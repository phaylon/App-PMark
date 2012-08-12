package App::PerlMark::Profile::HasModules;
use Moo::Role;

use aliased 'App::PerlMark::Profile::Module';

has module_map => (is => 'lazy');

sub _build_module_map { {} }

sub modules {
    my ($self) = @_;
    return values %{$self->module_map};
}

sub module {
    my ($self, $name) = @_;
    return $self->module_map->{$name}
        ||= Module->new(name => $name);
}

sub module_names {
    my ($self) = @_;
    return sort keys %{$self->module_map};
}

1;
