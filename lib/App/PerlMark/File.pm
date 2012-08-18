package App::PerlMark::File;
use Moo;

has file => (is => 'ro', required => 1);

sub read_all {
    my ($self) = @_;
    open my $fh, '<:utf8', $self->file
        or die "Unable to read '" . $self->file . "': $!\n";
    return do { local $/; <$fh> };
}

1;
