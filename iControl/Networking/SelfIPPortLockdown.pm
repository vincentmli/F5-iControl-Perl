###############################################################################
#
# SelfIPPortLockdown.pm
#
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Networking::SelfIPPortLockdown - iControl Networking SelfIPPortLockdown modules BIG-IP 9.x-10.x 

=head1 SYNOPSIS

        my $selfip = iControl::Networking::SelfIPPortLockdown->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',
			);


=head1 DESCRIPTION

iControl::Networking::SelfIPPortLockdown enables you to lock down protocols and ports on self IP addresses 


=head1 METHODS

=over 4

=back

=cut

package iControl::Networking::SelfIPPortLockdown;

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

my $ALLOW_MODE_PROTOCOL_PORT  = 'ALLOW_MODE_PROTOCOL_PORT';
my $ALLOW_MODE_DEFAULTS       = 'ALLOW_MODE_DEFAULTS';
my $PROTOCOL_ANY              = 'PROTOCOL_ANY';
my $ALLOW_MODE_NONE           = 'ALLOW_MODE_NONE';
my $ALLOW_MODE_PROTOCOL_PORTa = 'ALLOW_MODE_PROTOCOL_PORT';

=head2 new 

constructor to bring a selfip object into life

=cut

sub new {
    my ( $class, %arguments ) = @_;

    $class = ref($class) || $class;

    my $self = $class->SUPER::new(%arguments);

    bless( $self, $class );
    $self;
}

sub add_allow_access_list {

    my ( $self, $self_ips ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:Networking/SelfIPPortLockdown')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->add_allow_access_list(
        SOAP::Data->name(
            access_lists => [
                {
                    self_ip        => "$self_ips",
                    mode           => 'ALLOW_MODE_DEFAULTS',
                    protocol_ports => []
                }
            ]
        ),
    );
    $self->check_error( fault_obj => $all_som );

}

1;
