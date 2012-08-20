package App::PMark::Command::Update;
use Moo;
use App::PMark::Util    qw( textblock fail );
use Log::Contextual     qw( :log );
use Try::Tiny;

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
    my @sources = $self->_find_sources($profile, @names);
    unless (@sources) {
        log_info { "no subscriptions to update" };
        return;
    }
    for my $source (@sources) {
        try {
            log_info { sprintf q!updating source '%s' from '%s'!,
                $source->name,
                $source->target,
            };
            $source->update;
        }
        catch {
            log_warn { sprintf q!unable to update source '%s': %s!,
                $source->name,
                $_,
            };
        }
    }
    return 1;
}

sub _find_sources {
    my ($self, $profile, @names) = @_;
    if (@names) {
        return map {
            $profile->source($_)
                or fail "unknown source '$_'";
        } sort @names;
    }
    return sort { $a->name cmp $b->name } $profile->sources;
}

with qw(
    App::PMark::Command
);

1;
