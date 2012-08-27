use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;
use File::Temp;

my $main = TestProfile->new;
my $temp = File::Temp->new;

$main->run('recommend', qw( ModA ModB ModC ));
$main->run('export', $temp->filename);

ok -s $temp->filename, 'export target file has non-zero size';

$main->run('subscribe', 'foo', $temp->filename);

like scalar($main->run('search')), qr{ModA\s+\+2}, 'profile is valid';

done_testing;
