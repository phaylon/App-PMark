package App::PerlMark::Command::Export;
use Moo;
use File::Basename;
use App::PerlMark::Util qw( ssh_remote assert_path );

sub _command_arguments { '<target>' }

sub _command_options {
    ['mkpath|p', q!try to create the directory if it doesn't exist!],
}

sub _option_constraints {
    my ($class, $options, $args) = @_;
    [not(scalar @$args), 'Missing an export target argument'],
    [@$args > 1, 'Expected only a single target argument'],
}

sub run {
    my ($self, $profile, $target) = @_;
    if ($target eq '-') {
        $self->_export_to_stdout($profile);
    }
    elsif (my $remote = ssh_remote $target) {
        $self->_export_via_ssh($profile, $remote);
    }
    else {
        $self->_export_to_file($profile, $target);
    }
}

sub _export_to_file {
    my ($self, $profile, $file) = @_;
    assert_path dirname $file
        if $self->options->mkpath;
    open my $fh, '>:utf8', $file
        or die "$0: Unable to export to file '$file': $!\n";
    print $fh $profile->as_json;
}

sub _export_via_ssh {
    my ($self, $profile, $remote) = @_;
    my ($remote_target, $remote_path) = @$remote;
    my ($fh, $error) = App::PerlMark::Util
        ->can::on($remote_target, 'open_file')
        ->($remote_path, '>:utf8', mkpath => $self->options->mkpath);
    die sprintf "$0: Unable to export to file '%s' on %s: %s\n",
        $remote_path, $remote_target, $error,
        if $error;
    print $fh $profile->as_json;
}

sub _export_to_stdout {
    my ($self, $profile) = @_;
    my $json = $profile->as_json;
    chomp $json;
    print "$json\n";
}

with qw(
    App::PerlMark::Command
);

1;
