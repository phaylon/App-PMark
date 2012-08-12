package App::PerlMark::Profile::HasTags;
use Moo::Role;

has tag_map => (is => 'ro', default => sub { {} });

sub untag {
    my ($self, $tag) = @_;
    die "$0: Tags cannot contain spaces\n"
        if $tag =~ m{\s};
    return delete $self->tag_map->{lc $tag};
}

sub tag {
    my ($self, $tag) = @_;
    die "$0: Tags cannot contain spaces\n"
        if $tag =~ m{\s};
    return 0
        if $self->tag_map->{lc $tag};
    return $self->tag_map->{lc $tag} = 1;
}

sub tags {
    my ($self) = @_;
    return map lc, sort keys %{$self->tag_map};
}

1;
