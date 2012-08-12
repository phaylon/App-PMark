package App::PerlMark::Command::Note;
use Moo;
use File::Temp;

sub _command_arguments { '<modules>...' }

sub _command_options {
    ['message|m=s',              'shortcut for single line messages'],
    ['wv|with-version=s',        'add note to a specific module version'],
    ['wcv|with-current-version', 'add note to the current module version'],
}

sub _option_constraints {
    my ($class, $options) = @_;
    [ $options->wv && $options->wcv,
      'Cannot add note to current and specific versions at the same time',
    ],
    [ defined($options->message) && not(length $options->message),
      'Empty note messages are not allowed',
    ],
}

sub run {
    my ($self, $profile, @modules) = @_;
    return unless @modules;
    $self->_add_note_to($profile, @modules);
}

sub _add_note_to {
    my ($self, $profile, @modules) = @_;
    my $text    = $self->_find_note_text;
    my $options = $self->options;
    for my $name (@modules) {
        my $module = $profile->module($name);
        if (defined( my $version_string = $options->wv )) {
            my $version = $module->version($version_string);
            my $note = $version->add_note($text);
            printf "Added note %s to %s (%s)\n",
                $note->id,
                $name,
                $version_string;
        }
        elsif ($options->wcv) {
            my $version = $module->current_version;
            my $note = $version->add_note($text);
            printf "Added note %s to %s (%s)\n",
                $note->id,
                $name,
                $version->version;
        }
        else {
            my $note = $module->add_note($text);
            printf "Added note %s to %s\n", $note->id, $name;
        }
    }
    return 1;
}

sub _find_note_text {
    my ($self) = @_;
    if (defined(my $text = $self->options->message)) {
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
    App::PerlMark::Command::StoreProfile
);

1;
