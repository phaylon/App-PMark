package App::PMark::Exception;
use Moo;
use overload
    q{""}       => sub { sprintf "Error: %s\n", $_[0]->message },
    bool        => sub { 1 },
    fallback    => 1,

has message => (is => 'ro', required => 1);

sub throw {
    my ($class, $message) = @_;
    die $class->new(message => $message);
}

1;
