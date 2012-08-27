use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $main   = TestProfile->new;
my $friend = TestProfile->new;
my $other  = TestProfile->new;

$main->run('recommend', qw( Foo Bar Baz ));
$friend->run('recommend', qw( Foo Bar ));
$other->run('recommend', qw( Foo ));

$friend->run('subscribe', 'other', $other->datafile);
$main->run('subscribe', 'friend', $friend->datafile);

do {
    my @src = $main->run('sources');
    is scalar(@src), 1, 'found a single source in main profile';
    like $src[0], qr{friend}, 'friend in sources list';
    unlike $src[0], qr{other}, 'other source not in list';
};

do {
    my @src = $friend->run('sources');
    is scalar(@src), 1, 'found a single source in friend profile';
    like $src[0], qr{other}, 'found other distant source';
};

do {
    my @new = $main->run('sources', '--discover');
    is scalar(@new), 1, 'found a single new unsubscribed source';
    like $new[0], qr{friend/other}, 'new source contains origin';
};

like scalar($main->run('search', 'Foo')),
    qr{ Foo \s+ \+ 2 \s+ }x,
    'module has an accumulated score';

$friend->run('unrecommend', 'Foo');

like scalar($main->run('search', 'Foo')),
    qr{ Foo \s+ \+ 2 \s+ }x,
    'module still has an accumulated score';

$main->run('update');

like scalar($main->run('search', 'Foo')),
    qr{ Foo \s+ \+ 1 \s+ }x,
    'module score changed after update';

$main->run('subscribe', 'other', $other->datafile);

do {
    my @new = $main->run('sources', '--discover');
    is scalar(@new), 1, 'single line output';
    like $new[0], qr{no.+sources.+available}i, 'no sources message';
};

$main->run('unsubscribe', 'friend');

done_testing;
