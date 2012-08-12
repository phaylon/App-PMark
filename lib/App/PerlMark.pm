package App::PerlMark;
use Moo;
use Module::Runtime qw( use_module );

our $VERSION = '0.001';
$VERSION = eval $VERSION;

my %_command = (
    'recommend' => 'Recommend',
    '++'        => 'Recommend',
    'tag'       => 'Tag',
    'search'    => 'Search',
    'tags'      => 'Tags',
    'info'      => 'Info',
    'note'      => 'Note',
    'rmnotes'   => 'RemoveNotes',
    'export'    => 'Export',
    'subscribe' => 'Subscribe',
    'update'    => 'Update',
);

my @_command_help = (map "  $_\n",
    q!recommend (or ++):    Add module recommendations!,
    q!tag:                  Add tags to modules and versions!,
    q!search:               Search known modules!,
    q!tags:                 Search known tags!,
    q!info:                 Query full module information!,
    q!note:                 Add notes to modules and versions!,
    q!rmnotes:              Remove notes!,
    q!export:               Export profile data!,
    q!subscribe:            Subscribe to profiles of others!,
    q!update:               Update all subscriptions!,
);

sub run {
    my ($self) = @_;
    my $command = shift @ARGV;
    die "$0: Missing command parameter\n"
        unless defined $command;
    die "$0: Unknown command '$command'. Valid commands are:\n"
        . join '', @_command_help
        unless exists $_command{$command};
    my $class = sprintf 'App::PerlMark::Command::%s', $_command{$command};
    return use_module($class)->run_with_options($command);
}

1;

__END__

=head1 NAME

App::PerlMark - Description goes here

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

 Robert Sedlacek <rs@474.at>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2012 the App::PerlMark L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
