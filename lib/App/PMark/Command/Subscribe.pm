package App::PMark::Command::Subscribe;
use Moo;
use App::PMark::Util qw( textblock fail );
use List::Util          qw( max );
use Log::Contextual     qw( :log );

extends 'App::Cmd::Command';

sub abstract { 'subscribe to another profile' }

sub usage_desc { '%c subscribe %o <identifier> <target>' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Missing a source identifier and target argument')
        if @$args < 1;
    $self->usage_error('Missing a source target argument')
        if @$args < 2;
    $self->usage_error('Expected only identifier and target argument')
        if @$args > 3;
    return 1;
}

sub description {
    return textblock q{
        This command adds subscriptions to sources you want to consider
        when querying for information.

        The foreign profile data will be fetched and cached in your local
        profile directory. The cached data can be updated with the
        'update' command.

        You can remove a subscription with the 'unsubscribe' command.  All
        subscribed sources can be listed with the 'sources' command, which
        also can be used to discover new sources you aren't yet subscribed
        to.
    };
}

sub examples {
    ['subscribe to an ssh source named foo',
     'foo ssh://user@example.com:file.json'],
    ['subscribe to a web source named bar',
     'bar http://example.com/file.json'],
    ['subscribe to a file source named baz',
     'baz file.json'],
}

sub execute {
    my ($self, $profile, $options, $name, $target) = @_;
    my $source = $profile->add_source($name, $target);
    log_info { "added subscription for '$name'" };
    log_info { "updating source '$name' from '$target'" };
    my $error = $source->update;
    fail "unable to subscribe to and update from $target: $error"
        if $error;
    return 1;
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::StoreProfile
);

1;
