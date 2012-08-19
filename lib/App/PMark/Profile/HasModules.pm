package App::PMark::Profile::HasModules;
use Moo::Role;

use aliased 'App::PMark::Profile::Module';

has module_map => (is => 'rwp', lazy => 1, builder => 1);

sub modules {
    my ($self) = @_;
    $self->module_map;
    return values %{$self->module_map};
}

sub module {
    my ($self, $name) = @_;
    return $self->module_map->{$name}
        ||= Module->new(name => $name);
}

sub has_module {
    my ($self, $name) = @_;
    return $self->module_map->{$name};
}

sub module_names {
    my ($self) = @_;
    return sort keys %{$self->module_map};
}

sub remove_module {
    my ($self, $name) = @_;
    return delete $self->module_map->{$name};
}

1;
