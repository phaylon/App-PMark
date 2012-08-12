package App::PerlMark::Command::ShowInfo;
use Moo::Role;

sub show_info {
    my ($self, $profile, $name) = @_;
    my $module = $profile->module($name);
    printf "[%s]\n", $module->name;
    $self->show_score_info($profile, $module);
    $self->show_tag_info($profile, $module);
    $self->show_note_info($profile, $module);
    printf "\n";
    return 1;
}

sub show_score_info {
    my ($self, $profile, $module) = @_;
    my @by;
    my $score = $module->recommended;
    push @by, 'you' if $score;
    printf "- Score: %s\n", $score ? "+$score" : 0;
    printf "  by: %s\n", join ', ', @by
        if @by;
    return 1;
}

sub show_note_info {
    my ($self, $profile, $module) = @_;
    my @notes = $self->_find_notes($profile, $module);
    return unless @notes;
    printf "- Notes:\n";
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
    my @notes = (
        (map { ['you', 'all versions', $_] } $module->notes),
        (map {
            my $version = $_;
            (map { ['you', $version->version, $_] } $version->notes);
        } $module->versions),
    );
    return sort { $a->[2]->timestamp <=> $b->[2]->timestamp } @notes;
}

sub show_tag_info {
    my ($self, $profile, $module) = @_;
    my @tag_rows;
    if (my @tags = $module->tags) {
        push @tag_rows, ['All Versions', sort @tags];
    }
    for my $version ($module->versions) {
        my @tags = sort $version->tags;
        push @tag_rows, [$version->version, @tags]
            if @tags;
    }
    return unless @tag_rows;
    print "- Tags:\n";
    for my $row (@tag_rows) {
        my ($label, @tags) = @$row;
        printf "  %s: %s\n", $label, join ' ', @tags;
    }
    return 1;
}

1;
