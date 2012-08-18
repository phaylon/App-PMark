package App::PerlMark::Command::Tags;
use Moo;
use App::PerlMark::Util qw( patterns_to_regexps textblock );
use List::Util          qw( max );

extends 'App::Cmd::Command';

sub abstract { 'search all known tags' }

sub usage_desc { '%c tags %o [<patterns>...]' }

sub description {
    return textblock q{
        This command lists and searches all available tags.

        It takes a set of patterns as arguments. If one of the patterns
        matches, the tag will be displayed. Special characters in the
        patterns are '*' matching any number of characters, '+' matching
        one or more characters, or '%' which can be used to mark the
        beginning and end of the string.

        You can add new tags with the 'tag' command, and remove them with
        the 'untag' command.
    };
}

sub examples {
    ['find all known tags',         ''],
    ['find all win32 related tags', 'win32'],
}

my $_each_tag = sub {
    my ($profile, $code) = @_;
    for my $module ($profile->modules) {
        $_->$code
            for $module->tags;
        for my $version ($module->versions) {
            $_->$code
                for $version->tags;
        }
    }
    return 1;
};

sub run {
    my ($self, $profile, $options, @patterns) = @_;
    my %tags;
    my $inc = sub { $tags{$_[0]}++ };
    $profile->$_each_tag($inc);
    $_->profile->$_each_tag($inc)
        for $profile->sources;
    my $max_len     = max map length, keys %tags;
    my @tag_names   = sort keys %tags;
    if (@patterns) {
        my @rx = patterns_to_regexps @patterns;
        @tag_names = grep {
            my $tag = $_;
            scalar grep { $tag =~ $_ } @rx;
        } @tag_names;
    }
    printf "%-${max_len}s  x%d\n", $_, $tags{$_}
        for @tag_names;
    return 1;
}

with qw(
    App::PerlMark::Command
);

1;
