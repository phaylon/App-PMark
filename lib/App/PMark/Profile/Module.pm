package App::PMark::Profile::Module;
use Moo;
use Module::Metadata;
use List::MoreUtils     qw( uniq );
use App::PMark::Util    qw( fail );

use aliased 'App::PMark::Profile::Module::Version';

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

sub merge_with {
    my ($self, $other_module) = @_;
    $self->recommended($other_module->recommended);
    $self->merge_tags_with($other_module);
    $self->merge_notes_with($other_module);
    $self->merge_versions_with($other_module);
    return 1;
}

sub merge_versions_with {
    my ($self, $other_module) = @_;
    for my $other_version ($other_module->versions) {
        my $version = $self->version($other_version->version);
        $version->merge_tags_with($other_version);
        $version->merge_notes_with($other_version);
    }
    return 1;
}

sub versions {
    my ($self) = @_;
    return sort {
        $a->version cmp $b->version;
    } values %{$self->version_map};
}

sub has_version {
    my ($self, $version) = @_;
    return $self->version_map->{$version};
}

sub current_version {
    my ($self) = @_;
    my $module = $self->name;
    my $meta = Module::Metadata
        ->new_from_module($module, collect_pod => 0);
    fail "module $module does not seem to be installed"
        unless $meta;
    my $version = $meta->version($module);
    fail "unable to find a version for module '$module'"
        unless defined($version) and length($version);
    return $self->version($version);
}

sub version {
    my ($self, $version) = @_;
    fail "version string cannot be empty"
        unless length $version;
    return $self->version_map->{$version}
        ||= Version->new(version => "$version");
}

sub all_tags {
    my ($self) = @_;
    my @versions = values %{$self->version_map};
    return uniq sort map { ($_->tags) } @versions, $self;
}

with $_ for qw(
    App::PMark::Profile::HasTags
    App::PMark::Profile::HasNotes
);

1;
