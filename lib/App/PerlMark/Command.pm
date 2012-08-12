package App::PerlMark::Command;
use Moo::Role;
use Getopt::Long::Descriptive   qw( prog_name describe_options );
use File::Spec;
use File::HomeDir;
use App::PerlMark::Profile;
use App::PerlMark::Util         qw( ssh_remote );
use Object::Remote;

my $_default_profile = $ENV{PERLMARK_PROFILE}
    || File::Spec->catdir(File::HomeDir->my_data, '.perlmark');

has options => (
    is          => 'ro',
    init_arg    => 'options',
    required    => 1,
);

sub _command_options    { () }
sub _command_arguments  { '' }
sub _option_constraints { () }

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

sub _validate_options {
    my ($class, $options) = @_;
    my @errors = map {
        ($_->[0] ? $_->[1] : ());
    } $class->_option_constraints($options, [@ARGV]);
}

sub run_with_options {
    my ($class, $command) = @_;
    my $arguments = $class->_command_arguments;
    my @options   = $class->_command_options;
    my ($options, $usage) = describe_options(
        join(' ',
            'Usage:',
            '%c',
            $command,
            length($arguments) ? $arguments : (),
            '%o',
        ),
        [],
        [   'profile|p=s',
            'path to the profile directory that should be used',
            { default => $_default_profile },
        ],
        @options
            ? ([], @options)
            : (),
        [],
        [   'version|V',
            'print version information and exit',
        ],
        [   'help|h|?',
            'print this help and exit',
        ],
        [],
    );
    if (my @errors = $class->_validate_options($options)) {
        warn "$0: $_\n" for @errors;
        print $usage->text;
        exit 1;
    }
    if ($options->help) {
        print $usage->text;
        exit;
    }
    if ($options->version) {
        require App::PerlMark;
        printf "%s (%s) %s\n",
            'App::PerlMark',
            $0,
            App::PerlMark->VERSION;
        exit;
    }
    my $profile = $class->_make_profile($options);
    my $object  = $class->new(options => $options);
    $object->run($profile, @ARGV);
    return 1;
}

1;
