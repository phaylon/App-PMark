package App::PerlMark::Command::Import;
use Moo;
use App::PerlMark::Util qw( ssh_remote assert_path textblock fail );
use File::Basename;
use File::Temp;
use HTTP::Tiny;

use aliased 'App::PerlMark::Profile';

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
    if (my $remote = ssh_remote $target) {
        return Profile->new::on($remote->[0], file => $remote->[1]);
    }
    elsif ($target =~ m{^https?://}) {
        my $temp = File::Temp->new;
        my $res = HTTP::Tiny->new->mirror($target, "$temp");
        fail sprintf "Unable to fetch '%s' (%s): %s",
            $target, @{ $res }{qw( status reason )}
            unless $res->{success};
        return Profile->new(file => $temp);
    }
    else {
        return Profile->new(file => $target);
    }
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
