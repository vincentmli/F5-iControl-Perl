###############################################################################
#
# SelfIPV2.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Networking::SelfIPV2 - iControl Networking SelfIPV2 modules BIG-IP_V11.0.0 

=head1 SYNOPSIS

        my $selfip = iControl::Networking::SelfIPV2->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
				   floating_states => 'STATE_ENABLED',
				   traffic_groups => 'traffic-group-1',
				   
			);

	$selfip->create($self_ips, $vlan_names, $addresses, $netmasks)

=head1 DESCRIPTION

iControl::Networking::SelfIPV2 is a module to manage BIG-IP self ip configuration
including list/create/delete/modify selfips on BIG-IP 


=head1 METHODS

=over 4

=back

=cut


package iControl::Networking::SelfIPV2;

use strict;
use warnings;
use Carp;
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
my $TRAFFIC_GROUP_LOCAL_ONLY = "traffic-group-local-only";
my $TRAFFIC_GROUP_1 = "traffic-group-1";
my $NON_FLOATING_UNIT_ID = '0';

my $ALLOW_MODE_PROTOCOL_PORT = 'ALLOW_MODE_PROTOCOL_PORT';
my $ALLOW_MODE_DEFAULTS = 'ALLOW_MODE_DEFAULTS';
my $PROTOCOL_ANY = 'PROTOCOL_ANY';
my $ALLOW_MODE_NONE = 'ALLOW_MODE_NONE';
my $ALLOW_MODE_PROTOCOL_PORTa = 'ALLOW_MODE_PROTOCOL_PORT';


=head2 new 

constructor to bring a selfip object into life

=cut


sub new {
        my ($class, %arguments) = @_; 

	$class = ref($class) || $class;

	my $self = $class->SUPER::new(%arguments);

	$self->{floating_states} .= $arguments{floating_states} || "$STATE_DISABLED";
	$self->{traffic_groups} .= $arguments{traffic_groups} || "$TRAFFIC_GROUP_LOCAL_ONLY";


	bless ( $self, $class); 
	$self;
}


=head2 get_list 

Gets a list of all self IPs on this device

=cut

sub get_list {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->get_list();
    $self->check_error( fault_obj => $all_som );

    my @selfips = @{ $all_som->result };
    return @selfips;
}

=head2 delete_all_self_ips

Deletes all self IP addresses

=cut

sub delete_all_self_ips {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->delete_all_self_ips();
    $self->check_error( fault_obj => $all_som );
}

=head2 delete_self_ip

Deletes the specified self IP addresses

delete_self_ip($selfip)

=over 4

=item - $selfip: self ip to delete

=back

=cut

sub delete_self_ip {
    my ($self, $selfip) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->delete_self_ip(
	SOAP::Data->name( self_ips => [ "$selfip" ])
    );
    $self->check_error( fault_obj => $all_som );
}

=head2 create

Creates the specified self IP addresses with extended attributes for TMOS 11.x.

create($self_ips, $vlan_names, $addresses, $netmasks)

default to create non-floating selfip, otherwise, floating_states and 
traffic_groups attributes can be specified in constructor.

=over 4

=item - $self_ips: The self IP name to create

=item - $vlan_names: The VLANs that the new self IPs will be on

=item - $addresses: The IP addresses for the new self IPs 

=item - $netmasks: The netmasks for the self IPs

=back

=cut


sub create {

    my ( $self, $self_ips, $vlan_names, $addresses, $netmasks ) = @_;
    my $tg = $self->{traffic_groups};
    my $float = $self->{floating_states};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create(
        SOAP::Data->name( self_ips        => ["$self_ips"] ),
        SOAP::Data->name( vlan_names      => ["$vlan_names"] ),
        SOAP::Data->name( addresses       => ["$addresses"] ),
        SOAP::Data->name( netmasks        => ["$netmasks"] ),
        SOAP::Data->name( traffic_groups  => ["$tg"] ),
        SOAP::Data->name( floating_states => ["$float"] ),
    );
    $self->check_error( fault_obj => $all_som );

}
    
=head2 add_allow_access_list 

Adds the list of access methods, with optional protocols/ports, for the specified self IPs

create($self_ips)

default to allow default

=over 4

=item - $self_ips: The self IP name to add allow access 

=back

=cut

sub add_allow_access_list {

    my ( $self, $self_ips ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPV2')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->add_allow_access_list(
        SOAP::Data->name( self_ips        => ["$self_ips"] ),
        SOAP::Data->name( access_lists => [ { mode => "$ALLOW_MODE_DEFAULTS", protocol_ports => [] } ] ), #BUG 373018, always set allow-service to All
    );
    $self->check_error( fault_obj => $all_som );

}

1;
