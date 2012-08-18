package App::PerlMark::Command::Tag;
use Moo;
use App::PerlMark::Util qw( textblock );
use List::Util          qw( max );
use Log::Contextual     qw( :log );

extends 'App::Cmd::Command';

sub abstract { 'add tags to modules and versions' }

sub usage_desc { '%c tag %o <module> <tags>...' }

sub opt_spec {
    ['with-version|v=s@',       'add tags to a specific module version'],
    ['with-current-version|c',  'add tags to the current module version'],
}

sub description {
    return textblock q{
        This command adds tags to modules and specific module versions.

        Without any further options, the tags will be applied to the
        module itself. The '--with-current-version' option will apply the
        tags to the currently installed version of the module, while
        '--with-version' allows you to supply multiple explicit versions
        the tags should be applied to.

        You can introspect all available tags with the 'tags' command.
        Tags can be removed from modules and versions with the 'untag'
        command.
    };
}

sub examples {
    ['set tags on generic module',
     'Web::Simple web pure-perl'],
    ['set tags on current version',
     '--with-current-version Foo fail-win32 fail'],
    ['set tags on specific versions',
     '--with-version 1.0 --with-version 1.1 Foo fail-win32 fail'],
}

sub execute {
    my ($self, $profile, $options, $module_name, @tags) = @_;
    return 1
        unless @tags;
    my $module = $profile->module($module_name);
    my $is_set;
    if (defined( my $versions = $options->with_version )) {
        for my $version_string (@$versions) {
            my $version = $module->version($version_string);
            log_info {
                "adding tags to module $module_name ($version_string)";
            };
            $self->_add_tags($version, @tags);
            $is_set++;
        }
    }
    if ($options->with_current_version) {
        my $version = $module->current_version;
        log_info { sprintf "adding tags to module $module_name (%s)",
            $version->version,
        };
        $self->_add_tags($version, @tags);
        $is_set++;
    }
    unless ($is_set) {
        log_info { "adding tags to module $module_name" };
        $self->_add_tags($module, @tags);
    }
    return 1;
}

sub _add_tags {
    my ($self, $target, @tags) = @_;
    my $max_len = max map length, @tags;
    for my $tag (@tags) {
        my $added = $target->tag($tag);
        log_info { join ' ',
            "tag '$tag'",
            ($added ? 'created' : 'already exists'),
        };
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
