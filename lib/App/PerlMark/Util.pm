use strictures 1;

package App::PerlMark::Util;
use File::Path      qw( make_path );
use File::Basename;
use Exporter        qw( import );

our @EXPORT_OK = qw(
    patterns_to_regexps
    pattern_to_regexp
    ssh_remote
    open_file
    assert_path
);

sub assert_path {
    my ($path) = @_;
    make_path $path, { error => \my $errors };
    if ($errors and @$errors) {
        warn sprintf "Unable to create directory '%s': %s\n", %$_
            for @$errors;
        exit 1;
    }
    return 1;
}

sub open_file {
    my ($file, $mode, $mkpath) = @_;
    if ($mkpath) {
        make_path dirname $file, { error => \my $errors };
        return undef, join "\n", @$errors
            if $errors and @$errors;
    }
    open(my $fh, $mode, $file);
    return undef, $!
        unless $fh;
    return $fh, undef;
}

sub ssh_remote {
    my ($string) = @_;
    my $orig = $string;
    return undef
        unless $string =~ s{^ssh://}{};
    my ($remote, $path) = split m{:}, $string, 2;
    die "$0: SSH remote '$orig' is missing a file path element\n"
        unless defined $path and length $path;
    die "$0: SSH remote '$orig' is missing a remote specification\n"
        unless defined $remote and length $remote;
    return [$remote, $path];
}

sub patterns_to_regexps {
    my ($ignore_case, @patterns) = @_;
    return map { pattern_to_regexp($ignore_case, $_) } @_;
}

sub pattern_to_regexp {
    my ($ignore_case, $pattern) = @_;
    my $orig = $pattern;
    my @parts;
    while (length $pattern) {
        if ($pattern =~ s{^\*+}{}) {
            push @parts, qr{.*};
        }
        elsif ($pattern =~ s{^\++}{}) {
            push @parts, qr{.+};
        }
        elsif ($orig eq $pattern and $pattern =~ s{^\%}{}) {
            push @parts, qr{^};
        }
        elsif ($pattern =~ s{\%$}{}) {
            push @parts, qr{$};
        }
        elsif ($pattern =~ s{^([^*+]+)}{}) {
            push @parts, $ignore_case ? qr{\Q$1\E} : qr{\Q$1\E}i;
        }
        else {
            die "$0: Unable to parse '...$pattern' in '$orig'\n";
        }
    }
    my $body = join '', @parts;
    my $rx   = qr{$body};
    return $rx;
}

1;
