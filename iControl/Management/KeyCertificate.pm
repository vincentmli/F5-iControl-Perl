###############################################################################
#
# KeyCertificate.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Management::KeyCertificate - iControl Networking KeyCertificate modules

=head1 SYNOPSIS

my $keycert = iControl::Management::KeyCertificate->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   mode => 'MANAGEMENT_MODE_DEFAULT',);

=over 4

=item - mode:			default to MANAGEMENT_MODE_DEFAULT when not net,

=back

=cut

=head1 DESCRIPTION

iControl::Management::KeyCertificate is a module to manage BIG-IP KeyCertificate configuration
including list/create/delete/modify KeyCertificates on BIG-IP


=head1 METHODS

=over 4

=back

=cut

package iControl::Management::KeyCertificate;

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

my $MANAGEMENT_MODE_DEFAULT   = 'MANAGEMENT_MODE_DEFAULT';
my $MANAGEMENT_MODE_WEBSERVER = 'MANAGEMENT_MODE_WEBSERVER';
my $OVERWRITE_TRUE            = 'true';

sub new {
    my ( $class, %arguments ) = @_;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(%arguments);

    $self->{mode}      = $arguments{mode}      || "$MANAGEMENT_MODE_DEFAULT";
    $self->{overwrite} = $arguments{overwrite} || "$OVERWRITE_TRUE";

    bless( $self, $class );
    $self;
}

=head2 key_import_from_pem 

Imports/installs the specified keys from the given PEM-formatted data

key_import_from_pem($key_ids, $pem_data)

=over 4

=item - $key_ids: The string identifications of the keys to import/install. 

=item - $pem_data: The PEM-formatted data associated with the specified keys, read the whole key file in scalar string 

=back

=cut

sub key_import_from_pem {
    my ( $self, $key_ids, $pem_data ) = @_;
    my $mode      = $self->{mode};
    my $overwrite = $self->{overwrite};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->key_import_from_pem(
        SOAP::Data->name( mode      => $mode ),
        SOAP::Data->name( key_ids   => [$key_ids] ),
        SOAP::Data->name( pem_data  => [$pem_data] ),
        SOAP::Data->name( overwrite => $overwrite ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 certificate_import_from_pem 

Imports/installs the specified certificates from the given PEM-formatted data

certificate_import_from_pem($cert_ids, $pem_data)

=over 4

=item - $cert_ids: The string identifications of the certificates to import/install. 

=item - $pem_data: The PEM-formatted data associated with the specified certificates, read the whole cert file in scalar string 

=back

=cut

sub certificate_import_from_pem {
    my ( $self, $cert_ids, $pem_data ) = @_;
    my $mode      = $self->{mode};
    my $overwrite = $self->{overwrite};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_import_from_pem(
        SOAP::Data->name( mode      => $mode ),
        SOAP::Data->name( cert_ids  => [$cert_ids] ),
        SOAP::Data->name( pem_data  => [$pem_data] ),
        SOAP::Data->name( overwrite => $overwrite ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 certificate_delete 

Deletes/uninstalls the specified certificates

certificate_delete($cert_ids)

=over 4

=item - $cert_ids: The string identifications of the certificates to delete/uninstall 

=back

=cut

sub certificate_delete {
    my ( $self, $cert_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_delete(
        SOAP::Data->name( mode     => $mode ),
        SOAP::Data->name( cert_ids => [$cert_ids] ),
    );
    $self->check_error( fault_obj => $all_som );
}

=head2 key_delete 

Deletes/uninstalls the specified keys

key_delete($key_ids)

=over 4

=item - $key_ids: The string identifications of the keys to delete/uninstall 

=back

=cut

sub key_delete {
    my ( $self, $key_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->key_delete(
        SOAP::Data->name( mode    => $mode ),
        SOAP::Data->name( key_ids => [$key_ids] ),
    );
    $self->check_error( fault_obj => $all_som );
}

=head2 certificate_bind 

Binds/associates the specified keys and certificates

certificate_bind($cert_ids, $key_ids)

=over 4

=item - $cert_ids: The string identifications of the certificates 

=item - $key_ids: The string identifications of the keys 

=back

=cut

sub certificate_bind {
    my ( $self, $cert_ids, $key_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_bind(
        SOAP::Data->name( mode     => $mode ),
        SOAP::Data->name( cert_ids => [$cert_ids] ),
        SOAP::Data->name( key_ids  => [$key_ids] ),
    );
    $self->check_error( fault_obj => $all_som );
}


=head2 get_key_list

Gets the list of all installed keys and their information

get_key_list()

https://devcentral.f5.com/wiki/iControl.Management__KeyCertificate__KeyInformation.ashx
KeyInformation [] 	The list of keys and their information. 

=over 4

=back

=cut

sub get_key_list {
    my ( $self, $cert_ids, $key_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->get_key_list(
	SOAP::Data->name( mode     => $mode ),
    );
    $self->check_error( fault_obj => $all_som );
    return $all_som->result;
}

1;
