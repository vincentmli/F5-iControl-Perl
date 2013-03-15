###############################################################################
#
# Services.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::System::Services - iControl Networking KeyCertificate modules

=head1 SYNOPSIS

my $service = iControl::System::Services->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
                                   state => 'STATE_DISABLED',
);

=over 4

=item - state: set ssh access state to STATE_DISABLED or STATE_ENABLED, default STATE_DISABLED

=back

=cut

=head1 DESCRIPTION

iControl::System::Services enables you to manage the various supported services on the device, such as SSHD, HTTPD, NTPD, 
SOD.... This interface does not support transactions 

=head1 METHODS

=over 4

=back

=cut

package iControl::System::Services;

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

my $STATE_DISABLED = 'STATE_DISABLED';
my $STATE_ENABLED  = 'STATE_ENABLED';

sub new {
    my ( $class, %arguments ) = @_;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(%arguments);

    $self->{state} = $arguments{state} || "$STATE_DISABLED";

    bless( $self, $class );
    $self;
}

=head2 set_ssh_access_v2 

Sets the ssl service state and allowed addresses. Please see note in SSHAccess_v2 regarding "no access" and "all access"

set_ssh_access_v2($addresses_ref)

=over 4

=item - $addresses_ref: The addresses and address ranges allowed to access the device via SSH, pass in by array reference 

=back

=cut

sub set_ssh_access_v2 {
    my ( $self, $addresses_ref ) = @_;
    my $state = $self->{state};
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/Services')->proxy( $self->{_proxy} );

    my $all_som = $soap->set_ssh_access_v2(
        SOAP::Data->name(
            access => { state => $state, addresses => [ @{$addresses_ref} ] }
        )
    );
    $self->check_error( fault_obj => $all_som );

}

=head2 reboot_system 

Reboots the system. This method will reboot the system within specified number of seconds. Once this method has been called, 
no further operations or requests should be sent to the Portal, and make sure all pending operations are completed before the reboot

reboot_system($seconds_to_reboot)

=over 4

=item - $seconds_to_reboot: The number of seconds before the reboot takes place 

=back

=cut

sub reboot_system {
    my ( $self, $seconds_to_reboot ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:System/Services')->proxy( $self->{_proxy} );

    my $all_som = $soap->reboot_system(
        SOAP::Data->name( seconds_to_reboot => $seconds_to_reboot ) );
    $self->check_error( fault_obj => $all_som );

}

1;
