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
                                   password => 'password',);

=over 4

=item - member_type:			default to MEMBER_INTERFACE when not net,

=item - tag_state:			default to MEMBER_TAGGED when not set,

=item - failsafe_states:		default to STATE_DISABLED when not set,

=item - timeouts:			default to 90 seconds when not set,

=item - mac_masquerade_addresses:	default auto assigned,

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
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

# using RCS tag for version
$VERSION = sprintf "%d", q$Revision: #1 $ =~ /(\d+)/g;

@ISA         = qw(iControl);
@EXPORT      = ();
%EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # exported package globals and
    # optionally exported functions
@EXPORT_OK   = qw();

my $MANAGEMENT_MODE_DEFAULT = 'MANAGEMENT_MODE_DEFAULT';
my $MANAGEMENT_MODE_WEBSERVER = 'MANAGEMENT_MODE_WEBSERVER';
my $OVERWRITE_TRUE = 'true';

sub new {
        my ($class, %arguments) = @_;
        $class = ref($class) || $class;
        my $self = $class->SUPER::new(%arguments);

        $self->{mode} = $arguments{mode} || "$MANAGEMENT_MODE_DEFAULT";
        $self->{overwrite} = $arguments{overwrite} || "$OVERWRITE_TRUE";

        bless ( $self, $class);
        $self;
}

sub key_import_from_pem {
    my ( $self, $key_ids, $pem_data ) = @_;
    my $mode = $self->{mode};
    my $overwrite = $self->{overwrite};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->key_import_from_pem(
        SOAP::Data->name( mode        =>  $mode  ),
        SOAP::Data->name( key_ids      => [ $key_ids ] ),
        SOAP::Data->name( pem_data      => [ $pem_data ] ),
        SOAP::Data->name( overwrite  =>  $overwrite  ),
    );
    $self->check_error( fault_obj => $all_som );

}

sub certificate_import_from_pem {
    my ( $self, $cert_ids, $pem_data ) = @_;
    my $mode = $self->{mode};
    my $overwrite = $self->{overwrite};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_import_from_pem(
        SOAP::Data->name( mode        =>  $mode  ),
        SOAP::Data->name( cert_ids      => [ $cert_ids ] ),
        SOAP::Data->name( pem_data      => [ $pem_data ] ),
        SOAP::Data->name( overwrite  =>  $overwrite  ),
    );
    $self->check_error( fault_obj => $all_som );

}

sub certificate_delete {
    my ( $self, $cert_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_delete(
        SOAP::Data->name( mode        =>  $mode  ),
        SOAP::Data->name( cert_ids      => [ $cert_ids ] ),
    );
    $self->check_error( fault_obj => $all_som );
}

sub key_delete {
    my ( $self, $key_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->key_delete(
        SOAP::Data->name( mode        =>  $mode  ),
        SOAP::Data->name( key_ids      => [ $key_ids ] ),
    );
    $self->check_error( fault_obj => $all_som );
}

sub certificate_bind {
    my ( $self, $cert_ids, $key_ids ) = @_;
    my $mode = $self->{mode};
    my $soap =
      SOAP::Lite->uri('urn:iControl:Management/KeyCertificate')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->certificate_bind(
        SOAP::Data->name( mode        =>  $mode  ),
        SOAP::Data->name( cert_ids      => [ $cert_ids ] ),
        SOAP::Data->name( key_ids      => [ $key_ids ] ),
    );
    $self->check_error( fault_obj => $all_som );
}


1;
