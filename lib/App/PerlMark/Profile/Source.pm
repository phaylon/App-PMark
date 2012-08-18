package App::PerlMark::Profile::Source;
use Moo;
use File::Spec;
use App::PerlMark::Util qw( ssh_remote assert_path fail );
use Object::Remote;
use Try::Tiny;
use HTTP::Tiny;

has path    => (is => 'lazy');
has file    => (is => 'lazy');
has name    => (is => 'ro', required => 1);
has target  => (is => 'rw', required => 1);
has profile => (is => 'lazy');
has parent  => (is => 'ro', required => 1, weak_ref => 1);

sub TO_JSON {
    my ($self) = @_;
    return { __source__ => {
        name    => $self->name,
        target  => $self->target,
    }};
}

sub _build_path {
    my ($self) = @_;
    return File::Spec->catdir(
        $self->parent->path,
        'source',
        $self->name,
    );
}

sub _build_file {
    my ($self) = @_;
    return File::Spec->catfile($self->path, 'profile.json');
}

sub _build_profile {
    my ($self) = @_;
    require App::PerlMark::Profile;
    my $profile = App::PerlMark::Profile->new(
        is_readonly => 1,
        is_relaxed  => 1,
        file        => $self->file,
    );
    return $profile;
}

sub update {
    my ($self) = @_;
    my $target = $self->target;
    if (my $remote = ssh_remote $target) {
        return $self->_update_from_ssh($remote);
    }
    elsif ($target =~ m{^https?://}) {
        return $self->_update_from_http($target);
    }
    else {
        return $self->_update_from_file($target);
    }
}

sub _update_from_http {
    my ($self, $target_uri) = @_;
    assert_path $self->path;
    my $response = HTTP::Tiny->new->mirror($target_uri, $self->file);
    return undef
        if $response->{success};
    return sprintf '%d: %s', $response->{status}, $response->{reason};
}

sub _update_from_file {
    my ($self, $target_file) = @_;
    open my $fh, '<:utf8', $target_file
        or return "Unable to read from '$target_file': $!";
    $self->_write_json(do { local $/; <$fh> });
    return undef;
}

sub _update_from_ssh {
    my ($self, $remote) = @_;
    my ($remote_target, $remote_path) = @$remote;
    try {
        my $file = App::PerlMark::File
            ->new::on($remote_target, path => $remote_path);
#    my $cb = App::PerlMark::Util->can::on($remote_target, 'read_file');
#    my ($body, $error) = $cb->($remote_path, '<:utf8');
        $self->_write_json($file->read_all);
        return undef;
    }
    catch {
        return $_;
    };
}

sub _write_json {
    my ($self, $json) = @_;
    my $file = $self->file;
    assert_path $self->path;
    open my $fh, '>:utf8', $file
        or fail sprintf "unable to write profile for '%s' source '%s': %s",
        $self->name, $file, $!;
    print $fh $json;
    return 1;
}

1;
