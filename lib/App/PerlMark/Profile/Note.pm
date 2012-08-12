package App::PerlMark::Profile::Note;
use Moo;
use Sub::Quote;
use Digest::SHA::PurePerl   qw( sha1_hex );

my $_trim = quote_sub q/
    my $text = $_[0];
    $text =~ s{^[\s\n]+}{};
    $text =~ s{[\s\n]$}{};
    $text;
/;

has id          => (is => 'lazy');
has timestamp   => (is => 'lazy');
has text        => (is => 'ro', required => 1, coerce => $_trim);

sub _build_id {
    my ($self) = @_;
    return scalar sha1_hex $self->text;
}

sub _build_timestamp {
    return time;
}

sub TO_JSON {
    my ($self) = @_;
    return { __note__ => {
        id          => $self->id,
        timestamp   => $self->timestamp,
        text        => $self->text,
    }};
}

1;
