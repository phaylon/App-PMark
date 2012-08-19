package App::PMark::Command::Search;
use Moo;
use App::PMark::Util qw( patterns_to_regexps textblock );
use List::Util          qw( max );

extends 'App::Cmd::Command';

sub abstract { 'search for modules' }

sub usage_desc { '%c search %o <patterns>...' }

sub opt_spec {
    ['case-sensitive|c', 'do not ignore case when matching'],
    ['tags|t', 'match patterns against tags'],
    ['names|n', 'match patterns against module names'],
    ['all-tags|T', 'include tags from all versions'],
    ['raw|r',   'only output module names'],
    ['info|i',  'show full info for every module'],
    ['score|s=s', 'filter modules by score',
        { default => 1 }],
}

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Can only have either --raw or --info output')
        if $option->raw and $option->info;
    return 1;
}

sub description {
    return textblock q{
        This command allows you to search for known modules.

        It takes a set of patterns as arguments. If one of the patterns
        matches, the module will be displayed. Special characters in the
        patterns are '*' matching any number of characters, '+' matching
        one or more characters, or '%' which can be used to mark the
        beginning and end of the string.

        By default, matches are performed case-insensitive. If you want
        casing to matter you can specify the '--case-sensitive' option.

        By default, the patterns are matched against both module names and
        the tags that are given to the modules. You can select one (or
        both) explicitly with the '--names' and '--tags' options.

        The '--all-tags' option allows you to search for tags in all
        versions. By default, only the tags on the module itself are
        queried, and tags specific to versions ignored.

        You can use '--score' to set a minimum score (the number of
        recommendations) that the module must have to be listed. This will
        default to 1. Giving a '--score' of 0 will list all modules.
    };
}

sub examples {
    ['give a concise list of all known recommended modules',
     ''],
    ['give a concise list of all modules, even without score',
     '--score 0'],
    ['search for Moose extensions and give all information',
     '--info MooseX::'],
    ['search for modules with tags containing win32',
     '--tags win32'],
}

sub _match_tags {
    my ($self, $patterns, $tags) = @_;
    return scalar grep {
        my $tag = $_->[0];
        scalar grep {
            $tag =~ $_;
        } @$patterns;
    } @$tags;
}

sub execute {
    my ($self, $profile, $option, @patterns) = @_;
    my @rx = patterns_to_regexps(
        $option->case_sensitive,
        @patterns,
    );
    my @names       = $self->query_all_module_names($profile);
    my $max_len     = max map length, @names;
    my $min_score   = $option->score;
    my $in_names    = $option->names;
    my $in_tags     = $option->tags;
    unless ($in_names or $in_tags) {
        $_ = 1 for $in_names, $in_tags;
    }
    $in_tags = $in_tags || $option->all_tags;
    for my $name (@names) {
        my $own   = $profile->module($name);
        my $score = $self->query_recommended_by($profile, $name);
        next if $min_score > $score;
        my @tags  = $option->all_tags
            ? $self->query_counted_tags_all($profile, $name)
            : $self->query_counted_tags($profile, $name);
        next unless not(@rx)
            or ($in_names and grep { $name =~ $_ } @rx)
            or ($in_tags and $self->_match_tags(\@rx, \@tags));
        if ($option->{raw}) {
            print "$name\n";
        }
        elsif ($option->info) {
            $self->show_info($profile, $name);
        }
        else {
            printf "%-${max_len}s  %4s  %s\n",
                $name,
                $score ? "+$score" : '',
                @tags  ? join(' ', map {
                    my ($name, $count) = @$_;
                    $count > 1 ? sprintf('%s(%d)', $name, $count) : $name;
                } @tags) : '';
        }
    }
    return 1;
}

with qw(
    App::PMark::Command
    App::PMark::Command::Role::ShowInfo
    App::PMark::Command::Role::DeepQuery
);

1;
