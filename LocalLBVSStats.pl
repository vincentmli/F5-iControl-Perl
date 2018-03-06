#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT FOR F5
# Software Development Kit for iControl"; you may not use this file except in
# compliance with the License. The License is included in the iControl
# Software Development Kit.
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
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2004 F5 Networks,
# Inc. All Rights Reserved.  iControl (TM) is a registered trademark of F5 Networks, Inc.
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
use MIME::Base64;
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
my $sHost = $ARGV[0];
my $sPort = $ARGV[1];
my $sUID = $ARGV[2];
my $sPWD = $ARGV[3];
my $sCommand = $ARGV[4];
my $sArg1 = $ARGV[5];
my $sArg2 = $ARGV[6];
my $sProtocol = "https";


if ( ("80" eq $sPort) or ("8080" eq $sPort) )
{
	$sProtocol = "http";
}

if ( ($sHost eq "") or ($sPort eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	&usage();
}

sub usage()
{
	my ($sCmd) = @_;
	print "Usage: LocalLBVSStats.pl host port uid pwd command [options]\n";
	print "    -----------------------------------------------------------\n";

	if ( ($sCmd eq "") or ($sCmd eq "get") )
	{
		print "    get      virtual server     - Query the specified virtual server\n";
	}
	if ( ($sCmd eq "") or ($sCmd eq "list") )
	{
		print "    list                        - List the entire virtual server list\n";
	}
	exit();
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
	return "$sUID" => "$sPWD";
}

$VirtualServer = SOAP::Lite
	-> uri('urn:iControl:LocalLB/VirtualServer')
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $VirtualServer->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

if ( $sCommand eq "get" )
{
	&validateArgs("get", $sArg1);
	&handle_get($sArg1);
}
elsif ( $sCommand eq "list" )
{
	&handle_list();
}
else
{
	&usage();
}

#----------------------------------------------------------------------------
# validateArgs
#----------------------------------------------------------------------------
sub validateArgs()
{
	my ($cmd, @args) = (@_);

	foreach $arg (@args)
	{
		if ( "" eq $arg )
		{
			&usage($cmd);
		}
	}
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
# get
#----------------------------------------------------------------------------
sub handle_get()
{
	(@VirtualServerList) = @_;

	if ( 0 == scalar(@VirtualServerList) )
	{
		return;
	}

	$soapResponse = $VirtualServer->get_statistics
		(
			SOAP::Data->name(virtual_servers => [@VirtualServerList])
		);
	&checkResponse($soapResponse);
	$VirtualServerStatistics = $soapResponse->result;

	$time_stamp = $VirtualServerStatistics->{"time_stamp"};
	@VirtualServerStatisticEntry = @{$VirtualServerStatistics->{"statistics"}};

	foreach $VirtualServerStatistic (@VirtualServerStatisticEntry)
	{
		$virtual_server = $VirtualServerStatistic->{"virtual_server"};
		$name = $virtual_server->{"name"};
		$address = $virtual_server->{"address"};
		$port = $virtual_server->{"port"};
		$protocol = $virtual_server->{"protocol"};

		print "Virtual Server: '$name' ($address:$port)\n";

		@StatisticList = @{$VirtualServerStatistic->{"statistics"}};
		foreach $Statistic (@StatisticList)
		{
			$type = $Statistic->{"type"};
			$value = $Statistic->{"value"};
			$low = $value->{"low"};
			$high = $value->{"high"};
			$value64 = ($high<<32)|$low;
			$time_stamp = $Statistic->{"time_stamp"};
			print "--> $type : $value64\n";
		}

	}
}
	

#----------------------------------------------------------------------------
# list
#----------------------------------------------------------------------------
sub handle_list()
{
	$soapResponse = $VirtualServer->get_list();
	&checkResponse($soapResponse);

	@VirtualServerList = @{$soapResponse->result};
	&handle_get(@VirtualServerList);
}

