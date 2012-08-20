package App::PMark::Command;
use Moo::Role;
use File::Spec;
use File::HomeDir;
use App::PMark::Profile;
use App::PMark::Util        qw( ssh_remote textblock is_error );
use Object::Remote;
use Log::Contextual         qw( :log );
use Try::Tiny;

requires qw( app );

my $_default_profile = $ENV{PERLMARK_PROFILE}
    || File::Spec->catdir(File::HomeDir->my_data, '.pmark');

my @_version_modules = qw(
    App::PMark
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
            "\t# $comment\n\t${prefix}pmark $command $arguments";
        } $self->examples;
    $description = "$description\n\t$storage_msg\n";
    $description = "$description\n$examples\n"
        if $self->examples;
    $description = "$description\nOptions:\n";
    return $description;
};

around execute => sub {
    my ($orig, $self, $options, $args) = @_;
    return try {
        log_debug { 'building profile' };
        my $profile = $self->_make_profile($options);
        log_debug { 'running command' };
        $self->$orig($profile, $options, @$args);
        log_debug { 'running post-execute hooks' };
        $self->_post_execute($profile);
        return 1;
    }
    catch {
        if (is_error $_, 'App::PMark::Exception') {
            printf "Error: %s\n", $_->message;
            return 0;
        }
        die $_;
    };
};

around opt_spec => sub {
    my ($orig, $self, @args) = @_;
    my @specific = $self->$orig(@args);
    return (
        ['Generic Options:'],
        [   'profile=s' => 'location of the profile directory',
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
    return App::PMark::Profile->new(file => "$path/profile.json");
}

1;
