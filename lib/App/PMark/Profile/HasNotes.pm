package App::PMark::Profile::HasNotes;
use Moo::Role;

use aliased 'App::PMark::Profile::Note';

has note_map => (is => 'ro', default => sub { {} });

sub merge_notes_with {
    my ($self, $other) = @_;
    for my $other_note ($other->notes) {
        next if $self->note($other_note->id);
        $self->note_map->{$other_note->id} = $other_note;
    }
    return 1;
}

sub note {
    my ($self, $id) = @_;
    return $self->note_map->{$id};
}

sub notes {
    my ($self) = @_;
    return values %{$self->note_map};
}

sub add_note {
    my ($self, $text) = @_;
    my $note = Note->new(text => $text);
    $self->note_map->{$note->id} = $note;
    return $note;
}

sub remove_note {
    my ($self, $id) = @_;
    return delete $self->note_map->{$id};
}

1;
