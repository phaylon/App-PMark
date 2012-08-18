package App::PerlMark::Profile;
use Moo;
use File::Basename;
use File::Path          qw( make_path );
use Fcntl               qw( :flock );
use App::PerlMark::Util qw( assert_path );
use List::Util          qw( first );
use File::Spec;
use JSON::PP;
use Try::Tiny;

use aliased 'App::PerlMark::Profile::Module';
use aliased 'App::PerlMark::Profile::Module::Version';
use aliased 'App::PerlMark::Profile::Note';
use aliased 'App::PerlMark::Profile::Source';

has path        => (is => 'ro', required => 1);
has file        => (is => 'lazy');
has data        => (is => 'lazy');
has source_map  => (is => 'lazy');
has json        => (is => 'lazy');
has is_readonly => (is => 'ro');
has is_relaxed  => (is => 'ro');

sub _load_profile_data {
    my ($self, $target) = @_;
}

sub _build_json {
    my ($self) = @_;
    my $_inflate = sub {
        my ($class, %common) = @_;
        return sub {
            my ($args) = @_;
            return $class->new(%$args, %common);
        };
    };
    return JSON::PP->new
        ->convert_blessed(1)->relaxed(1)->canonical(1)->utf8(0)
        ->filter_json_single_key_object(
            __module__  => Module->$_inflate,
        )
        ->filter_json_single_key_object(
            __version__ => Version->$_inflate,
        )
        ->filter_json_single_key_object(
            __note__    => Note->$_inflate,
        )
        ->filter_json_single_key_object(
            __source__  => Source->$_inflate(parent => $self),
        )
}

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
    try {
        my $fh = $file->$_open('read');
        my $body = do { local $/; <$fh> };
        $fh->$_close($file);
        my $data = $self->json->decode($body);
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
    catch {
        die $_ unless $self->is_relaxed;
        chomp(my $error = $_);
        $error =~ s{\s+at\s+\S+\s+line\s+\d+.*}{};
        warn "$0: Warning: Cannot read profile '$file': $error\n";
        return {};
    };
}

sub _build_source_map {
    my ($self) = @_;
    return $self->data->{source_map} || {};
}

sub _build_module_map {
    my ($self) = @_;
    return $self->data->{module_map} || {};
}

sub sources {
    my ($self) = @_;
    return values %{$self->source_map};
}

sub source {
    my ($self, $name) = @_;
    return $self->source_map->{lc $name};
}

sub add_source {
    my ($self, $name, $target) = @_;
    $name = lc $name;
    die "$0: Source names can only contain 'a-z', '0-9', '-' and '_'\n"
        if $name =~ m{[^a-z0-9_-]};
    if (my $existing = $self->source($name)) {
        die "$0: You are already subscribed to a source named "
            . "'$name':\n  " . $existing->target . "\n";
    }
    if (my $existing = $self->find_source_by_target($target)) {
        die "$0: Your subscription to '" . $existing->name . "' "
            . "already updates from $target\n";
    }
    my $source = Source->new(
        name    => $name,
        target  => $target,
        parent  => $self,
    );
    return $self->source_map->{$name} = $source;
}

sub find_source_by_target {
    my ($self, $target) = @_;
    return first {
        $_->target eq $target;
    } $self->sources;
}

sub remove_source {
    my ($self, $name) = @_;
    $name = lc $name;
    return delete $self->source_map->{$name};
}

sub as_data {
    my ($self) = @_;
    require App::PerlMark;
    return {
        module_map => $self->module_map,
        source_map => $self->source_map,
        meta => {
            version => App::PerlMark->VERSION,
            update  => scalar time,
        },
    };
}

sub as_json {
    my ($self) = @_;
    return $self->json->encode($self->as_data);
}

sub store {
    my ($self) = @_;
    die "$0: Cannot store a readonly profile\n"
        if $self->is_readonly;
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

with qw(
    App::PerlMark::Profile::HasModules
);

1;
