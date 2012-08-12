package App::PerlMark::Command::Info;
use Moo;

sub _command_arguments { '<modules>...' }

sub run {
    my ($self, $profile, @modules) = @_;
    $self->show_info($profile, $_)
        for @modules;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::ShowInfo
);

1;
