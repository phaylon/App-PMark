package App::PerlMark::Command::Search;
use Moo;
use App::PerlMark::Util qw( patterns_to_regexps );
use List::Util          qw( max );

sub _command_arguments { '<patterns>...' }

sub _command_options {
    ['case-sensitive|c', 'do not ignore case when matching'],
    ['tags|t', 'match patterns against tags'],
    ['names|n', 'match patterns against module names'],
    ['raw|r',   'only output module names'],
    ['info|i',  'show full info for every module'],
    ['score|s=s', 'filter modules by score',
        { default => 0 }],
    ['all-tags|T', 'include all tags',
        { implies => { tags => 1 } }],
}

sub _option_constraints {
    my ($class, $options) = @_;
    [ $options->raw && $options->info,
      'Can only have either --raw or --info output, not both',
    ],
}

sub _match_tags {
    my ($self, $patterns, $tags) = @_;
    return scalar grep {
        my $tag = $_;
        scalar grep {
            $tag =~ $_;
        } @$patterns;
    } @$tags;
}

sub run {
    my ($self, $profile, @patterns) = @_;
    my @rx = patterns_to_regexps(
        $self->options->case_sensitive,
        @patterns,
    );
    my @names       = $profile->module_names;
    my $max_len     = max map length, @names;
    my $options     = $self->options;
    my $min_score   = $options->score;
    my $in_names    = $options->names;
    my $in_tags     = $options->tags;
    unless ($in_names or $in_tags) {
        $_ = 1 for $in_names, $in_tags;
    }
    for my $name (sort @names) {
        my $own   = $profile->module($name);
        my $score = $own->recommended;
        next if $min_score > $score;
        my @tags  = $options->all_tags
            ? $own->all_tags
            : $own->tags;
        next unless not(@rx)
            or ($in_names and grep { $name =~ $_ } @rx)
            or ($in_tags and $self->_match_tags(\@rx, \@tags));
        if ($options->raw) {
            print "$name\n";
        }
        elsif ($options->info) {
            $self->show_info($profile, $name);
        }
        else {
            printf "%-${max_len}s  %6s  %s\n",
                $name,
                $score ? "(+$score)" : '',
                @tags  ? sprintf("[%s]", join ' ', sort @tags) : '';
        }
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::ShowInfo
);

1;
