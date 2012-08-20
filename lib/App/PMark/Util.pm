use strictures 1;

package App::PMark::Util;
use File::Path      qw( make_path );
use File::Basename;
use Exporter        qw( import );
use Module::Runtime qw( use_module );

our @EXPORT_OK = qw(
    patterns_to_regexps
    pattern_to_regexp
    ssh_remote
    open_file
    assert_path
    textblock
    fail
);

sub fail {
    use_module('App::PMark::Exception')->throw(join '', @_);
}

sub textblock {
    my ($text) = @_;
    $text =~ s{^[\s\n]+}{};
    $text =~ s{[\s\n]+$}{};
    $text =~ s{(\n+)[^\t\S\n]*}{$1\t}g;
    $text =~ s{^}{\t};
    $text =~ s{$}{\n};
    return $text;
}

sub assert_path {
    my ($path) = @_;
    make_path $path, { error => \my $errors };
    if ($errors and @$errors) {
        fail sprintf "unable to create directory '%s': %s",
            %{ $errors->[0] };
    }
    return 1;
}

sub read_file {
    my ($file, $mode) = @_;
    my ($fh,  $error) = open_file($file, $mode);
    return undef, $error
        if defined $error;
    return do { local $/; scalar <$fh> }, undef;
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
    fail "SSH remote '$orig' is missing a file path element"
        unless defined $path and length $path;
    fail "SSH remote '$orig' is missing a remote specification"
        unless defined $remote and length $remote;
    return [$remote, $path];
}

sub patterns_to_regexps {
    my ($ignore_case, @patterns) = @_;
    return map { pattern_to_regexp($ignore_case, $_) } @patterns;
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
        elsif ($pattern =~ s{^\%$}{}) {
            push @parts, qr{$};
        }
        elsif ($pattern =~ s{^([^*+%]+)}{}) {
            push @parts, $ignore_case ? qr{\Q$1\E} : qr{\Q$1\E}i;
        }
        else {
            fail "unable to parse '...$pattern' in '$orig'";
        }
    }
    my $body = join '', @parts;
    my $rx   = qr{$body};
    return $rx;
}

1;