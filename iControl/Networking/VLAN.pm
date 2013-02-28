###############################################################################
#
# VLAN.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

package iControl::Networking::VLAN;

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


=pod

=head2 get_vlans

Get a list of vlans from bigip.

=cut

sub get_vlans {
        my ($self) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Networking/VLAN')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->get_list();
        $self->check_error(fault_obj => $all_som);

        my @vlans = @{$all_som->result};
        return @vlans;
}

1;
