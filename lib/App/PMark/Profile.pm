package App::PMark::Profile;
use Moo;
use File::Basename;
use File::Path          qw( make_path );
use Fcntl               qw( :flock );
use App::PMark::Util qw( assert_path fail );
use List::Util          qw( first );
use File::Spec;
use JSON::PP;
use Try::Tiny;
use Log::Contextual     qw( :log );

use aliased 'App::PMark::Profile::Module';
use aliased 'App::PMark::Profile::Module::Version';
use aliased 'App::PMark::Profile::Note';
use aliased 'App::PMark::Profile::Source';

has file        => (is => 'ro', required => 1);
has path        => (is => 'lazy');
has data        => (is => 'lazy');
has source_map  => (is => 'rwp', lazy => 1, builder => 1);
has json        => (is => 'lazy');
has is_readonly => (is => 'ro');
has is_relaxed  => (is => 'ro');

sub replace_with {
    my ($self, $other) = @_;
    log_info { 'replacing all module and source data' };
    $self->_set_module_map($other->module_map);
    $self->_set_source_map($other->source_map);
    return 1;
}

sub merge_with {
    my ($self, $other) = @_;
    $self->merge_modules_with($other);
    $self->merge_sources_with($other);
    return 1;
}

sub merge_modules_with {
    my ($self, $other) = @_;
    log_info { 'merging modules' };
    for my $other_module ($other->modules) {
        my $exists = $self->has_module($other_module->name);
        my $module = $exists || $self->module($other_module->name);
        log_info { sprintf "%s module '%s'",
            $exists ? 'updating' : 'adding',
            $module->name;
        };
        $module->merge_with($other_module);
    }
    log_info { 'done merging modules' };
    return 1;
}

sub merge_sources_with {
    my ($self, $other) = @_;
    log_info { 'merging sources' };
    for my $other_source ($other->sources) {
        my ($name, $target) = (
            $other_source->name,
            $other_source->target,
        );
        my $source;
        if ($source = $self->source($name)) {
            next if $source->target eq $target;
            log_info { sprintf q!target for source '%s' is now '%s'!,
                $name, $target,
            };
            $source->target($target);
        }
        else {
            log_info { sprintf q!adding source '%s' (%s)!,
                $name, $target,
            };
            $source = $self->add_source($name, $target);
        }
        log_info { sprintf q!updating source '%s'!, $name };
        $source->update;
    }
    log_info { 'done merging sources' };
}

sub _build_path { dirname $_[0]->file }

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
        or fail "unable to $mode profile '$file': $!";
    flock $fh, LOCK_EX
        or fail "unable to obtain lock for profile '$file': $!";
    return $fh;
};

my $_close = sub {
    my ($fh, $file) = @_;
    flock $fh, LOCK_UN
        or fail "unable to release lock to profile '$file': $!";
    close $fh
        or fail "unable to close handle to profile '$file': $!";
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
        fail "profile '$file' contains no compat version metadata"
            unless defined $data->{meta}{version};
        require App::PMark;
        my $own_version  = App::PMark->VERSION;
        my $data_version = $data->{meta}{version};
        fail sprintf "profile version for '%s' is %s, but we are %s",
            $data_version, $own_version
            if $data_version > $own_version;
        return $data;
    }
    catch {
        die $_ unless $self->is_relaxed;
        chomp(my $error = $_);
        $error =~ s{\s+at\s+\S+\s+line\s+\d+.*}{};
        log_warn { "cannot read profile '$file': $error" };
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
    fail "source names can only contain 'a-z', '0-9', '-' and '_'"
        if $name =~ m{[^a-z0-9_-]};
    if (my $existing = $self->source($name)) {
        fail "you are already subscribed to a source named "
            . "'$name':\n  " . $existing->target;
    }
    if (my $existing = $self->find_source_by_target($target)) {
        fail "your subscription to '" . $existing->name . "' "
            . "already updates from $target";
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
    require App::PMark;
    return {
        module_map => $self->module_map,
        source_map => $self->source_map,
        meta => {
            version => App::PMark->VERSION,
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
    fail "cannot store a readonly profile"
        if $self->is_readonly;
    my $file = $self->file;
    unless (-e $file) {
        log_info { "initializing profile '$file'" };
        assert_path dirname $file;
    }
    my $body = $self->as_json;
    my $fh = $file->$_open('write');
    print $fh $body
        or fail "Unable to write content of profile '$file': $!";
    $fh->$_close($file);
    return 1;
}

with qw(
    App::PMark::Profile::HasModules
);

1;
