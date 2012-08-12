package App::PerlMark::Command::DeepQuery;
use Moo::Role;
use List::MoreUtils qw( uniq );

sub query_recommended_by {
    my ($self, $profile, $name) = @_;
    my @by;
    push @by, 'you'
        if $profile->module($name)->recommended;
    push @by, sort map {
        $_->profile->module($name)->recommended
            ? $_->name
            : ();
    } $profile->sources;
    return @by;
}

sub query_counted_tags {
    my ($self, $profile, $name, $expand) = @_;
    my $gather = sub {
        my $module = shift;
        return uniq sort $module->tags, $expand ? $module->$expand : ();
    };
    my %tag;
    $tag{$_}++ for
        $profile->module($name)->$gather,
        map {
            ($_->profile->module($name)->$gather);
        } $profile->sources;
    my @tags =
        map  { [$_, $tag{$_}] }
        sort { $tag{$b} <=> $tag{$a} }
        keys %tag;
    return @tags;
}

sub query_counted_tags_all {
    my ($self, $profile, $name) = @_;
    return $self->query_counted_tags($profile, $name, sub {
        my $module = shift;
        return map { ($_->tags) } $module->versions;
    });
}

sub query_all_module_names {
    my ($self, $profile) = @_;
    my %module;
    $module{$_->name}++
        for $profile->modules,
            map { ($_->profile->modules) } $profile->sources;
    return sort keys %module;
}

1;
