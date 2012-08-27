use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME          => 'App-PMark',
  VERSION_FROM  => 'lib/App/PMark.pm',
  EXE_FILES     => ['bin/pmark'],
  PREREQ_PM     => {
    'aliased'               => '0.30',
    'Digest::SHA::PurePerl' => '5.71',
    'File::HomeDir'         => '0.99',
    'HTTP::Tiny'            => '0.017',
    'JSON::PP'              => '2.27200',
    'List::MoreUtils'       => '0.33',
    'Log::Contextual'       => '0.004202',
    'Log::Dispatch'         => '2.32',
    'Module::Metadata'      => '1.000009',
    'Module::Runtime'       => '0.013',
    'Moo'                   => '1.000003',
    'Net::FTP'              => '2.77',
    'Object::Remote'        => '0.002003',
    'strictures'            => '1',
    'Term::ReadKey'         => '2.30',
    'Try::Tiny'             => '0.11',
  },
);
