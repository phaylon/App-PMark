package App::PMark::Profile::Source;
use Moo;
use File::Spec;
use App::PMark::Util qw( ssh_remote assert_path fail coerce_file );
use Object::Remote;
use Try::Tiny;
use HTTP::Tiny;

has file    => (is => 'lazy');
has name    => (is => 'ro', required => 1);
has target  => (is => 'rw', required => 1, coerce => coerce_file);
has profile => (is => 'lazy');
has parent  => (is => 'ro', required => 1, weak_ref => 1);

sub TO_JSON {
    my ($self) = @_;
    return { __source__ => {
        name    => $self->name,
        target  => '' . $self->target,
    }};
}

sub _build_file {
    my ($self) = @_;
    return $self->parent->file
        ->sibling('source', $self->name, 'profile.json');
}

sub _build_profile {
    my ($self) = @_;
    require App::PMark::Profile;
    my $profile = App::PMark::Profile->new(
        is_readonly => 1,
        is_relaxed  => 1,
        file        => $self->file,
    );
    return $profile;
}

sub update {
    my ($self) = @_;
    $self->file->put($self->target->get);
    return 1;
}

1;
