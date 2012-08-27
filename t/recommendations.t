use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $main = TestProfile->new;

$main->run('recommend', 'Foo', 'Bar');
$main->run('unrecommend', 'Bar', 'Baz');

do {
    my @modules = $main->run('search', '--raw');
    chomp @modules;
    is_deeply \@modules, [qw( Foo )], 'recommended modules';
};

do {
    my @modules = $main->run('search', '--raw', '--score' => 0);
    chomp @modules;
    is_deeply \@modules, [qw( Bar Foo )], 'all modules';
};

done_testing;
