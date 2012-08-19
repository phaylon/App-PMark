package App::PMark::Command::Forget;
use Moo;
use App::PMark::Util qw( textblock );
use List::Util          qw( max );
use Log::Contextual     qw( :log );

extends 'App::Cmd::Command';

sub abstract { 'forget all information about specific modules' }

sub usage_desc { '%c forget %o <modules>...' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Requires module arguments to be forgotten')
        unless @$args;
    return 1;
}

sub description {
    return textblock q{
        This command allows you to forget all data associated with a
        specified set of modules.

        This includes tags, versions, notes and their recommendation
        status.

        Note that the modules might still show up if one of your sources
        has information about them, since the only information removed
        will be your own.
    };
}

sub examples {
    ['forget everything about Foo and Bar::Baz', 'Foo Bar::Baz'],
}

sub execute {
    my ($self, $profile, $option, @modules) = @_;
    my $max_len = max map length, @modules;
    for my $name (@modules) {
        my $removed = $profile->remove_module($name);
        if ($removed) {
            log_info { "removed all data about module $name" };
        }
        else {
            log_warn { "no data available for module $name" };
        }
    }
    return 1;
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::StoreProfile
);

1;
