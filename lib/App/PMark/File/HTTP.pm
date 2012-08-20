package App::PMark::File::HTTP;
use Moo;
use App::PMark::Util qw( fail );
use HTTP::Tiny;
use overload fallback => 1,
    bool  => sub { 1 },
    q("") => sub { $_[0]->uri };

has uri => (is => 'ro');

sub get {
    my ($self) = @_;
    my $result = HTTP::Tiny->new->get($self->uri);
    return $result->{content}
        if $result->{success};
    fail sprintf q!unable to read from HTTP location '%s': %s %s!,
        $self->uri,
        $result->{status},
        $result->{reason};
}

sub put {
    my ($self) = @_;
    fail sprintf "writing to HTTP locations is not supported (%s)",
        $self->uri;
}

sub sibling {
    my ($self, @path) = @_;
    my $path = join '/', @path;
    (my $sibling_uri = $self->uri) =~ s{/[^/]+$}{/$path};
    return ref($self)->new(uri => $sibling_uri);
}

1;
