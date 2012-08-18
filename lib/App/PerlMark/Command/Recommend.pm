package App::PerlMark::Command::Recommend;
use Moo;
use App::PerlMark::Util qw( textblock );
use List::Util          qw( max );

extends 'App::Cmd::Command';

around command_names => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(@args), '++';
};

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Requires module arguments to be recommended')
        unless @$args;
    return 1;
}

sub abstract { 'mark modules as recommended' }

sub usage_desc { '%c recommend %o <modules>...' }

sub opt_spec {
    ['tag|t=s@', 'add tags to recommended modules'],
}

sub examples {
    ['recommend Moose and Moo', 'Moose Moo'],
    ['recommend modules and tag as pure-perl',
     'Moo Web::Simple -t pure-perl'],
}

sub description {
    return textblock q{
        This command allows you to mark modules as recommended.

        You can use the '++' alias instead of this name. Additional tags
        for the recommended modules can be specified with the '--tag'
        option.

        You can remove recommendations with the 'unrecommend' command
        or wipe all data with the 'forget' command.
    };
}

sub execute {
    my ($self, $profile, $option, @modules) = @_;
    my $max_len = max map length, @modules;
    my @tags = @{$option->{tag}||[]};
    for my $name (@modules) {
        my $module = $profile->module($name);
        my $added  = !$module->recommended;
        $module->recommended(1);
        printf "%-${max_len}s %s\n",
            $name,
            $added ? '++' : 'is already recommended';
        my @added = grep { $module->tag($_) } @tags;
        printf "  Added tags: %s\n", join ', ', @added
            if @added;
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
