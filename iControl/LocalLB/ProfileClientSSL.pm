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

iControl::LocalLB::ProfileClientSSL is a module to manage BIG-IP ProfileClientSSL configuration
including list/create/delete/modify ProfileClientSSLs on BIG-IP


=head1 METHODS

=over 4

=back

=cut


package iControl::LocalLB::ProfileClientSSL;

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

sub create_v2 {
    my ( $self, $profile_names, $keys, $certs ) = @_;
    my $default_flag = $self->{default_flag};
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->create_v2(
        SOAP::Data->name( profile_names        => [ $profile_names ] ),
        SOAP::Data->name( keys      => [ { value => $keys, default_flag => $default_flag } ] ),
        SOAP::Data->name( certs      => [ { value => $certs, default_flag => $default_flag } ] ),
    );
    $self->check_error( fault_obj => $all_som );

}

sub delete_profile {
    my ( $self, $profile_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->delete_profile(
        SOAP::Data->name( profile_names    => [ $profile_names ] ),
    );
    $self->check_error( fault_obj => $all_som );
}

sub get_key_file_v2 {
    my ( $self, $profile_names ) = @_;
    my $soap =
      SOAP::Lite->uri('urn:iControl:LocalLB/ProfileClientSSL')
      ->proxy( $self->{_proxy} );
    my $all_som = $soap->get_key_file_v2(
        SOAP::Data->name( profile_names    => [ $profile_names ] ),
    );
    $self->check_error( fault_obj => $all_som );
    my @keys = @{$all_som->result};
    return @keys;
}



1;
