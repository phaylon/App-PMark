package App::PMark::Command::Export;
use Moo;
use File::Basename;
use App::PMark::Util qw( make_file textblock );

extends 'App::Cmd::Command';

sub abstract { 'export your profile data' }

sub usage_desc { '%c export %o <target>' }

sub opt_spec {
    ['mkpath|p', q!try to create the directory if it doesn't exist!],
}

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Missing an export target argument')
        unless @$args;
    $self->usage_error('Expected only a single export target argument')
        if @$args > 1;
    return 1;
}

sub description {
    return textblock q{
        This command allows you to export your profile data into a file.

        The produced JSON file can be subscribed to by anyone who has
        supported access to the file. See the 'subscribe' command for more
        information about this.

        If you pass the '--mkpath' option the directory of the file will
        be created if it doesn't exist yet.
    };
}

sub examples {
    ['export to stdout', '-'],
    ['export via SSH', 'ssh://user@example.com:file.json'],
    ['export to file', 'file.json'],
}

sub execute {
    my ($self, $profile, $option, $target) = @_;
    make_file($target)->put($profile->file->get);
    print "\n";
    return 1;
}

with qw(
    App::PMark::Command
);

1;
