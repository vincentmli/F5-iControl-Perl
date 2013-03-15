###############################################################################
#
# LicenseAdministration.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Management::LicenseAdministration - iControl Networking KeyCertificate modules

=head1 SYNOPSIS

my $lic = iControl::Management::LicenseAdministration->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
);

=over 4

=back

=cut

=head1 DESCRIPTION

iControl::Management::LicenseAdministration exposes methods that enable you to authorize the system, 
either manually or in an automated fashion. This interface allows you to generate license files, 
install previously generated licenses, and view other licensing characteristics. 
This interface does not support transactions


=head1 METHODS

=over 4

=back

=cut

package iControl::Management::LicenseAdministration;

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

=head2 get_evaluation_license_expiration 

Gets information on when the evaluation license will expire

get_evaluation_license_expiration()

Return Type

EvaluationExpiration 	The information on when the evaluation license will expire.
https://devcentral.f5.com/wiki/iControl.Management__LicenseAdministration__EvaluationExpiration.ashx

=over 4

=back

=cut

sub get_evaluation_license_expiration {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/LicenseAdministration')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->get_evaluation_license_expiration();
    $self->check_error( fault_obj => $all_som );

    return $all_som->result;
}

=head2 get_registration_keys 

Gets the list of registration keys used to license the device. This returns the base key first, 
then add-on keys. As of v10.0.0, there are new add-on keys that are time limited; with this method
you can tell they are there but not when they expire. If that matters, you should use the newer 
method get_time_limited_module_keys. All of the keys returned are active keys

get_registration_keys()

Return Type

String [] 	The list of registration keys, the first key is base key.

=over 4

=back

=cut

sub get_registration_keys {
    my ($self) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/LicenseAdministration')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->get_registration_keys();
    $self->check_error( fault_obj => $all_som );

    return @{ $all_som->result };
}

=head2 activate_license 

Activates the license for the specified registration keys

activate_license($registration_keys_ref)

=over 4

=item - $registration_keys_ref: The list of registration keys to activate, pass in as array ref 

=back

=cut

sub activate_license {
    my ( $self, $registration_keys_ref ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/LicenseAdministration')
      ->proxy( $self->{_proxy} );

    my $all_som = $soap->activate_license(
        SOAP::Data->name( registration_keys => [ @{$registration_keys_ref} ] ),
    );
    $self->check_error( fault_obj => $all_som );
}

1;
