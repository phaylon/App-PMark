use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App-PerlMark',
  VERSION_FROM => 'lib/App/PerlMark.pm'
);
