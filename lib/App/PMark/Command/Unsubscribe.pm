package App::PMark::Command::Unsubscribe;
use Moo;
use App::PMark::Util qw( textblock );
use Log::Contextual     qw( :log );

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
        my $removed = $profile->remove_source($name);
        if ($removed) {
            log_info { "removed subscription to source '$name'" };
        }
        else {
            log_warn { "not subscribed to any source named '$name'" };
        }
    }
    return 1;
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::StoreProfile
);

1;
