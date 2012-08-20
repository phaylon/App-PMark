use strictures 1;

package App::PMark::Util;
use File::Path      qw( make_path );
use File::Basename;
use Exporter        qw( import );
use Module::Runtime qw( use_module );
use Scalar::Util    qw( blessed );

our @EXPORT_OK = qw(
    patterns_to_regexps
    pattern_to_regexp
    ssh_remote
    open_file
    assert_path
    textblock
    fail
    make_file
    coerce_file
    is_error
);

sub is_error {
    my ($value, $class) = @_;
    return undef
        unless blessed $value;
    $class = 'App::PMark::Exception'
        unless defined $class;
    return $value->isa($class);
}

sub fail {
    use_module('App::PMark::Exception')->throw(join '', @_);
}

sub coerce_file {
    return sub { make_file(@_) };
}

sub make_file {
    my ($spec) = @_;
    if ($spec =~ m{^ssh://(.*)$}) {
        my $remote = $1;
        if ($remote =~ m{^([^:]+):(.+)$}) {
            return use_module('App::PMark::File::SSH')
                ->new(remote => $1, path => $2);
        }
        else {
            fail "Invalid SSH remote specification '$remote'";
        }
    }
    elsif ($spec =~ m{^http://}) {
        return use_module('App::PMark::File::HTTP')
            ->new(uri => $spec);
    }
    else {
        return use_module('App::PMark::File::Local')
            ->new(path => $spec);
    }
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
