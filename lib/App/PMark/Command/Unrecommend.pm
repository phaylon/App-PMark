package App::PMark::Command::Unrecommend;
use Moo;
use App::PMark::Util qw( textblock );
use List::Util          qw( max );
use Log::Contextual     qw( :log );

extends 'App::Cmd::Command';

sub abstract { 'remove module recommendations' }

sub usage_desc { '%c unrecommend %o <modules>...' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Requires module arguments to be unrecommended')
        unless @$args;
    return 1;
}

sub description {
    return textblock q{
        This command marks a set of specified modules as no longer
        recommended. The use of the modules will not be discouraged, but
        their score will no longer be increased when looking for modules.

        If you want to discourage use of a module, tags and notes might
        be a better place for that information.

        Modules that are not recommended yet will not be affected.
    };
}

sub examples {
    ['unrecommend Foo and Bar::Baz', 'Foo Bar::Baz'],
}

sub execute {
    my ($self, $profile, $option, @modules) = @_;
    my $max_len = max map length, @modules;
    for my $name (@modules) {
        my $module = $profile->has_module($name);
        unless ($module) {
            log_warn { "unknown module $name" };
            next;
        }
        my $removed = $module->recommended;
        $module->recommended(0);
        log_info {
            $removed
            ? "$name--"
            : "module $name is not yet recommended";
        };
    }
    return 1;
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::StoreProfile
);

1;
