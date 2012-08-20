package App::PMark::File::SSH;
use Moo;
use Log::Contextual     qw( :log );
use Object::Remote;
use File::Basename;
use File::Spec;
use overload fallback => 1,
    bool  => sub { 1 },
    q("") => sub { sprintf q!ssh://%s:%s!, $_[0]->remote, $_[0]->path };

use aliased 'App::PMark::File::Local';

has remote      => (is => 'ro', required => 1);
has path        => (is => 'ro', required => 1);
has connected   => (is => 'ro', lazy => 1, builder => 1);

sub _build_connected {
    my ($self) = @_;
    log_debug { sprintf q!connecting to '%s'!, $self->remote };
    return Local->new::on($self->remote, path => $self->path);
}

sub get {
    my ($self) = @_;
    log_debug { sprintf q!reading '%s' on '%s'!,
        $self->path,
        $self->remote,
    };
    return $self->connected->get;
}

sub put {
    my ($self, $content) = @_;
    log_debug { sprintf q!writing '%s' on '%s'!,
        $self->path,
        $self->remote,
    };
    return $self->connected->put($content);
}

sub sibling {
    my ($self, @path) = @_;
    return $self->connected->sibling(@path);
}

with 'App::PMark::File';

1;
