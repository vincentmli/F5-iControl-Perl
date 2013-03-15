###############################################################################
#
# LocalLB.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::LocalLB::LocalLB - iControl LocalLB LocalLB  modules

=head1 SYNOPSIS

my $lb = iControl::LocalLB->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
);

=over 4

=back

=cut

=head1 DESCRIPTION

The LocalLB module contains the Local Load Balancing interfaces that enable you to get information on and work with the components, 
attributes, and devices associated with a local load balance

=head1 METHODS

=over 4

=back

=cut


package iControl::LocalLB;

use strict;
use warnings;
use iControl;

use Exporter();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

# using RCS tag for version
$VERSION = sprintf "%d", q$Revision: #1 $ =~ /(\d+)/g;

@ISA         = qw(iControl);
@EXPORT      = ();
%EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # exported package globals and
    # optionally exported functions
@EXPORT_OK   = qw();

my $MONITOR_RULE_TYPE_SINGLE = 'MONITOR_RULE_TYPE_SINGLE';
my $MONITOR_RULE_QUORUM = '0';

sub new {
        my ($class, %arguments) = @_;
        $class = ref($class) || $class;
        my $self = $class->SUPER::new(%arguments);

	$self->{monitorrule_type}  =  $arguments{monitorrule_type} || $MONITOR_RULE_TYPE_SINGLE;
	$self->{monitorrule_quorum}  =  $arguments{monitorrule_quorum} || $MONITOR_RULE_QUORUM;

        bless ( $self, $class);
        $self;
}

1;
