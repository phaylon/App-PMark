package App::PMark::Command::Sources;
use Moo;
use List::Util          qw( max );
use App::PMark::Util qw( textblock );

extends 'App::Cmd::Command';

sub abstract { 'list all subscriptions' }

sub usage_desc { '%c sources %o' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Command does not expect any arguments')
        if @$args;
    return 1;
}

sub opt_spec {
    ['discover|d', 'show what your sources are subscribed to'],
}

sub description {
    return textblock q{
        This command will list current or possible subscriptions.

        Calling this command without options will show you a list of
        sources you are currently subscribed to.

        Calling this command with the '--discover' option will show you a
        list of possible subscriptions. These are compiled by taking all
        subscriptions of your known sources and listing all those that you
        aren't yet subscribed to.

        You can use the 'subscribe' command to add more subscriptions and
        the 'unsubscribe' command to cancel existing ones.
    };
}

sub examples {
    ['list current subscriptions', ''],
    ['list sources not yet subscribed to', '--discover'],
}

sub execute {
    my ($self, $profile, $option) = @_;
    if ($option->discover) {
        $self->_show_unsubscribed($profile);
    }
    else {
        $self->_show_subscribed($profile);
    }
    return 1;
}

sub _show_unsubscribed {
    my ($self, $profile) = @_;
    my @sources  = sort { $a->name cmp $b->name } $profile->sources;
    my %known    = map { ($_->target => 1) } @sources;
    my @full_map = map {
        my $source = $_;
        map  { [join('/', $source->name, $_->name), $_->target] }
        grep { not $known{$_->target} }
            $source->profile->sources;
    } @sources;
    print "no unsubscribed sources available\n" and return
        unless @full_map;
    my $max_len = 1 + (max(map length($_->[0]), @full_map) || 0);
    printf "%-${max_len}s %s\n", $_->[0] . ':', $_->[1]
        for @full_map;
    return 1;
}

sub _show_subscribed {
    my ($self, $profile) = @_;
    my @sources = sort { $a->name cmp $b->name } $profile->sources
        or print "not subscribed to any sources\n" and return;
    my $max_len = 1 + (max(map length($_->name), @sources) || 0);
    printf "%-${max_len}s %s\n", $_->name . ':', $_->target
        for @sources;
    return 1;
}

with qw(
    App::PMark::Command
);

1;
