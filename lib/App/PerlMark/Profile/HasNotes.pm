package App::PerlMark::Profile::HasNotes;
use Moo::Role;

use aliased 'App::PerlMark::Profile::Note';

has note_map => (is => 'ro', default => sub { {} });

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
