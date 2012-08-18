package App::PerlMark::Command::Import;
use Moo;
use App::PerlMark::Util qw( ssh_remote assert_path textblock );

extends 'App::Cmd::Command';

sub abstract { 'import a profile from somewhere else' }

sub usage_desc { '%c import %o <target>' }

sub opt_spec {
    ['override|o',  'override current data with imported data'],
    ['all|a',       'import all information'],
    ['modules|m',   'import modules'],
    ['tags|t',      'import tags'],
    ['notes|n',     'import notes'],
}

sub description {
    return textblock q{
        This command imports data from an external profile into your
        current profile data.
    };
}

sub examples {
}

sub execute {
    my ($self, $profile, $option, $target) = @_;
}

with qw(
    App::PerlMark::Command
);

1;
