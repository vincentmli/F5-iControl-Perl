###############################################################################
#
# Pool.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::LocalLB::Pool - iControl LocalLB Pool  modules

=head1 SYNOPSIS

my $pool = iControl::LocalLB::Pool->new(protocol => 'https',
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

The Pool interface enables you to work with attributes, and statistics for pools. You can also use this interface to create pools, 
add members to a pool, delete members from a pool, find out the load balancing mode for a pool, and set the load balancing mode for a pool. 

=head1 METHODS

=over 4

=back

=cut


package iControl::LocalLB::Pool;

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

my $DEFAULT_FLAG = 'false';

sub new {
        my ($class, %arguments) = @_;
        $class = ref($class) || $class;
        my $self = $class->SUPER::new(%arguments);

        $self->{default_flag} = $arguments{default_flag} || "$DEFAULT_FLAG";

        bless ( $self, $class);
        $self;
}

=head2 create_v2

Creates a new pool

create_v2($pool_names, $lb_methods, $members_ref)

https://devcentral.f5.com/wiki/iControl.LocalLB__Pool__create_v2.ashx

=over 4

=item - $pool_names: The names of the pools 

=item - $lb_methods: The load balancing methods to use for the pools 

=item - $members_ref: The lists of initial members of the pools,pass in array ref 

=back

=cut


sub create_v2 {
    my ( $self, $pool_names, $lb_methods, $members_ref ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create_v2(
        SOAP::Data->name( pool_names        => [ $pool_names ] ),
        SOAP::Data->name( lb_methods      => [ $lb_methods ] ),
        SOAP::Data->name( members      => [ [ @{$members_ref} ] ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 delete_pool 

Deletes the specified pools

delete($pool_names)

=over 4

=item - $pool_names: The names of the pools 

=back

=cut


sub delete_pool {
    my ( $self, $pool_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->delete_pool(
        SOAP::Data->name( pool_names        => [ $pool_names ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 delete_all_pools 

Deletes all pools

delete_all_pools()

=over 4

=back

=cut

sub delete_all_pools {
    my ( $self, $pool_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->delete_all_pools();
    $self->check_error( fault_obj => $all_som );

}

=head2 set_lb_method 

Sets the load balancing methods for the specified pools

set_lb_method($pool_names, $lb_methods)

https://devcentral.f5.com/wiki/iControl.LocalLB__Pool__set_lb_method.ashx

=over 4

=item - $pool_names: The names of the pools

=item - $lb_methods: The load balancing methods to use for the pools 

=back

=cut

sub set_lb_method {
    my ( $self, $pool_names, $lb_methods ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->set_lb_method(
        SOAP::Data->name( pool_names        => [ $pool_names ] ),
        SOAP::Data->name( lb_methods        => [ $lb_methods ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 set_minimum_up_member

Sets the minimum member counts that are required to be UP for the specified pools

set_minimum_up_member($pool_names, $values)

=over 4

=back

=cut

sub set_minimum_up_member {
    my ( $self, $pool_names, $values ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->set_minimum_up_member(
        SOAP::Data->name( pool_names        => [ $pool_names ] ),
        SOAP::Data->name( values        => [ $values ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 set_minimum_up_member_action 

Sets the actions to be taken if the minimum number of members required to be UP for the specified pools is not met

set_minimum_up_member_action($pool_names, $actions)

https://devcentral.f5.com/wiki/iControl.Common__HAAction.ashx

=over 4

=item - $pool_names: The names of the pools

=item - $actions: The actions to be taken if the minimum number of members required to be UP for the specified pools is not met 

=back

=cut

sub set_minimum_up_member_action {
    my ( $self, $pool_names, $actions ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/Pool')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->set_minimum_up_member_action(
        SOAP::Data->name( pool_names        => [ $pool_names ] ),
        SOAP::Data->name( actions        => [ $actions ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

1;
