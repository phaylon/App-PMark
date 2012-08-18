package App::PerlMark;
use Moo;
use Module::Runtime             qw( use_module );
use List::Util                  qw( max );
use Log::Contextual             qw( set_logger );
use Log::Dispatch;

extends 'App::Cmd';

our $VERSION = '0.001';
$VERSION = eval $VERSION;

sub allow_any_unambiguous_abbrev { 1 }

around _plugins => sub {
    my ($orig, $self, @args) = @_;
    return grep { not m{^App::PerlMark::Command::Role::} }
        $self->$orig(@args);
};

sub usage_desc { '%c <command> %o <arguments>...' }

sub global_opt_spec {
    ['version|V', 'print versions and exit'],
    ['debug|D',   'enable debugging output'],
}

my @_version_modules = qw(
    App::PerlMark
    Object::Remote
    CPS::Future
    Module::Runtime
    File::HomeDir
);

sub show_versions {
    my ($self, $options, $args) = @_;
    my $max_len = max map length, @_version_modules;
    (my $perl_version = $^V) =~ s{^v}{};
    printf "%-${max_len}s  %s\n", @$_
        for ['perl', $perl_version],
            map [$_, $_->VERSION],
            map use_module($_),
            sort @_version_modules;
    return 1;
};

before execute_command => sub {
    my ($self) = @_;
    if ($self->global_options->version) {
        $self->show_versions;
        exit;
    }
    my %prefix = (
        debug   => '[debug]',
        warning => 'Warning:',
    );
    set_logger(Log::Dispatch->new(
        callbacks => sub {
            my %arg = @_;
            return join ' ',
                $prefix{$arg{level}} || (),
                $arg{message};
        },
        outputs => [
            ['Screen',
                newline     => 1,
                min_level   => $self->global_options->debug
                    ? 'debug'
                    : 'info',
            ],
        ],
    ));
};

1;

__END__

=head1 NAME

App::PerlMark - Distributed module recommendations, notes and tags

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COMMANDS

=head2 help

=head2 recommend
=head2 unrecommend

=head2 search
=head2 info

=head2 note
=head2 rm-notes

=head2 tag
=head2 untag
=head2 tags

=head2 export

=head2 subscribe
=head2 unsubscribe
=head2 sources
=head2 update

=head2 forget

=head1 AUTHOR

Robert Sedlacek <rs@474.at>

=head1 COPYRIGHT

Copyright (c) 2012 the App::PerlMark L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
