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

        my $selfip = iControl::Networking::SelfIP->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   floating_states => 'STATE_ENABLED',
				   
			);

	$selfip->create($self_ips, $vlan_names, $addresses, $netmasks)

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
use Carp;
use iControl;
use iControl::Management::DBVariable;

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
my $NON_FLOATING_UNIT_ID = '0';

=head2 new 

constructor to bring a selfip object into life

=cut


sub new {
        my ($class, %arguments) = @_; 

	$class = ref($class) || $class;

	my $self = $class->SUPER::new(%arguments);

	$self->{floating_states} .= $arguments{floating_states} || "$STATE_DISABLED";
	my $db = iControl::Management::DBVariable->new(%arguments); 
	$self->{unit_id} .= $db->query('Failover.UnitId') || "$NON_FLOATING_UNIT_ID";

	bless ( $self, $class); 
	$self;
}


=head2 get_floating_states

object floating_states attibute accessor to get selfips floating states 

=cut

sub get_floating_states {
    my ( $self, $floating_states ) = @_;
    if ( $floating_states eq 'floating_states' ){
         my $fs = $self->{$floating_states};
         return $fs;
    } else {
         carp(
            " $floating_states is not valid attribute.\n".
            " "
        );
    }
}

=head2 set_floating_states

object floating_states attibute accessor to set selfips floating states 

=cut

sub set_floating_states {
    my ( $self, $floating_states, $state ) = @_;
    if ( $floating_states eq 'floating_states' and 
         ( $state eq $STATE_DISABLED or $state eq $STATE_ENABLED )
       ) {  
            $self->{$floating_states} = $state || "$STATE_DISABLED";
    }else {
                 carp(
            " either $floating_states is not valid attribute or $state is not valid $STATE_DISABLED or $STATE_ENABLED\n".
            " "
        );

    }
}



=head2 get_list

get list of selfips from BIG-IP

=cut

sub get_list {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIP')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->get_list();
    $self->check_error( fault_obj => $all_som );

    my @selfips = @{ $all_som->result };
    return @selfips;
}

=head2 delete_all_self_ips

deletes all self IP addresses

=cut

sub delete_all_self_ips {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIP')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->delete_all_self_ips();
    $self->check_error( fault_obj => $all_som );
}

=head2 delete_self_ip

deletes the specified self IP addresses 

delete_self_ip($selfip)

=over 4

=item - $selfip: self ip to delete

=back

=cut

sub delete_self_ip {
    my ($self, $selfip) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIP')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->delete_self_ip(
	SOAP::Data->name( self_ips => [ "$selfip" ])
    );
    $self->check_error( fault_obj => $all_som );
}

=head2 create

create selfip on BIG-IP for TMOS v9.x/10.x/11.x

create($self_ips, $vlan_names, $netmasks, $unitid)

=over 4

=item - $self_ips: The self IPs to create

=item - $vlan_names: The VLANs that the new self IPs will be on

=item - $netmasks: The netmasks for the self IPs

=back

=cut


sub create {

    my ( $self, $self_ips, $vlan_names, $netmasks ) = @_;
    my $float = $self->{floating_states};
    my $uid   = $float eq $STATE_ENABLED ? "$self->{unit_id}"  : $NON_FLOATING_UNIT_ID;
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
