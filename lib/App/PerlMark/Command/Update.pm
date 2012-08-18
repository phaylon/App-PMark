package App::PerlMark::Command::Update;
use Moo;
use App::PerlMark::Util qw( textblock );

extends 'App::Cmd::Command';

sub abstract { q!update the profiles you are subscribed to! }

sub usage_desc { '%c update %o [<identifiers>...]' }

sub description {
    return textblock q{
        This command updates the locally stored versions of profiles you
        are subscribed to.

        If no arguments are supplied, all subscriptions will be updated.
        If you give a set of identifiers as arguments, only the
        subscriptions known under those identifiers will be updated.

        You can use the 'subscribe' command to add new subscriptions and
        the 'unsubscribe' command to remove subscriptions from your list
        of sources. You can also use the 'sources' command to give you a
        list of current or not yet subscribed sources.
    };
}

sub examples {
    ['update all sources', ''],
    ['update only foo and bar', 'foo bar'],
}

sub execute {
    my ($self, $profile, $options, @names) = @_;
    my @sources = $self->_find_sources($profile, @names)
        or print "No subscriptions to update\n" and return;
    for my $source (@sources) {
        printf "Updating '%s' from %s\n", $source->name, $source->target;
        my $error = $source->update;
        warn "  Error: $error\n"
            if $error;
    }
    return 1;
}

sub _find_sources {
    my ($self, $profile, @names) = @_;
    if (@names) {
        return map {
            $profile->source($_)
                or die "$0: Unknown source '$_'\n";
        } sort @names;
    }
    return sort { $a->name cmp $b->name } $profile->sources;
}

with qw(
    App::PerlMark::Command
);

1;
