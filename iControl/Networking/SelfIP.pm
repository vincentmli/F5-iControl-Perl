###############################################################################
#
# SelfIP.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

package iControl::Networking::SelfIP;

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

my $STATE_DISABLED = "STATE_DISABLED";
my $STATE_ENABLED = "STATE_ENABLED";


=pod

=head2 get_self_ips

Get a list of selfip from bigip.

=cut

sub get_self_ips {
        my ($self) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Networking/SelfIP')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->get_list();
        $self->check_error(fault_obj => $all_som);

        my @selfips = @{$all_som->result};
        return @selfips;
}

=pod

=head2 set_self_ipv2

create selfip on bigip.

=cut
sub set_self_ipv2 {

        my ($self, $self_ips, $vlan_names, $addresses, $netmasks, $floating) = @_;
	my $tg = $floating == 1 ? 'traffic-group-1' : 'traffic-group-local-only';
	my $state = $floating == 1 ? $STATE_ENABLED : $STATE_DISABLED;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Networking/SelfIPV2')
                -> proxy($self->{_proxy})
        ;
	my $all_som = $soap->create(
        	SOAP::Data->name( self_ips => [ "$self_ips" ] ),
        	SOAP::Data->name( vlan_names      => [ "$vlan_names" ] ),
        	SOAP::Data->name( addresses        => [ "$addresses" ] ),
        	SOAP::Data->name( netmasks        => [ "$netmasks" ] ),
        	SOAP::Data->name( traffic_groups        => [ "$tg" ] ),
        	SOAP::Data->name( floating_states  => [ "$state" ] ),
	);
        $self->check_error(fault_obj => $all_som);

}

=pod

=head2 set_self_ip

create selfip on bigip.

=cut

sub set_self_ip {

        my ($self, $self_ips, $vlan_names, $netmasks, $unitid, $floating) = @_;
	my $float = $floating == 1 ? $STATE_ENABLED : $STATE_DISABLED;
	my $uid = $floating == 1 ? "$unitid" : '0';
	print "$float\n";
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Networking/SelfIP')
                -> proxy($self->{_proxy})
        ;
	my $all_som = $soap->create(
        	SOAP::Data->name( self_ips => [ "$self_ips" ] ),
        	SOAP::Data->name( vlan_names      => [ "$vlan_names" ] ),
        	SOAP::Data->name( netmasks        => [ "$netmasks" ] ),
        	SOAP::Data->name( unit_ids        => [ "$uid" ] ),
        	SOAP::Data->name( floating_states  => [ "$float" ] ),
	);
        $self->check_error(fault_obj => $all_som);

}


1;
