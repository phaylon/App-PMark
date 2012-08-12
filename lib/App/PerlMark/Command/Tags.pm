package App::PerlMark::Command::Tags;
use Moo;
use App::PerlMark::Util qw( patterns_to_regexps );
use List::Util          qw( max );

sub run {
    my ($self, $profile, @patterns) = @_;
    my %tags;
    for my $module ($profile->modules) {
        $tags{$_}++ for $module->tags;
        for my $version ($module->versions) {
            $tags{$_}++ for $version->tags;
        }
    }
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
