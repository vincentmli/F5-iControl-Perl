###############################################################################
#
# DBVariable.pm
#
# $Change: 00001 $
# $Author: Vincent Li v.li@f5.com $
# $Date: 2013/02/26 $
#
###############################################################################

=head1 NAME

iControl::Management::DBVariable - iControl Networking KeyCertificate modules

=head1 SYNOPSIS

my $db = iControl::Management::DBVariable->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'user',
                                   password => 'password',

=over 4

=back

=cut

=head1 DESCRIPTION

iControl::Management::DBVariable exposes methods that enable you to work directly with our internal database 
that contains configuration variables using name/value pairs


=head1 METHODS

=over 4

=back

=cut


package iControl::Management::DBVariable;

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


=head2 query 

Queries the values of the specified variables

query($name)

=over 4

=item - $name: The names of the database variables

=back

=cut

sub query {
        my ($self, $name) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Management/DBVariable')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->query(
                                   SOAP::Data->name(variables => [$name])
                                  );
        $self->check_error(fault_obj => $all_som);

        return $all_som->result->[0]->{value};
}

=head2 modify 

Modifies the specified variables in the database

modify($name)

=over 4

=item - $name: The names of the database variables

=back

=cut

sub modify {
        my ($self, $name, $value) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Management/DBVariable')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->modify(
                                   SOAP::Data->name(variables => [ { name => $name, value => $value } ]),
                                  );
        $self->check_error(fault_obj => $all_som);

}

=head2 get_list 

Retrieves the values of all variables defined in the database. This list can potentially be huge

Return type: VariableNameValue [] 	The list of variable names/values.

get_list()

=over 4

=back

=cut

sub get_list {
        my ($self) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Management/DBVariable')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->get_list();
        $self->check_error(fault_obj => $all_som);
	my @result = @{$all_som->result};
	return @result;

}

=head2 reset 

Resets the specified variables to their default values

reset($name)

=over 4

=item - $name: Names of the database variables to modify 

=back

=cut

sub reset {
        my ($self, $name) = @_;
        my $soap = SOAP::Lite
                -> uri('urn:iControl:Management/DBVariable')
                -> proxy($self->{_proxy})
        ;

        my $all_som = $soap->reset(
                                   SOAP::Data->name(variables => [$name]),
                                  );
        $self->check_error(fault_obj => $all_som);

}


1;
