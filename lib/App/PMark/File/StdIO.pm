package App::PMark::File::StdIO;
use Moo;
use App::PMark::Util qw( fail );

my $_input_cache;

sub get {
    my ($self) = @_;
    return $_input_cache
        if defined $_input_cache;
    return $_input_cache = do { local $/; <STDIN> };
}

sub put {
    my ($self, $content) = @_;
    print $content;
}

sub sibling {
    my ($self, @path) = @_;
    fail sprintf "cannot find sibling file '%s'  from STDIN/STDOUT",
        join '/', @path;
}

with 'App::PMark::File';

1;
