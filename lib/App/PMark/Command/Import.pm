package App::PMark::Command::Import;
use Moo;
use App::PMark::Util qw( make_file ssh_remote assert_path textblock fail );
use File::Basename;
use File::Temp;
use HTTP::Tiny;

use aliased 'App::PMark::Profile';

extends 'App::Cmd::Command';

sub abstract { 'import a profile from somewhere else' }

sub usage_desc { '%c import %o <target>' }

sub opt_spec {
    ['override|o',  'override current data with imported data'],
}

sub description {
    return textblock q{
        This command imports data from an external profile into your
        current profile data.
    };
}

sub examples {
    ['merge other profile into current data',
     'other_profile.json'],
    ['override current profile with data from other profile',
     '--override other_profile.json'],
}

sub execute {
    my ($self, $profile, $option, $target) = @_;
    my $import = $self->_find_target_profile($target);
    $import->modules;
    my $method = $option->override
        ? '_import_override'
        : '_import_merge';
    return $self->$method($profile, $import);
}

sub _import_override {
    my ($self, $profile, $import) = @_;
    $profile->replace_with($import);
    return 1;
}

sub _import_merge {
    my ($self, $profile, $import) = @_;
    $profile->merge_with($import);
    return 1;
}

sub _find_target_profile {
    my ($self, $target) = @_;
    return Profile->new(file => make_file($target));
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::StoreProfile
);

1;
