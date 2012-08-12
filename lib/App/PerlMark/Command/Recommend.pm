package App::PerlMark::Command::Recommend;
use Moo;
use List::Util  qw( max );

sub _command_arguments { '<modules>...' }

sub _command_options { }

sub run {
    my ($self, $profile, @modules) = @_;
    my $max_len = max map length, @modules;
    for my $name (@modules) {
        my $module = $profile->module($name);
        my $added  = !$module->recommended;
        $module->recommended(1);
        printf "%-${max_len}s %s\n",
            $name,
            $added ? '++' : 'is already recommended';
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
