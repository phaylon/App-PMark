package App::PerlMark::Profile;
use Moo;
use File::Basename;
use File::Path          qw( make_path );
use Fcntl               qw( :flock );
use App::PerlMark::Util qw( assert_path );
use File::Spec;
use JSON::PP;

use aliased 'App::PerlMark::Profile::Module';
use aliased 'App::PerlMark::Profile::Module::Version';
use aliased 'App::PerlMark::Profile::Note';

has path            => (is => 'ro', required => 1);
has file            => (is => 'lazy');
has data            => (is => 'lazy');
has module_map      => (is => 'lazy');

my $_inflate = sub {
    my ($class) = @_;
    return sub {
        my ($args) = @_;
        return $class->new(%$args);
    };
};

my $_json = JSON::PP
    ->new
#    ->pretty(1)
    ->filter_json_single_key_object(__module__  => Module->$_inflate)
    ->filter_json_single_key_object(__version__ => Version->$_inflate)
    ->filter_json_single_key_object(__note__    => Note->$_inflate)
    ->convert_blessed(1)
    ->relaxed(1)
    ->canonical(1)
    ->utf8(0);

my %_real_mode = (
    read    => '<:utf8',
    write   => '>:utf8',
);

my $_open = sub {
    my ($file, $mode) = @_;
    open my $fh, $_real_mode{$mode}, $file
        or die "Unable to $mode profile '$file': $!\n";
    flock $fh, LOCK_EX
        or die "Unable to obtain lock for profile '$file': $!\n";
    return $fh;
};

my $_close = sub {
    my ($fh, $file) = @_;
    flock $fh, LOCK_UN
        or die "Unable to release lock to profile '$file': $!\n";
    close $fh
        or die "Unable to close handle to profile '$file': $!\n";
    return 1;
};

sub _build_file {
    my ($self) = @_;
    return File::Spec->catfile($self->path, 'profile.json');
}

sub _build_data {
    my ($self) = @_;
    my $file = $self->file;
    return {}
        unless -e $file;
    my $fh = $file->$_open('read');
    my $body = do { local $/; <$fh> };
    $fh->$_close($file);
    my $data = $_json->decode($body);
    die "$0: Profile '$file' contains no compat version metadata\n"
        unless defined $data->{meta}{version};
    require App::PerlMark;
    my $own_version  = App::PerlMark->VERSION;
    my $data_version = $data->{meta}{version};
    die sprintf "$0: Profile version for '%s' is %s, but we are %s\n",
        $data_version, $own_version
        if $data_version > $own_version;
    return $data;
}

sub _build_module_map {
    my ($self) = @_;
    return $self->data->{module_map} || {};
}

sub modules {
    my ($self) = @_;
    return values %{$self->module_map};
}

sub module {
    my ($self, $name) = @_;
    return $self->module_map->{$name}
        ||= Module->new(name => $name);
}

sub module_names {
    my ($self) = @_;
    return sort keys %{$self->module_map};
}

sub as_data {
    my ($self) = @_;
    require App::PerlMark;
    return {
        module_map => $self->module_map,
        meta => {
            version => App::PerlMark->VERSION,
            update  => scalar time,
        },
    };
}

sub as_json {
    my ($self) = @_;
    return $_json->encode($self->as_data);
}

sub store {
    my ($self) = @_;
    my $file = $self->file;
    unless (-e $file) {
        warn "Initializing profile '$file'\n";
        assert_path dirname $file;
    }
    my $body = $self->as_json;
    my $fh = $file->$_open('write');
    print $fh $body
        or die "$0: Unable to write content of profile '$file': $!\n";
    $fh->$_close($file);
    return 1;
}

1;
