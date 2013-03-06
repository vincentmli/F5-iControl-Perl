###############################################################################
#
# DBVariable.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

package iControl::Networking::DBVariable;

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


=head2 get_db_variable

Get the value of a variable from BigIP's DB.

get_db_vairable($key)

=over 4

=item - $key: Get the value of db key $key

=back

=cut

sub get_db_variable {
        my ($self, $key) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Management/DBVariable')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->query(
                                   SOAP::Data->name(variables => [$key])
                                  );
        $self->check_error(fault_obj => $all_som);

        return $all_som->result->[0]->{value};
}


1;
