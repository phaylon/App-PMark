package App::PerlMark::Command::RemoveNotes;
use Moo;

sub _command_arguments { '<note-ids>...' }

sub run {
    my ($self, $profile, @note_ids) = @_;
    my @modules = $profile->modules;
    NOTE: for my $note_id (@note_ids) {
        $note_id =~ s{^\<(.+)\>$}{$1};
        MODULE: for my $module (@modules) {
            if (my $note = $module->remove_note($note_id)) {
                printf "Removed note %s from %s\n",
                    $note_id,
                    $module->name;
                next NOTE;
            }
            for my $version ($module->versions) {
                if (my $note = $version->remove_note($note_id)) {
                    printf "Removed note %s from %s (%s)\n",
                        $note_id,
                        $module->name,
                        $version->version;
                    next NOTE;
                }
            }
        }
        printf "Unable to find note %s\n", $note_id;
    }
    return 1;
}

with qw(
    App::PerlMark::Command
    App::PerlMark::Command::StoreProfile
);

1;
