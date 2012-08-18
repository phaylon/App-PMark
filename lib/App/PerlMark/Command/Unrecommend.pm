package App::PerlMark::Command::Unrecommend;
use Moo;
use App::PerlMark::Util qw( textblock );
use List::Util          qw( max );

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
            printf "%-${max_len}s is an unknown module\n", $name;
            next;
        }
        my $removed = $module->recommended;
        $module->recommended(0);
        printf "%-${max_len}s %s\n",
            $name,
            $removed ? '--' : 'is not recommended';
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
