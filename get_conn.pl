#!/usr/bin/perl
#if BIGIP 10.x support activate_license method, it would save way much code lines, sigh :(.
#Todo:  figure out handle Perl excption properly to skip unreachble BIG-IP devices if there is
#connection error, it would be more efficient and less script lines

use SOAP::Lite + trace => qw(method debug);
#use SOAP::Lite;
use MIME::Base64;
use Data::Dumper;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
    push( @INC, "/usr/local/lib" );
}
use iControlTypeCast;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost;
my $sPort     = "443";
my $sUID      = "admin";
my $sPWD      = "admin";
my $sProtocol = "https";

# GetInterface
#----------------------------------------------------------------------------
sub GetInterface() {
    my ( $sHost, $module, $name ) = @_;
    my $Interface =
      SOAP::Lite->uri("urn:iControl:$module/$name")->readable(1)
      ->proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi",
	      ssl_opts => [ SSL_verify_mode => 0 ]
        );

   #----------------------------------------------------------------------------
   # Attempt to add auth headers to avoid dual-round trip
   #----------------------------------------------------------------------------
    eval {
        $Interface->transport->http_request->header( 'Authorization' => 'Basic '
              . MIME::Base64::encode( "$sUID:$sPWD", '' ) );
    };

    return $Interface;
}

my $clientside_client = { address => 10.1.72.6, port => 12345 } ;
my $clientside_server = { address => 10.1.72.88, port => 80 } ;

sub getConn() {
    my ($sHost) = @_;
    my $conn =
      &GetInterface( "$sHost", "System", "Connections" );
    $soapResponse = $conn->get_active_connection_v2(
		SOAP::Data->name( connections => [ {"clientside_client" => $clientside_client}  ] ),
	);

    &checkResponse($soapResponse);
    my $connofA = @{ $soapResponse->result };
    foreach my $con (@{$connofA}) {
	my $connection_id = $con->connection_id;
	print Dumper($connection_id);
    }

}

sub checkResponse() {
    my ($soapResponse) = (@_);
    if ( $soapResponse->fault ) {
        print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
        exit();
    }
}


&getConn("172.24.19.9");
