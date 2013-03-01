package iControl;

use strict;
use warnings;
use Data::Dumper;


#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;

use constant DEFAULT_PROXY_URI => 'iControl/iControlPortal.cgi';
use constant DEFAULT_HOST => '127.0.0.1';
use constant DEFAULT_HTTP_PORT => '80';
use constant DEFAULT_HTTPS_PORT => '443';
use constant DEFAULT_PROTOCOL => 'http';
use constant ERROR_PREFIX => "iControl Error:\n";
use constant TRUE => 1;
use constant FALSE => 0;
use constant MAX_EXTENSION => 100;
my %ICONTROL_TYPECAST_TYPES = (
        '{urn:iControl}Management.UserManagement.UserRole'  => 1,
        '{urn:iControl}Common.EnabledState'                 => 1,
        '{urn:iControl}LocalLB.ProfileType' =>1,
        '{urn:iControl}LocalLB.ProfileContextType' => 1,
        '{urn:iControl}LTConfig.Class' => 1,
        '{urn:iControl}LTConfig.Field' => 1,
);

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified IO::Socket::SSL.pm to remove the SSL verification alert, got better idea ?

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

}

    use Exporter ();
    use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK);
    @ISA = qw(Exporter);
    @EXPORT = qw();
    @EXPORT_OK = qw();

$VERSION = "1.00100";

#http://www.indecorous.com/perl/pod/ simple pod howto

=pod

=head1 NAME

iControl - a Perl module for iControl functionality. It provides methods that
use iControl via SOAP::Lite to manage bigip.

=head1 SYNOPSIS

        use iControl;

	my $iControl = iControl->new(protocol => 'https',
                                   host => 'mgmt_ip',
                                   username => 'admin',
                                   password => 'admin');



=head1 DESCRIPTION

iControl provides an Object Oriented Perl interface to implement some of the interfaces
provided by iControl.

=head1 METHODS

=head2 new

The constructor is used for generating a new object,
initializing its attributes.

=cut

sub new {
        my ($class, %arguments) = @_;
        my $error_message = '';

        # Set proxy from parameters
        my $protocol = $arguments{protocol} || DEFAULT_PROTOCOL;
        my $authentication = '';
        if ($arguments{username} && $arguments{password}) {
          $authentication .= "$arguments{username}:$arguments{password}\@";
        }
        my $host .= $arguments{host} || DEFAULT_HOST;
        my $port .= $arguments{port} || ($arguments{protocol} && $arguments{protocol} eq 'https' ?
                                         DEFAULT_HTTPS_PORT : DEFAULT_HTTP_PORT);
        my $proxy_uri .= $arguments{proxy_uri} || DEFAULT_PROXY_URI;
        my $proxy = "$protocol://$authentication$host:$port/$proxy_uri";

        bless {
                _proxy    => $proxy,
        } , $class;
}

sub check_error {
    my ($self, %params) = @_;
    my $display_message = $params{display_message};
    my $internal_error = $params{internal_error};
    if (defined($params{fault_obj})) {
        return if !$params{fault_obj}->fault;  #no error
        $display_message = $internal_error = $params{fault_obj}->faultcode . ": " . $params{fault_obj}->faultstring;
        $display_message =~ s/.*error_string[^A-Za-z]*//xms;
    }
    my $error_message = ERROR_PREFIX.$internal_error;
    print "$error_message\n";
}

#Implement Typecast for iControl enumeration Elements
no warnings 'redefine';
sub SOAP::Deserializer::typecast {
        my ($self, $value, $name, $attrs, $children, $type) = @_;
        return unless ( $type &&
                        ($ICONTROL_TYPECAST_TYPES{$type} ));

        return $value;
}

use warnings;


1;
                          
