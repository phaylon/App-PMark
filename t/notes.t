use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $main = TestProfile->new;

$main->run('note', 'Foo', '--message', 'MainNote');
my $o = $main
    ->run('note', 'Foo', '--with-version', 23, '--message', 'V23Note');
$main
    ->run('note', 'Foo', '--with-current-version', '--message', 'V12Note');
my $rx = qr{^added\s+note\s+(\S+)\s}i;
like $o, $rx, 'correct output format';
$o =~ $rx;
my $id = $1;

do {
    my $info = $main->run('info', 'Foo');
    like $info, qr{MainNote}, 'main note visible';
    like $info, qr{V23Note}, 'version specific note visible';
    like $info, qr{V12Note}, 'current version note visible';
};

$main->run('rm-notes', $id);

do {
    my $info = $main->run('info', 'Foo');
    like $info, qr{MainNote}, 'main note visible';
    unlike $info, qr{V23Note}, 'version specific note no longer visible';
    like $info, qr{V12Note}, 'current version note visible';
};

done_testing;
