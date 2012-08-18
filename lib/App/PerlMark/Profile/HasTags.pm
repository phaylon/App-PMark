package App::PerlMark::Profile::HasTags;
use Moo::Role;
use App::PerlMark::Util qw( fail );

has tag_map => (is => 'ro', default => sub { {} });

sub merge_tags_with {
    my ($self, $other) = @_;
    $self->tag($_)
        for $other->tags;
    return 1;
}

sub untag {
    my ($self, $tag) = @_;
    fail "tags cannot contain spaces"
        if $tag =~ m{\s};
    return delete $self->tag_map->{lc $tag};
}

sub tag {
    my ($self, $tag) = @_;
    fail "tags cannot contain spaces"
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
