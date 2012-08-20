package App::PMark::File::Local;
use Moo;
use App::PMark::Util qw( fail assert_path );
use File::Basename;
use File::Spec;
use overload fallback => 1,
    bool  => sub { 1 },
    q("") => sub { $_[0]->path };

use aliased 'App::PMark::Exception::FileNotFound';

has path => (is => 'ro', required => 1);

sub get {
    my ($self) = @_;
    my $path = $self->path;
    FileNotFound->throw("file '$path' does not exist")
        unless -e $path;
    open my $fh, '<:utf8', $path
        or fail "unable to read '" . $path . "': $!\n";
    return do { local $/; <$fh> };
}

sub put {
    my ($self, $content) = @_;
    assert_path dirname $self->path;
    open my $fh, '>:utf8', $self->path
        or fail "unable to write '" . $self->path . "': $!\n";
    print $fh $content;
    return 1;
}

sub sibling {
    my ($self, @path) = @_;
    return ref($self)->new(
        path => File::Spec->catfile(
            dirname($self->path),
            @path,
        ),
    );
}

with 'App::PMark::File';

1;
