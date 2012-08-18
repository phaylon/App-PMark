package App::PerlMark::Command::Info;
use Moo;
use App::PerlMark::Util qw( textblock );
use List::Util          qw( max );

extends 'App::Cmd::Command';

sub abstract { 'fetch complete information stored about modules' }

sub usage_desc { '%c info %o <modules>...' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Requires module arguments to be queried')
        unless @$args;
    return 1;
}

sub description {
    return textblock q{
        This command queries the profile for the complete information
        about a set of specified modules.
    };
}

sub examples {
    ['show all information about Moose and Moo', 'Moose Moo'],
}

sub execute {
    my ($self, $profile, $option, @modules) = @_;
    $self->show_info($profile, $_)
        for @modules;
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::ShowInfo
);

1;
