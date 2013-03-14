###############################################################################
#
# ProfileClientSSL.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::LocalLB::ProfileClientSSL - iControl Networking ProfileClientSSL modules

=head1 SYNOPSIS

my $keycert = iControl::LocalLB::ProfileClientSSL->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   default_flag => 'false',);

=over 4

=item - default_flag:	default to false when not net,set the attribute value using passed-in value on profile creation

=back

=cut

=head1 DESCRIPTION

The ProfileClientSSL interface enables you to manipulate a local load balancer's client SSL profile

=head1 METHODS

=over 4

=back

=cut

package iControl::LocalLB::ProfileClientSSL;

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

my $DEFAULT_FLAG = 'false';

sub new {
    my ( $class, %arguments ) = @_;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(%arguments);

    $self->{default_flag} = $arguments{default_flag} || "$DEFAULT_FLAG";

    bless( $self, $class );
    $self;
}

=head2 create_v2

Creates the specified client SSL profiles, using key and certificate file object names. 
Certificate and key file objects are managed by the Management::KeyCertificate interface. 

create($profile_names, $keys, $certs)

=over 4

=item - $profile_names: The client SSL profiles to create 

=item - $keys: The certificate key file object names to be used by BIG-IP acting as an SSL server. 

=item - $certs: The certificate file object names to be used by BIG-IP acting as an SSL server 

=back

=cut

sub create_v2 {
    my ( $self, $profile_names, $keys, $certs ) = @_;
    my $default_flag = $self->{default_flag};
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create_v2(
        SOAP::Data->name( profile_names => [$profile_names] ),
        SOAP::Data->name(
            keys => [ { value => "$keys.key", default_flag => $default_flag } ]
        ),
        SOAP::Data->name(
            certs =>
              [ { value => "$certs.crt", default_flag => $default_flag } ]
        ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 delete_profile 

Deletes the specified client SSL profiles

delete_profile($profile_names)

=over 4

=item - $profile_names: The names of the client SSL profiles to delete 

=back

=cut

sub delete_profile {
    my ( $self, $profile_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->delete_profile(
        SOAP::Data->name( profile_names => [$profile_names] ),
    );
    $self->check_error( fault_obj => $all_som );
}

=head2 get_key_file_v2 

Gets the names of the certificate key file objects used by BIG-IP acting as an SSL server for a set of client SSL profiles

get_key_file_v2($profile_names)

=over 4

=item - $profile_names: The names of the client SSL profiles 

=back

=cut

sub get_key_file_v2 {
    my ( $self, $profile_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->get_key_file_v2(
        SOAP::Data->name( profile_names => [$profile_names] ),
    );
    $self->check_error( fault_obj => $all_som );
    my @keys = @{ $all_som->result };
    return @keys;
}

1;
