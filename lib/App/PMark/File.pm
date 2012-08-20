package App::PMark::File;
use Moo;
use App::PMark::Util qw( fail );

has file => (is => 'ro', required => 1);

sub read_all {
    my ($self) = @_;
    open my $fh, '<:utf8', $self->file
        or fail "unable to read '" . $self->file . "': $!\n";
    return do { local $/; <$fh> };
}

1;