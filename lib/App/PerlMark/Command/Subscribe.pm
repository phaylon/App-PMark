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
    my ($self, $profile, $name, $target) = @_;
    my $source = $profile->add_source($name, $target);
    printf "Updating '%s' from %s\n", $name, $target;
    my $error = $source->update;
    die "$0: Unable to subscribe to $target: $error\n";
        if $error;
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
