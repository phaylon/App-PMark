package App::PerlMark::Command::Note;
use Moo;
use App::PerlMark::Util qw( textblock );
use File::Temp;

extends 'App::Cmd::Command';

sub abstract { 'add notes to modules and module versions' }

sub usage_desc { '%c note %o <modules>...' }

sub opt_spec {
    ['message|m=s',              'shortcut for single line messages'],
    ['with-version|v=s@',        'add note to a specific module version'],
    ['with-current-version|c',   'add note to the current module version'],
}

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Version specific notes can only take one module')
        if @$args > 1 and $option->with_version;
    return 1;
}

sub description {
    return textblock q{
        This command adds notes to modules and specific module versions.

        The notes will contain the timestamp and an ID that can be used to
        remove them via the 'rm-notes' command.

        You can specify a message as an option with '--message'. If this
        option is not specified, the program in the EDITOR environment
        variable will be run to compose the message.

        You can use '--with-version' to pass a specific version to attach
        the message to, or '--with-current-version' to attach the message
        to the version of the module that is currently installed. If
        nothing version specific is given, the note will be attached to
        the generic module name.

        Note that if you attach a note to specified versions, you can't
        specify more than one module to add it to.

        The notes will be visible with the 'info' command or by any other
        command capable of showing full information.
    };
}

sub examples {
    ['open an editor to add a note to Moose',
     'Moose',
     'EDITOR=vim'],
    ['add a note to multiple modules from the command line',
     '--message "Needs more documentation" Foo::Bar Foo::Baz'],
    ['add a note to a specific version',
     '--message "Win32 incompatible" --with-version 0.23 Foo::Bar'],
    ['add a note to the currently installed version',
     '--message "Win32 OK" --with-current-version Foo::bar'],
}

sub execute {
    my ($self, $profile, $option, @modules) = @_;
    return unless @modules;
    $self->_add_note_to($profile, $option, @modules);
}

sub _add_note_to {
    my ($self, $profile, $option, @modules) = @_;
    my $text = $self->_find_note_text($option);
    for my $name (@modules) {
        my $module = $profile->module($name);
        my $is_set;
        if (my $versions = $option->with_version) {
            for my $version_string (@$versions) {
                my $version = $module->version($version_string);
                my $note = $version->add_note($text);
                printf "Added note %s to %s (%s)\n",
                    $note->id,
                    $name,
                    $version_string;
                $is_set++;
            }
        }
        if ($option->with_current_version) {
            my $version = $module->current_version;
            my $note = $version->add_note($text);
            printf "Added note %s to %s (%s)\n",
                $note->id,
                $name,
                $version->version;
            $is_set++;
        }
        unless ($is_set) {
            my $note = $module->add_note($text);
            printf "Added note %s to %s\n", $note->id, $name;
        }
    }
    return 1;
}

sub _find_note_text {
    my ($self, $option) = @_;
    if (defined(my $text = $option->{message})) {
        return $text;
    }
    return $self->_note_from_editor;
}

sub _note_from_editor {
    my ($self) = @_;
    my $editor = $ENV{EDITOR};
    die "$0: Environment variable EDITOR is not set\n"
        unless defined $editor and length $editor;
    my $file  = File::Temp->new;
    my $error = system($editor, $file->filename);
    die "$0: Editor returned with non-zero exit value\n"
        if $error;
    my $answer = '';
    do {
        print "Add note? [y/n] ";
        chomp( $answer = <STDIN> );
    } until $answer eq 'y' or $answer eq 'n';
    if ($answer eq 'n') {
        print "Note not added\n";
        exit;
    }
    open my $fh, '<:utf8', $file->filename
        or die "$0: Could not read tempfile for note '$file': $!\n";
    return do { local $/; <$fh> };
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
