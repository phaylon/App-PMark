package App::PerlMark::Command::Tag;
use Moo;
use List::Util          qw( max );
use Module::Metadata;

sub _command_arguments { '<module> <tags>...' }

sub _command_options {
    ['wv|with-version=s',        'add tags to a specific module version'],
    ['wcv|with-current-version', 'add tags to the current module version'],
    ['remove|r',                 'remove tags instead of adding them'],
}

sub _option_constraints {
    my ($class, $options, $args) = @_;
    [ $options->wv && $options->wcv,
      'Cannot add note to current and specific versions at the same time',
    ],
}

sub run {
    my ($self, $profile, $module_name, @tags) = @_;
    return 1
        unless @tags;
    my $module  = $profile->module($module_name);
    my $options = $self->options;
    my $method  = $options->remove ? '_remove_tags' : '_add_tags';
    if (defined( my $version_string = $options->wv )) {
        my $version = $module->version($version_string);
        printf "%s (%s):\n", $module_name, $version_string;
        $self->$method($version, @tags);
    }
    elsif ($options->wcv) {
        my $version = $module->current_version;
        printf "%s (%s):\n", $module_name, $version->version;
        $self->$method($version, @tags);
    }
    else {
        printf "%s (all versions):\n", $module_name;
        $self->$method($module, @tags);
    }
    return 1;
}

sub _add_tags {
    my ($self, $target, @tags) = @_;
    my $max_len = max map length, @tags;
    for my $tag (@tags) {
        my $added = $target->tag($tag);
        printf "  tag %-${max_len}s %s\n",
            $tag,
            $added ? 'created' : 'already exists';
    }
    return 1;
}

sub _remove_tags {
    my ($self, $target, @tags) = @_;
    my $max_len = max map length, @tags;
    for my $tag (@tags) {
        my $removed = $target->untag($tag);
        printf "  tag %-${max_len}s %s\n",
            $tag,
            $removed ? 'removed' : 'did not exist';
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
