###############################################################################
#
# SoftwareManagement.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::System::SoftwareManagement - iControl Networking SoftwareManagement modules

=head1 SYNOPSIS

my $keycert = iControl::System::SoftwareManagement->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   product => 'BIGIP',
                                   create_volume => 'false',
                                   reboot => 'false',
                                   retry => 'false',
);

=over 4

=item - product:			default to BIGIP

=item - create_volume:			default not to create volume (boolean false)

=item - reboot:			default not reboot (boolean false)

=item - retry:			default not retry (boolean false)

=back

=cut

=head1 DESCRIPTION

iControl::System::SoftwareManagement is a class to manage BIG-IP Software


=head1 METHODS

=over 4

=back

=cut


package iControl::System::SoftwareManagement;

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

my $DEFAULT_PRODUCT = 'BIGIP';
my $DEFAULT_CREATE_VOLUME = 'false';
my $DEFAULT_REBOOT = 'false';
my $DEFAULT_RETRY = 'false';

sub new {
        my ($class, %arguments) = @_;
        $class = ref($class) || $class;
        my $self = $class->SUPER::new(%arguments);

        $self->{product} = $arguments{product} || "$DEFAULT_PRODUCT";
        $self->{create_volume} = $arguments{create_volume} || "$DEFAULT_CREATE_VOLUME";
        $self->{reboot} = $arguments{reboot} || "$DEFAULT_REBOOT";
        $self->{retry} = $arguments{retry} || "$DEFAULT_RETRY";

        bless ( $self, $class);
        $self;
}


=head2 install_software_image 

This method has been deprecated as it does not allow the creation of volumes. Please use install_software_image_v2 in its stead. Initiates an install of SW images on all blades installed on one chassis

install_software_image($install_volume, $product, $version, $build)

=over 4

=item - $install_volume: installation slot (HD slot) to install to. This will be the same on all blades. 

=item - $version: The version of product (ex: 9.6.0) 

=item - $build: the build number you are installing 

=back

=cut


sub install_software_image {
    my ( $self, $install_volume, $version, $build ) = @_;
    my $product = $self->{product};
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/SoftwareManagement')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->install_software_image(
        SOAP::Data->name( install_volume    =>  $install_volume  ),
        SOAP::Data->name( product      =>  $product  ),
        SOAP::Data->name( version      =>  $version  ),
        SOAP::Data->name( build  =>  $build  ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 install_software_image_v2 

Initiates an install of a software image on all blades installed on one chassis - BIG-IP_v11.2.0

install_software_image_v2($install_volume, $product, $version, $build)

=over 4

=item - $install_volume: Installation slot (HD slot) to create. This will be the same on all blades 

=item - $version: The version of product (ex: 11.2.0) 

=item - $build: The build number you are installing (ex: 1943.0) 

=back

=cut

sub install_software_image_v2 {
    my ( $self, $install_volume, $version, $build ) = @_;
    my $product = $self->{product};
    my $create_volume = $self->{create_volume};
    my $reboot = $self->{reboot};
    my $retry = $self->{retry};
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/SoftwareManagement')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->install_software_image_v2(
        SOAP::Data->name( install_volume    =>  $install_volume  ),
        SOAP::Data->name( product      =>  $product  ),
        SOAP::Data->name( version      =>  $version  ),
        SOAP::Data->name( build  =>  $build  ),
        SOAP::Data->name( create_volume  =>  $create_volume  ),
        SOAP::Data->name( reboot  =>  $reboot  ),
        SOAP::Data->name( retry  =>  $retry  ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 set_boot_location 

Sets the default boot location, which will be the boot location that boots after the next system reboot. 
This version will not work on a clustered system - BIG-IP_v9.2.0

set_boot_location($location)

=over 4

=item - $location: The boot location name. Short-form names such as CF1.1, HD1.1, HD1.2, MD1.1 

=back

=cut

sub set_boot_location {
    my ( $self, $location ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/SoftwareManagement')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->set_boot_location(
        SOAP::Data->name( location  =>  $location  ),
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 set_cluster_boot_location 

Sets the cluster wide boot location, which will be the boot location after the next system reboot. 
Starting with BIG-IP version 9.6.0, clustered systems will reboot immediately

set_cluster_boot_location($location)

=over 4

=item - $location: The boot location name. Short-form names such as CF1.1, HD1.1, HD1.2, MD1.1 

=back

=cut

sub set_cluster_boot_location {
    my ( $self, $location ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/SoftwareManagement')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->set_cluster_boot_location(
        SOAP::Data->name( location  =>  $location  ),
    );
    $self->check_error( fault_obj => $all_som );

}


1;
