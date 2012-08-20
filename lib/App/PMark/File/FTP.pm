package App::PMark::File::FTP;
use Moo;
use Net::FTP;
use App::PMark::Util qw( fail );
use File::Temp;
use Term::ReadKey;
use overload fallback => 1,
    bool  => sub { 1 },
    q("") => sub {
        return 'ftp://' . join('/',
            join('@',
                $_[0]->username || (),
                $_[0]->hostname,
            ),
            $_[0]->path,
        );
    };

use aliased 'App::PMark::File::Local';

has username    => (is => 'ro');
has hostname    => (is => 'ro', required => 1);
has path        => (is => 'ro', required => 1);
has connected   => (is => 'ro', lazy => 1, builder => 1);

sub _build_connected {
    my ($self) = @_;
    my $host = $self->hostname;
    my $ftp  = Net::FTP->new($host)
        or fail sprintf q!cannot connect to '%s': %s!, $host, $@;
    my @auth;
    if (defined( my $username = $self->username )) {
        my $password = $self->_get_password($username);
        @auth = ($username, $password);
    }
    $ftp->login(@auth)
        or fail sprintf q!unable to login on '%s': %s!,
            $host, $ftp->message;
    return $ftp;
}

sub _get_password {
    my ($self, $username) = @_;
    printf "password for '%s' on '%s': ", $username, $self->hostname;
    ReadMode('noecho');
    my $password = ReadLine(0);
    ReadMode('restore');
    chomp $password;
    return $password;
}

sub _ensure_cwd {
    my ($self, $path) = @_;
    my $ftp   = $self->connected;
    my @parts = split m{/}, $path;
    my $file  = pop @parts;
    $ftp->cwd(join '/', @parts);
    return $file;
}

sub get {
    my ($self) = @_;
    my $temp = File::Temp->new;
    my $file = $self->_ensure_cwd($self->path);
    $self->connected->get($file, $temp->filename)
        or fail sprintf q!unable to read content via FTP: %s!,
            $self->connected->message;
    return Local->new(path => $temp->filename)->get;
}

sub put {
    my ($self, $content) = @_;
    my $temp = File::Temp->new;
    my $file = $self->_ensure_cwd($self->path);
    Local->new(path => $temp->filename)->put($content);
    $self->connected->put($temp->filename, $file)
        or fail sprintf q!unable to write content via FTP: %s!,
            $self->connected->message;
    return 1;
}

sub sibling {
    my ($self, @path) = @_;
    my @parts = split m{/}, $self->path;
    pop @parts;
    return ref($self)->new(
        username    => $self->username,
        hostname    => $self->hostname,
        path        => join('/', @parts, @path),
        connected   => $self->connected,
    );
}

with 'App::PMark::File';

1;
