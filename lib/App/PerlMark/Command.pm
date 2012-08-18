package App::PerlMark::Command;
use Moo::Role;
use File::Spec;
use File::HomeDir;
use App::PerlMark::Profile;
use App::PerlMark::Util         qw( ssh_remote textblock );
use Object::Remote;

requires qw(
    app
);

my $_default_profile = $ENV{PERLMARK_PROFILE}
    || File::Spec->catdir(File::HomeDir->my_data, '.perlmark');

my @_version_modules = qw(
    App::PerlMark
    Object::Remote
    CPS::Future
    Module::Runtime
    File::HomeDir
);

before validate_args => sub {
    my ($self, $options, $args) = @_;
    if ($options->help) {
        print $self->usage->text;
        exit;
    }
    if ($options->version) {
        $self->app->show_versions;
    }
};

sub stores_profile { 0 }

sub examples { () }

sub fail {
    my ($self, @msg) = @_;
    my $msg = join '', @msg;
    die "Error: $msg\n";
}

around description => sub {
    my ($orig, $self, @args) = @_;
    my $command     = ($self->command_names)[0];
    my $description = $self->$orig(@args);
    my $storage_msg = $self->stores_profile
        ? "This command WILL modify your profile data."
        : "This command WILL NOT modify your profile data.";
    my $examples    = join "\n\n",
        "Examples:",
        map {
            my ($comment, $arguments, $prefix) = @$_;
            $prefix = $prefix ? "$prefix " : '';
            "\t# $comment\n\t${prefix}perlmark $command $arguments";
        } $self->examples;
    $description = "$description\n\t$storage_msg\n";
    $description = "$description\n$examples\n"
        if $self->examples;
    $description = "$description\nOptions:\n";
    return $description;
};

around execute => sub {
    my ($orig, $self, $options, $args) = @_;
    my $profile = $self->_make_profile($options);
    $self->$orig($profile, $options, @$args);
    $self->_post_execute($profile);
    return 1;
};

around opt_spec => sub {
    my ($orig, $self, @args) = @_;
    my @specific = $self->$orig(@args);
    return (
        ['Generic Options:'],
        [   'profile|p=s' => 'location of the profile directory',
            { default => $_default_profile },
        ],
        @specific
            ? ([], ['Command Specific Options:'], @specific)
            : (),
        [],
        ['Meta Options:'],
        ['help|h|?'     => 'print short help and exit'],
        ['version|V'    => 'print version and exit'],
    );
};

sub _post_execute { }

sub _make_profile {
    my ($self, $options) = @_;
    my $path = $options->profile;
    if (my $remote = ssh_remote $path) {
        my ($remote_target, $remote_path) = @$remote;
        return App::PerlMark::Profile
            ->new::on($remote_target, path => $remote_path);
    }
    return App::PerlMark::Profile
        ->new(path => $path);
}

1;
