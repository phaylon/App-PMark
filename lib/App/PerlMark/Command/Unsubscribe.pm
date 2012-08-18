package App::PerlMark::Command::Unsubscribe;
use Moo;
use App::PerlMark::Util qw( textblock );

extends 'App::Cmd::Command';

sub abstract { 'unsubscribe from a current source' }

sub usage_desc { '%c unsubscribe %o <identifiers>...' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Missing source identifier arguments')
        unless @$args;
    return 1;
}

sub description {
    return textblock q{
        This command removes sources you are currently subscribed to.

        You can see a list of source you are currently subscribed to with
        the 'sources' command. New subscriptions can be added with the
        'subscribe' command.
    };
}

sub examples {
    ['remove the foo and bar sources', 'foo bar'],
}

sub execute {
    my ($self, $profile, $option, @names) = @_;
    for my $name (@names) {
        my $removed = $profile->remove_source($name)
            or warn "Not subscribed to any source named '$name'\n";
        print "Removed subscription to source '$name'\n";
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
