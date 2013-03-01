###############################################################################
#
# SelfIP.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Networking::SelfIP - iControl Networking SelfIP modules 

=head1 SYNOPSIS

        my $iControl = iControl::Networking::SelfIP->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password');

	$iControl->set_self_ipv2($self_ips, $vlan_names, $addresses, $netmasks, $floating)

=head1 DESCRIPTION

iControl::Networking::SelfIP is a module to manage BIG-IP self ip configuration
including list/create/delete/modify selfips on BIG-IP 


=head1 METHODS

=over 4

=back

=cut

package iControl::Networking::SelfIP;

use strict;
use warnings;
use iControl;

use Exporter();
our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

# using RCS tag for version
$VERSION = sprintf "%d", q$Revision: #1 $ =~ /(\d+)/g;

@ISA         = qw(iControl);
@EXPORT      = ();
%EXPORT_TAGS = ();             # eg: TAG => [ qw!name1 name2! ],

# exported package globals and
# optionally exported functions
@EXPORT_OK = qw();

my $STATE_DISABLED = "STATE_DISABLED";
my $STATE_ENABLED  = "STATE_ENABLED";

sub get_self_ips {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIP')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->get_list();
    $self->check_error( fault_obj => $all_som );

    my @selfips = @{ $all_som->result };
    return @selfips;
}

=head2 set_self_ipv2

create selfip on BIG-IP.

=over 4

=item set_self_ipv2($self_ips, $vlan_names, $addresses, $netmasks, $floating)

set_self_ipv2 to create self ip for TMOS 11.x

=back

=over 4

=item $self_ips: The self IP name to create

=item $vlan_names: The VLANs that the new self IPs will be on

=item $addresses: The IP addresses for the new self IPs 

=item $netmasks: The netmasks for the self IPs

=item $floating: set to 1 create floating self ip with default traffic group traffic-group-1,
                 set to 0 to create non-floating self ip with default traffic group traffic-group-local-only 


=back

=cut

sub set_self_ipv2 {

    my ( $self, $self_ips, $vlan_names, $addresses, $netmasks, $floating ) = @_;
    my $tg    = $floating == 1 ? 'traffic-group-1' : 'traffic-group-local-only';
    my $state = $floating == 1 ? $STATE_ENABLED    : $STATE_DISABLED;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create(
        SOAP::Data->name( self_ips        => ["$self_ips"] ),
        SOAP::Data->name( vlan_names      => ["$vlan_names"] ),
        SOAP::Data->name( addresses       => ["$addresses"] ),
        SOAP::Data->name( netmasks        => ["$netmasks"] ),
        SOAP::Data->name( traffic_groups  => ["$tg"] ),
        SOAP::Data->name( floating_states => ["$state"] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 set_self_ip

create selfip on BIG-IP.

=over 4

=item set_self_ip($self_ips, $vlan_names, $netmasks, $unitid, $floating)

set_self_ip to create self ip for TMOS v9.x/10.x/11.x

=back

=over 4

=item $self_ips: The self IPs to create<br>

=item $vlan_names: The VLANs that the new self IPs will be on

=item $netmasks: The netmasks for the self IPs

=item $unitid:  should be 0 for non-floating self ip, 1 or 2 for floating self ip

=item $floating: set to 1 create floating self ip, set to 0 to create non-floating self ip


=back

=cut

sub set_self_ip {

    my ( $self, $self_ips, $vlan_names, $netmasks, $unitid, $floating ) = @_;
    my $float = $floating == 1 ? $STATE_ENABLED : $STATE_DISABLED;
    my $uid   = $floating == 1 ? "$unitid"      : '0';
    print "$float\n";
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIP')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create(
        SOAP::Data->name( self_ips        => ["$self_ips"] ),
        SOAP::Data->name( vlan_names      => ["$vlan_names"] ),
        SOAP::Data->name( netmasks        => ["$netmasks"] ),
        SOAP::Data->name( unit_ids        => ["$uid"] ),
        SOAP::Data->name( floating_states => ["$float"] ),
    );
    $self->check_error( fault_obj => $all_som );

}

1;
