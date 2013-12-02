###############################################################################
#
# NodeAddressV2.pm
#
# $Author: Greg Petras
# $Date: 2013/10/15 $
#
###############################################################################

=head1 NAME

iControl::LocalLB::NodeAddressV2 - iControl LocalLB NodeAddressV2 modules

=head1 SYNOPSIS

my $node = iControl::LocalLB::NodeAddressV2->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   default_flag => 'false,
);

=over 4

=item - default_flag:	default to false when not net,set the attribute value using passed-in value on profile creation

=back

=cut

=head1 DESCRIPTION

The NodeAddressV2 interface enables you to work with attributes of nodes. You can use this interface to create nodes, 
and set various parameters. Its functionality will be enhanced as needed.

=head1 METHODS

=over 4

=back

=cut

package iControl::LocalLB::NodeAddressV2;

use strict;
use warnings;
use iControl;
use iControl::LocalLB;

use Exporter();
our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

# using RCS tag for version
$VERSION = sprintf "%d", q$Revision: #1 $ =~ /(\d+)/g;

@ISA         = qw(iControl::LocalLB);
@EXPORT      = ();
%EXPORT_TAGS = ();                      # eg: TAG => [ qw!name1 name2! ],

# exported package globals and
# optionally exported functions
@EXPORT_OK = qw();

my $DEFAULT_FLAG = 'false';

sub new {
    my ( $class, %arguments ) = @_;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(%arguments);

    bless( $self, $class );
    $self;
}

=head2 add_metadata

Adds the metadata for the specified nodes. For definition of the metadata,
refer to the get_metadata method description.

add_metadata($nodes, $names, $values)

https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__add_metadata.ashx

=over 4

=item - $nodes: Names of the nodes with which the metadata are to be associated.

=item - $names: Names of the metadata associated with the node.

=item - $values: Values of the metadata associated with the node.

=back

=cut

sub add_metadata_v2 {
    my ( $self, $nodes, $names, $values ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/NodeAddressV2')->proxy( $self->{_proxy} );
    my $all_som = $soap->add_metadata_v2(
        SOAP::Data->name( nodes   => [$nodes] ),
        SOAP::Data->name( names   => [ [ @{$names} ] ] ),
        SOAP::Data->name( values  => [ [ @{$values} ] ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 create

Creates the specified node addresses.

create($nodes, $addresses, $limits)

https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__create.ashx

=over 4

=item - $nodes: Names of the node addresses to create.

=item - $addresses: Addresses of the nodes to create.

=item - $limits: The connection limits.

=back

=cut

sub create {
    my ( $self, $nodes, $addresses, $limits ) = @_;
    if (! defined $limits) {
        $limits = [ 0 ];
    }
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/NodeAddressV2')->proxy( $self->{_proxy} );
    my $all_som = $soap->create(
        SOAP::Data->name( nodes     => $nodes ),
        SOAP::Data->name( addresses => $addresses ),
        SOAP::Data->name( limits    => $limits ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 get_address

Gets the IP addresses for a set of node addresses.

get_address($nodes)

https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_address.ashx

=cut

sub get_address {
    my ( $self, $nodes ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/NodeAddressV2')->proxy( $self->{_proxy} );
    my $all_som = $soap->get_address(
        SOAP::Data->name( nodes => $nodes ),
    );
    $self->check_error( fault_obj => $all_som );

    my @addresses = @{ $all_som->result };
    return @addresses;

}

=head2 get_list

Gets a list of all node addresses.

get_list()

https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_list.ashx

=cut

sub get_list {
    my ( $self ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/NodeAddressV2')->proxy( $self->{_proxy} );
    my $all_som = $soap->get_list();
    $self->check_error( fault_obj => $all_som );

    my @list = sort(@{ $all_som->result });
    return @list;

}

=head2 get_metadata

Gets metadata for the defined nodes.

get_metadata($nodes)

https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_metadata.ashx

=cut

sub get_metadata {
    my ( $self, $nodes ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/NodeAddressV2')->proxy( $self->{_proxy} );
    my $all_som = $soap->get_metadata(
        SOAP::Data->name( nodes => $nodes ),
    );
    $self->check_error( fault_obj => $all_som );

    my @metadata = sort(@{ $all_som->result });
    return @metadata;

}

1;
