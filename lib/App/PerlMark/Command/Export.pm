package App::PerlMark::Command::Export;
use Moo;
use File::Basename;
use App::PerlMark::Util qw( ssh_remote assert_path textblock fail );

extends 'App::Cmd::Command';

sub abstract { 'export your profile data' }

sub usage_desc { '%c export %o <target>' }

sub opt_spec {
    ['mkpath|p', q!try to create the directory if it doesn't exist!],
}

sub validate_args {
    my ($self, $option, $args) = @_;
    $self->usage_error('Missing an export target argument')
        unless @$args;
    $self->usage_error('Expected only a single export target argument')
        if @$args > 1;
    return 1;
}

sub description {
    return textblock q{
        This command allows you to export your profile data into a file.

        The produced JSON file can be subscribed to by anyone who has
        supported access to the file. See the 'subscribe' command for more
        information about this.

        If you pass the '--mkpath' option the directory of the file will
        be created if it doesn't exist yet.
    };
}

sub examples {
    ['export to stdout', '-'],
    ['export via SSH', 'ssh://user@example.com:file.json'],
    ['export to file', 'file.json'],
}

sub execute {
    my ($self, $profile, $option, $target) = @_;
    if ($target eq '-') {
        $self->_export_to_stdout($profile);
    }
    elsif (my $remote = ssh_remote $target) {
        $self->_export_via_ssh($profile, $option, $remote);
    }
    else {
        $self->_export_to_file($profile, $option, $target);
    }
}

sub _export_to_file {
    my ($self, $profile, $option, $file) = @_;
    assert_path dirname $file
        if $option->{mkpath};
    open my $fh, '>:utf8', $file
        or fail "unable to export to file '$file': $!";
    print $fh $profile->as_json;
}

sub _export_via_ssh {
    my ($self, $profile, $option, $remote) = @_;
    my ($remote_target, $remote_path) = @$remote;
    my ($fh, $error) = App::PerlMark::Util
        ->can::on($remote_target, 'open_file')
        ->($remote_path, '>:utf8', mkpath => $option->{mkpath});
    fail sprintf "unable to export to file '%s' on %s: %s",
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
