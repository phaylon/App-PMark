package App::PerlMark::Command::Update;
use Moo;
use List::Util  qw( max );

sub _command_arguments { '<identifiers>' }

sub run {
    my ($self, $profile, @names) = @_;
    my @sources = $self->_find_sources($profile, @names);
    for my $source (@sources) {
        printf "Updating '%s' from %s\n", $source->name, $source->target;
        my $error = $source->update;
        warn "  Error: $error\n"
            if $error;
    }
    return 1;
}

sub _find_sources {
    my ($self, $profile, @names) = @_;
    if (@names) {
        return map {
            $profile->source($_)
                or die "$0: Unknown source '$_'\n";
        } sort @names;
    }
    return sort { $a->name cmp $b->name } $profile->sources;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
