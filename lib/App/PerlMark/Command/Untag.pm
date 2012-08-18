package App::PerlMark::Command::Untag;
use Moo;
use List::Util          qw( max );
use App::PerlMark::Util qw( textblock );

extends 'App::Cmd::Command';

sub abstract { 'remove tags from modules and versions' }

sub usage_desc { '%c untag %o <module> <tags>...' }

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Requires a module argument')
        unless @$args;
    return 1;
}

sub opt_spec {
    ['with-version|v=s@',   'remove from a specific module versions'],
    ['all-versions|a',      'remove tag on all module versions'],
}

sub description {
    return textblock q{
        This command removes tags from modules and versions.

        Without any other options, only tags from the module itself will
        be removed, and tags on the version left intact. You can use
        '--with-version' to supply specific versions from which the tags
        should be removed. The '--all-versions' options can be used to
        remove tags from all module versions, including the tags on the
        module itself.

        You can use the 'tag' command to add tags to modules and versions,
        and search the list of tags with the 'tags' command.
    };
}

sub examples {
    ['remove main module tags baz and qux',
     'Foo::Bar baz qux'],
    ['remove tags from specific versions',
     '--with-version 1.0 --with-version 1.1 Foo::Bar baz qux'],
    ['remove tags from all versions',
     '--all-versions Foo::Bar baz qux'],
}

sub execute {
    my ($self, $profile, $option, $name, @tags) = @_;
    return 1
        unless @tags;
    my $module = $profile->module($name);
    if ($option->with_version) {
        $self->_untag_by_versions($option, $name, $module, @tags);
    }
    elsif ($option->all_versions) {
        $self->_untag_plain($profile, $name, $module, @tags);
        $self->_untag_all_versions($name, $module, @tags);
    }
    else {
        $self->_untag_plain($name, $module, @tags);
    }
    return 1;
}

sub _untag_plain {
    my ($self, $name, $module, @tags) = @_;
    my @removed = grep { $module->untag($_) } @tags;
    printf "%s: %s\n", $name, @removed
        ? sprintf('Removed tags [%s]', join ' ', @removed)
        : 'Nothing to untag';
    return 1;
}

sub _untag_all_versions {
    my ($self, $name, $module, @tags) = @_;
    my $count = 0;
    for my $version ($module->versions) {
        my @removed = grep { $version->untag($_) } @tags;
        printf "$name %s: %s\n", $version->version, @removed
            ? sprintf('Removed tags [%s]', join ' ', @removed)
            : 'Nothing to untag';
        $count++;
    }
    print "No specific $name versions found\n"
        unless $count;
    return 1;
}

sub _untag_by_versions {
    my ($self, $option, $name, $module, @tags) = @_;
    my $options = $self->options;
    for my $version_string (@{$options->with_version}) {
        my $version = $module->has_version($version_string);
        print "Unknown $name version '$version_string'\n" and next
            unless $version;
        my @removed = grep { $version->untag($_) } @tags;
        printf "$name %s: %s\n", $version_string, @removed
            ? sprintf('Removed tags [%s]', join ' ', @removed)
            : 'Nothing to untag';
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
