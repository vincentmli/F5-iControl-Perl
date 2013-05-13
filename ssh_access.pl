#!/usr/bin/perl

use SOAP::Lite;
use MIME::Base64;
use Data::Dumper;

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
    push( @INC, "/usr/local/lib" );
}
use iControlTypeCast;


#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sPort = 443;
my $sUID = $ARGV[1];
my $sPWD = $ARGV[2];
my $sSTATE = $ARGV[3];
my $sADDRS = $ARGV[4];
my $sProtocol = "https";

if ( ("80" eq $sPort) or ("8080" eq $sPort) )
{
        $sProtocol = "http";
}

if ( ($sHost eq "") or ($sPort eq "") or ($sUID eq "") or ($sPWD eq "") )
{
        die ("Usage: $0 host uid pwd state addresses\n");
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
        return "$sUID" => "$sPWD";
}

$soap = SOAP::Lite
        -> uri('urn:iControl:System/Services')
        -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $soap->transport->http_request->header
(
        'Authorization' =>
                'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };




#----------------------------------------------------------------------------
# sub getSSHAccess
#----------------------------------------------------------------------------
sub getSSHAccess()
{
	my $soapResponse = $soap->get_ssh_access_v2();
	&checkResponse($soapResponse);
	
	my $SSHAccessV2 = $soapResponse->result;
	my $state = $SSHAccessV2->{"state"};
	my @addresses = @{ $SSHAccessV2->{"addresses"} };
	
	print "State: $state\n";
	foreach $address (@addresses)
	{
		print " -> $address\n";
	}
}

#----------------------------------------------------------------------------
# sub setSSHAccess
#----------------------------------------------------------------------------
sub setSSHAccess()
{
	my ($state, $addrlist) = (@_);
	
	my @addresses = split(/,/, $addrlist);
	
	print "addresses: @addresses\n";

	my $SSHAccessV2 = {
		state => $state,
		addresses => [@addresses]
	};
	
	my $soapResponse = $soap->set_ssh_access_v2(
		SOAP::Data->name(access => $SSHAccessV2)
	);
	&checkResponse($soapResponse);
}

#----------------------------------------------------------------------------
# checkResponse
#----------------------------------------------------------------------------
sub checkResponse()
{
	my ($soapResponse) = (@_);
	if ( $soapResponse->fault )
	{
		print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
		exit();
	}
}

#----------------------------------------------------------------------------
# Main program logic
#----------------------------------------------------------------------------

if ( $sSTATE eq "" )
{
	&getSSHAccess();
}
elsif ( $sADDRS eq "" )
{
	&setSSHAccess($sSTATE, "ALL");
	&getSSHAccess();
}
else
{
	&setSSHAccess($sSTATE, $sADDRS);
	&getSSHAccess();
}
