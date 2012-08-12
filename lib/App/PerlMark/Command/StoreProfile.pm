package App::PerlMark::Command::StoreProfile;
use Moo::Role;

after run => sub {
    my ($self, $profile) = @_;
    $profile->store;
};

1;
