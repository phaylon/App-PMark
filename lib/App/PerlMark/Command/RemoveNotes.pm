package App::PerlMark::Command::RemoveNotes;
use Moo;
use App::PerlMark::Util qw( textblock );
use Log::Contextual     qw( :log );

extends 'App::Cmd::Command';

sub abstract { 'remove notes from modules' }

sub command_names { 'rm-notes', 'rmnotes' }

sub opt_spec {
    ['module|m=s@', 'restrict the set of modules from which to remove'],
}

sub usage_desc { '%c rm-notes %o <note-ids>...' }

sub description {
    return textblock q{
        This command allows you to remove notes from modules by supplying
        their IDs.

        The ID of a note will be displayed in the 'info' output of the
        module. These IDs are generated from a digest of the message.

        If you supplied a note to multiple modules, this command will
        remove them from all modules and versions.

        An alias named 'rmnotes' is available as well.

        See the 'note' command on information about adding notes to
        modules and versions.
    };
}

sub examples {
    ['remove the note with the specified ID',
     'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3'],
}

sub _find_modules {
    my ($self, $profile, $options) = @_;
    if (my $modules = $options->module) {
        return map {
            my $module = $profile->has_module($_);
            log_warn { "unknown module '$_'" }
                unless $module;
            ($module ? $module : ());
        } @$modules;
    }
    return $profile->modules;
}

sub execute {
    my ($self, $profile, $options, @note_ids) = @_;
    my @modules = $self->_find_modules($profile, $options)
        or return 1;
    NOTE: for my $note_id (@note_ids) {
        $note_id =~ s{^\<(.+)\>$}{$1};
        my $seen;
        MODULE: for my $module (@modules) {
            if (my $note = $module->remove_note($note_id)) {
                log_info { sprintf q!removed note %s from %s!,
                    $note_id,
                    $module->name,
                };
                $seen++;
            }
            for my $version ($module->versions) {
                if (my $note = $version->remove_note($note_id)) {
                    log_info { sprintf q!removed note %s from %s (%s)!,
                        $note_id,
                        $module->name,
                        $version->version,
                    };
                    $seen++;
                }
            }
        }
        log_warn { "unable to find note $note_id" }
            unless $seen;
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::Role::StoreProfile
);

1;
