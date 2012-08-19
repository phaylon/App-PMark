package App::PMark::Profile::Module::Version;
use Moo;

has version => (is => 'ro', required => 1);

sub TO_JSON {
    my ($self) = @_;
    return { __version__ => {
        version     => $self->version,
        tag_map     => $self->tag_map,
        note_map    => $self->note_map,
    }};
}

with qw(
    App::PMark::Profile::HasTags
    App::PMark::Profile::HasNotes
);

1;
