#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the iControl Public License
# Version 9.2 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.f5.com/.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is iControl Code and related documentation
# distributed by F5.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2005
# F5 Networks, Inc. All Rights Reserved.  iControl (TM) is a registered 
# trademark of F5 Networks, Inc.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
#----------------------------------------------------------------------------

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sPort = $ARGV[1];
my $sUID = $ARGV[2];
my $sPWD = $ARGV[3];
my $sPool = $ARGV[4];
my $sNodeAddr = $ARGV[5];
my $sAddDel = $ARGV[6];
my $sProtocol = "https";

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
#    push( @INC, "/usr/local/lib" );
}


sub usage()
{
	die ("Usage: $0 host port uid pwd \n");
}

if ( ($sHost eq "") or ($sPort eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	usage();
}

if ( ("80" eq $sPort) or ("8080" eq $sPort) )
{
	$sProtocol = "http";
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
	return "$sUID" => "$sPWD";
}

$Dns = SOAP::Lite
	-> uri('urn:iControl:LocalLB/DNSCache')
	-> readable(1)
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

#----------------------------------------------------------------------------
# Attempt to add auth headers to avoid dual-round trip
#----------------------------------------------------------------------------
eval { $Dns->transport->http_request->header
(
	'Authorization' =>
	'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

#----------------------------------------------------------------------------
# support for custom enum types
#----------------------------------------------------------------------------
sub SOAP::Deserializer::typecast
{
	my ($self, $value, $name, $attrs, $children, $type) = @_;
	my $retval = undef;
	if ( "{urn:iControl}Common.EnabledState" == $type )
	{
		$retval = $value;
	}
	return $retval;
}

#----------------------------------------------------------------------------
# Main logic
#----------------------------------------------------------------------------
		

sub delDNScache()
{

        my $soapResponse =
#                $Dns->delete_all_dns_caches ();
                $Dns->delete_all_resource_records (
			SOAP::Data->name ( caches => ( ["dns_cache_server"] ) ),
			
		);
        &checkResponse($soapResponse);

		
}

&delDNScache;

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

