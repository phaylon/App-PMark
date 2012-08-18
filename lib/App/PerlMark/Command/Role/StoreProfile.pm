package App::PerlMark::Command::Role::StoreProfile;
use Moo::Role;

around stores_profile => sub { 1 };

after _post_execute => sub {
    my ($self, $profile) = @_;
    $profile->store;
};

1;
