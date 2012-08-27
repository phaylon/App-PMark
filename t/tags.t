use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $main = TestProfile->new;

subtest 'adding some tags' => sub {
    $main->run('tag', 'Foo', qw( bar baz ));
    $main->run('tag', 'Foo', qw( baz qux ));
    $main->run('tag', 'Bar', qw( baz ));
    my @out = $main->run('tags');
    is scalar(@out), 3, 'have three tags';
    like $out[0], qr{bar\s+x1}, 'first tag';
    like $out[1], qr{baz\s+x2}, 'second tag';
    like $out[2], qr{qux\s+x1}, 'third tag';
};

subtest 'removing some tags' => sub {
    $main->run('untag', 'Foo', qw( baz qux ));
    my @out = $main->run('tags');
    is scalar(@out), 2, 'have two tags';
    like $out[0], qr{bar\s+x1}, 'first tag';
    like $out[1], qr{baz\s+x1}, 'second tag';
};

subtest 'quick search' => sub {
    my @out = $main->run('search', '--score' => 0);
    is scalar(@out), 2, 'found two modules';
    like $out[0], qr{Bar\s+baz}, 'first module';
    like $out[1], qr{Foo\s+bar}, 'second module';
};

subtest 'adding tags to versions' => sub {
    $main->run('tag', 'Foo', '--with-version', 23, qw( tag23 ));
    $main->run('tag', 'Foo', '--with-current-version', qw( tagcurr ));
    unlike scalar($main->run('search', '--score' => 0)),
        qr{tag(?:23|curr)},
        'version tags not in list';
    my $all = $main->run('search', '--score' => 0, '--all-tags');
    like $all, qr{tag23},   'version tag in explicit list';
    like $all, qr{tagcurr}, 'current version tag in explicit list';
};

subtest 'search by tags' => sub {
    my @baz = $main->run('search', 'baz', '--score' => 0);
    is scalar(@baz), 1, 'found single module tagged baz';
    like $baz[0], qr{Bar\s+baz}, 'correct module';
    unlike scalar($main->run('search', 'tag23', '--score' => 0)),
        qr{Foo},
        'version specific tag not found';
    like scalar($main->run('search',
            'tag23', '--score' => 0, '--all-tags')),
        qr{Foo},
        'version specific tag found when explicitly searching all';
};

subtest 'tagging while recommending' => sub {
    $main->run('recommend', 'Qux', '--tag', 'rectag');
    like $main->run('tags'), qr{rectag}, 'tag available';
};

done_testing;
