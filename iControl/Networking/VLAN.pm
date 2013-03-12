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

my $vlan = iControl::Networking::VLAN->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   member_type => 'MEMBER_TRUNK',
                                   tag_state => 'MEMBER_UNTAGGED',
                                   failsafe_states => 'STATE_ENABLED',
                                   timeouts => '120'
                                   mac_masquerade_addresses => 'xx:xx:xx:xx:xx:xx',);

=over 4

=item - member_type:			default to MEMBER_INTERFACE when not net,

=item - tag_state:			default to MEMBER_TAGGED when not set,

=item - failsafe_states:		default to STATE_DISABLED when not set,

=item - timeouts:			default to 90 seconds when not set,

=item - mac_masquerade_addresses:	default auto assigned,

=back

=cut

=head1 DESCRIPTION

iControl::Networking::VLAN is a module to manage BIG-IP VLAN configuration
including list/create/delete/modify VLANs on BIG-IP


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

my $STATE_DISABLED = 'STATE_DISABLED';
my $STATE_ENABLED = 'STATE_ENABLED';
my $MEMBER_INTERFACE = 'MEMBER_INTERFACE';
my $MEMBER_TRUNK = 'MEMBER_TRUNK';
my $MEMBER_TAGGED = 'MEMBER_TAGGED';
my $MEMBER_UNTAGGED = 'MEMBER_UNTAGGED';
my $DEFAULT_FAILSAFE_TIMEOUT = '90';
my $DEFAULT_MAC_MASQUERADE_ADDRESSES = '0';

sub new {
        my ($class, %arguments) = @_;

        $class = ref($class) || $class;

        my $self = $class->SUPER::new(%arguments);

        $self->{vlan_ids} = $arguments{vlan_ids};
        $self->{failsafe_states} = $arguments{failsafe_states} || "$STATE_DISABLED";
        $self->{timeouts} = $arguments{timeouts} || $DEFAULT_FAILSAFE_TIMEOUT;
        $self->{mac_masquerade_addresses} = $arguments{mac_masquerade_addresses} || $DEFAULT_MAC_MASQUERADE_ADDRESSES;
        $self->{member_type} = $arguments{member_type} || "$MEMBER_INTERFACE";
        $self->{tag_state} = $arguments{tag_state} || "$MEMBER_TAGGED";

        bless ( $self, $class);
        $self;
}

=head2 get_list

Gets a list of all VLANs on this device

get_list

=cut


sub get_list {
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

=head2 get_failsafe_timeout 

Gets the failsafe timeouts for the specified VLANs

get_failsafe_timeout($vlans);

=over 4

=item - $vlans: vlan to get failsafe timeout 

=back

=cut


sub get_failsafe_timeout {

    my ( $self, $vlans) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/VLAN')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->get_failsafe_timeout(
        SOAP::Data->name( vlans        => ["$vlans"] ),
    );
    $self->check_error( fault_obj => $all_som );
    my @timeouts = @{$all_som->result}; 
    return @timeouts
}

=head2 create 

Creates the specified VLANs with extended attributes

create($vlans, $vlan_ids, $member_name);

=over 4

=item - $vlans: The VLAN names 

=item - $vlan_ids: The VLAN tag numbers or IDs (valid range is 1-4095). 

=item - $member_name: the interface/trunk name, if add more than one interfaces/trunks
        use this method to create the vlan with one interface,then use add_member method
        to add more interfaces, this eliminate the the array of hash handliing complication  

=back

=cut


sub create {

    my ( $self, $vlans, $vlan_ids, $member_name) = @_;
    my $fs = $self->{failsafe_states};
    my $timeouts = $self->{timeouts};
    my $mma = $self->{mac_masquerade_addresses};
    my $mt = $self->{member_type};
    my $ts = $self->{tag_state};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/VLAN')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create(
        SOAP::Data->name( vlans        => ["$vlans"] ),
        SOAP::Data->name( vlan_ids      => ["$vlan_ids"] ),
        SOAP::Data->name( members       => [ [ { member_name => "$member_name", member_type => "$mt", tag_state => "$ts" } ] ] ),
        SOAP::Data->name( failsafe_states        => ["$fs"] ),
        SOAP::Data->name( timeouts  => [ $timeouts ] ),
        SOAP::Data->name( mac_masquerade_addresses => [ $mma ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 delete_vlan 

Deletes the specified VLANs

delete($vlans);

=over 4

=item - $vlans: vlan to delete 

=back

=cut

sub delete_vlan {

    my ( $self, $vlans) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/VLAN')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->delete_vlan(
        SOAP::Data->name( vlans        => ["$vlans"] ),
    );
    $self->check_error( fault_obj => $all_som );
}

1;
