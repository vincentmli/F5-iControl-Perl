###############################################################################
#
# VLAN.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Networking::VLAN - iControl Networking VLAN modules

=head1 SYNOPSIS

        my $iControl = iControl::Networking::VLAN->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password');


=head1 DESCRIPTION

iControl::Networking::VLAN is a module to manage BIG-IP self ip configuration
including create/delete/modify selfips on BIG-IP


=head1 METHODS

=over 4

=back

=cut


package iControl::Networking::VLAN;

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

=head2 get_vlans 

get list of  vlans on BIG-IP.

=over 4

=item ($self_ips, $vlan_names, $netmasks, $unitid, $floating)

set_self_ip to create self ip for TMOS v9.x/10.x/11.x, unit_ids should be 0
for non-floating self ip, 1 or 2 for floating self ip, if $floating set to 1
create floating self ip, if $floating set to 0, create non-floating self ip

=over 4

=back

=cut


sub get_vlans {
        my ($self) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Networking/VLAN')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->get_list();
        $self->check_error(fault_obj => $all_som);

        my @vlans = @{$all_som->result};
        return @vlans;
}

1;
