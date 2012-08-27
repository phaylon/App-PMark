package TestProfile;
use Moo;
use File::Temp;
use IPC::System::Simple qw( capturex runx );
use FindBin;

has tempdir     => (is => 'lazy');
has executable  => (is => 'lazy');
has lib_dirs    => (is => 'lazy');

sub run {
    my ($self, @args) = @_;
    my @command = (
        $^X,
        (map { "-I$_" } @{ $self->lib_dirs }),
        $self->executable,
        @args,
        '--profile' => $self->tempdir->dirname,
    );
    return capturex @command;
}

sub runall {
    my ($self, @commands) = @_;
    return map { scalar $self->run(@$_) } @commands;
}

sub datafile { join '/', $_[0]->tempdir->dirname, 'profile.json' }

sub _build_tempdir      { File::Temp->newdir }
sub _build_executable   { "$FindBin::Bin/../bin/pmark" }
sub _build_lib_dirs     { [map "$FindBin::Bin/$_", 'lib', '../lib'] }

1;
