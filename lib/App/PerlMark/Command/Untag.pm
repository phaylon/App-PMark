package App::PerlMark::Command::Untag;
use Moo;
use List::Util          qw( max );
use App::PerlMark::Util qw( textblock );
use Log::Contextual     qw( :log );

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
    log_info {
        my $word = @removed == 1 ? 'tag' : 'tags';
        @removed
        ? "removed $word [@removed] from module $name"
        : "nothing to remove from module $name",
    };
    return 1;
}

sub _untag_all_versions {
    my ($self, $name, $module, @tags) = @_;
    my $count = 0;
    for my $version ($module->versions) {
        my @removed = grep { $version->untag($_) } @tags;
        my $word = @removed == 1 ? 'tag' : 'tags';
        log_info {
            my $vstring = $version->version;
            @removed
            ? "removed $word [@removed] from module $name ($vstring)"
            : "nothing to untag from module $name ($vstring)";
        };
        $count++;
    }
    log_info { "module $name has no version-specific data" }
        unless $count;
    return 1;
}

sub _untag_by_versions {
    my ($self, $option, $name, $module, @tags) = @_;
    my $options = $self->options;
    for my $vstring (@{$options->with_version}) {
        my $version = $module->has_version($vstring);
        log_warn { "unknown version for module $name '$vstring" }
            unless $version;
        my @removed = grep { $version->untag($_) } @tags;
        log_info {
            my $word = @removed == 1 ? 'tag' : 'tags';
            @removed
            ? "removed $word [@removed] from module $name ($vstring)"
            : "nothing to untag from module $name ($vstring)";
        };
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
