package App::PerlMark::Command::Role::ShowInfo;
use Moo::Role;

sub show_info {
    my ($self, $profile, $name) = @_;
    my $module = $profile->module($name);
    printf "[%s]\n", $module->name;
    $self->show_score_info($profile, $name);
    $self->show_tag_info($profile, $module);
    $self->show_note_info($profile, $module);
    printf "\n";
    return 1;
}

sub show_score_info {
    my ($self, $profile, $name) = @_;
    my @by    = $self->query_recommended_by($profile, $name);
    my $score = scalar @by;
    printf " Score: %s (by %s)\n",
        $score ? "+$score" : 0,
        join(', ', @by) || 'nobody';
    return 1;
}

sub show_note_info {
    my ($self, $profile, $module) = @_;
    my @notes = $self->_find_notes($profile, $module);
    return unless @notes;
    printf " Notes:\n";
    $self->_display_note($_)
        for @notes;
    return 1;
}

sub _display_note {
    my ($self, $sourced_note) = @_;
    my ($source, $version, $note) = @$sourced_note;
    printf "  --- from %s for %s, at %s, <%s>:\n",
        $source,
        $version,
        scalar localtime($note->timestamp),
        $note->id;
    my $text = $note->text;
    $text =~ s{\n\s*\S}{$1   }g;
    print "    $text\n";
    return 1;
}

sub _find_notes {
    my ($self, $profile, $module) = @_;
    my $get_notes = sub {
        my ($source_name, $mod) = @_;
        (map { [$source_name, 'all versions', $_] } $mod->notes),
        (map {
            my $version = $_;
            (map {
                [$source_name, $version->version, $_]
            } $version->notes);
        } $mod->versions),
    };
    my @notes = (
        $get_notes->('you', $module),
        (map {
            ($get_notes->($_->name, $_->profile->module($module->name)));
        } $profile->sources),
    );
    return sort { $a->[2]->timestamp <=> $b->[2]->timestamp } @notes;
}

sub show_tag_info {
    my ($self, $profile, $module) = @_;
    my %all;
    my %by_version;
    my $collect = sub {
        my ($mod) = @_;
        $all{$_}++ for $mod->tags;
        for my $version ($mod->versions) {
            $by_version{$version->version}{$_}++
                for $version->tags;
        }
    };
    $module->$collect;
    $_->profile->module($module->name)->$collect
        for $profile->sources;
    return unless keys %all or keys %by_version;
#    print " Tags:\n";
    my $display = sub {
        my $map = shift;
        return join ', ', map {
            my $count = $map->{$_};
            $count > 1 ? "$_($count)" : $_;
        } sort keys %$map;
    };
    printf " Tags: %s\n", $display->(\%all);
    printf "    %s: %s\n", $_, $display->($by_version{$_})
        for sort keys %by_version;
    return 1;
}

with qw(
    App::PerlMark::Command::Role::DeepQuery
);

1;
