use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $main = TestProfile->new;

$main->run('recommend', qw( ModA ModB ModC ));

do {
    my @mod = $main->run('search', '--raw', '--score' => 0);
    chomp @mod;
    is_deeply \@mod, [qw( ModA ModB ModC )], 'all modules recommended';
};

$main->run('forget', 'ModB');

do {
    my @mod = $main->run('search', '--raw', '--score' => 0);
    chomp @mod;
    is_deeply \@mod, [qw( ModA ModC )], 'one module forgotten';
};

done_testing;
