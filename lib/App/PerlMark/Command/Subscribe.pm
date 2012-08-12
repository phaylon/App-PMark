package App::PerlMark::Command::Subscribe;
use Moo;

sub _command_arguments { '<identifier> <target>' }

sub _option_constraints {
    my ($class, $options, $args) = @_;
    [@$args < 1, 'Missing a source identifier argument'],
    [@$args < 2, 'Missing a source target argument'],
    [@$args > 2, 'Expected only identifier and target arguments'],
}

sub run {
    my ($self, $profile, $target) = @_;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
