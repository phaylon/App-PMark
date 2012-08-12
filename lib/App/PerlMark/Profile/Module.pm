package App::PerlMark::Profile::Module;
use Moo;
use Module::Metadata;
use List::MoreUtils     qw( uniq );

use aliased 'App::PerlMark::Profile::Module::Version';

has name        => (is => 'ro', required => 1);
has recommended => (is => 'rw', default => sub { 0 });
has version_map => (is => 'ro', default => sub { {} });

sub TO_JSON {
    my ($self) = @_;
    return { __module__ => {
        name        => $self->name,
        recommended => $self->recommended,
        tag_map     => $self->tag_map,
        version_map => $self->version_map,
        note_map    => $self->note_map,
    }};
}

sub versions {
    my ($self) = @_;
    return sort {
        $a->version cmp $b->version;
    } values %{$self->version_map};
}

sub current_version {
    my ($self) = @_;
    my $module = $self->name;
    my $meta = Module::Metadata
        ->new_from_module($module, collect_pod => 0);
    my $version = $meta->version($module);
    die "Unable to find a version for module '$module'\n"
        unless defined($version) and length($version);
    return $self->version($version);
}

sub version {
    my ($self, $version) = @_;
    die "$0: Version string cannot be empty\n"
        unless length $version;
    return $self->version_map->{$version}
        ||= Version->new(version => "$version");
}

sub all_tags {
    my ($self) = @_;
    my @versions = values %{$self->version_map};
    return uniq sort map { ($_->tags) } @versions, $self;
}

with qw(
    App::PerlMark::Profile::HasTags
    App::PerlMark::Profile::HasNotes
);

1;
