use strictures 1;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestProfile;

my $source = TestProfile->new;
my $main   = TestProfile->new;

$main->runall(
    ['recommend', qw( Foo Bar ), '--tag' => 'main-tag'],
    ['note', qw( Foo Bar ), '--message' => 'MainMsg'],
    ['note', 'Foo', '--with-version' => 23, '--message' => 'MainFoo23'],
    ['tag', 'Foo', 'main-foo-23', '--with-version' => 23],
);

$source->runall(
    ['recommend', qw( Bar Baz ), '--tag' => 'src-tag'],
    ['note', qw( Bar Baz ), '--message' => 'SrcMsg'],
    ['note', 'Foo', '--with-version' => 23, '--message' => 'SrcFoo23'],
    ['tag', 'Foo', 'src-foo-23', '--with-version' => 23],
);

my $is_module = sub {
    my ($str, $module) = @_;
    like $str, qr{\A\[\Q$module\E\]}, "output for $module";
    return $str;
};

my $has_score = sub {
    my ($str, $score) = @_;
    like $str, qr{Score:\s+\+?\Q$score\E}, "score of $score";
    return $str;
};

my $contains = sub {
    my ($str, $what, @values) = @_;
    like $str, qr{\Q$_\E}, "contains $what '$_'"
        for @values;
    return $str;
};

my $contains_not = sub {
    my ($str, $what, @values) = @_;
    unlike $str, qr{\Q$_\E}, "does not contain $what '$_'"
        for @values;
    return $str;
};

subtest merge => sub {
    $main->run('import', $source->datafile);
    my @modules = $main->run('search', '--raw', '--score' => 0);
    chomp @modules;
    is_deeply \@modules, [qw( Bar Baz Foo )], 'correct set of modules';
    my @info = split m{\n\n}, scalar
        $main->run('search', '--score' => 0, '--info', '--all-tags');
    subtest Bar => sub {
        $info[0]
            ->$is_module('Bar')
            ->$has_score(1)
            ->$contains(tag => qw( main-tag src-tag ))
            ->$contains(note => qw( MainMsg SrcMsg ));
    };
    subtest Baz => sub {
        $info[1]
            ->$is_module('Baz')
            ->$has_score(1)
            ->$contains(tag => qw( src-tag ))
            ->$contains_not(tag => qw( main-tag ))
            ->$contains(note => qw( SrcMsg ))
            ->$contains_not(note => qw( MainMsg ));
    };
    subtest Foo => sub {
        $info[2]
            ->$is_module('Foo')
            ->$has_score(1)
            ->$contains(tag => qw( main-tag main-foo-23 src-foo-23 ))
            ->$contains_not(tag => qw( src-tag ))
            ->$contains(note => qw( MainMsg MainFoo23 SrcFoo23 ))
            ->$contains_not(note => qw( SrcMsg ));
    };
};

subtest override => sub {
    $main->run('import', $source->datafile, '--override');
    my @modules = $main->run('search', '--raw', '--score' => 0);
    chomp @modules;
    is_deeply \@modules, [qw( Bar Baz Foo )], 'correct set of modules';
    my @info = split m{\n\n}, scalar
        $main->run('search', '--score' => 0, '--info', '--all-tags');
    subtest Bar => sub {
        $info[0]
            ->$is_module('Bar')
            ->$has_score(1)
            ->$contains(tag => qw( src-tag ))
            ->$contains_not(tag => qw( main-tag ))
            ->$contains(note => qw( SrcMsg ))
            ->$contains_not(note => qw( MainMsg ));
    };
    subtest Baz => sub {
        $info[1]
            ->$is_module('Baz')
            ->$has_score(1)
            ->$contains(tag => qw( src-tag ))
            ->$contains_not(tag => qw( main-tag ))
            ->$contains(note => qw( SrcMsg ))
            ->$contains_not(note => qw( MainMsg ));
    };
    subtest Foo => sub {
        $info[2]
            ->$is_module('Foo')
            ->$has_score(0)
            ->$contains(tag => qw( src-foo-23 ))
            ->$contains_not(tag => qw( main-tag main-foo-23 src-tag ))
            ->$contains(note => qw( SrcFoo23 ))
            ->$contains_not(note => qw( SrcMsg MainMsg MainFoo23 ));
    };
};

done_testing;
