#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT
# FOR F5 Software Development Kit for iControl"; you may not use this file
# except in compliance with the License. The License is included in the
# iControl Software Development Kit.
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
use MIME::Base64;

BEGIN {push (@INC, "/usr/local/lib"); $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;}
use iControlTypeCast;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sPort = $ARGV[1];
my $sUID = $ARGV[2];
my $sPWD = $ARGV[3];
my $sPool = $ARGV[4];
my $sProtocol = "https";

if ( ("80" eq $sPort) or ("8080" eq $sPort) )
{
	$sProtocol = "http";
}

if ( ($sHost eq "") or ($sPort eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	die ("Usage: PoolMemberMonitors.pl host port uid pwd [pool_name]\n");
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
	return "$sUID" => "$sPWD";
}

$Pool = SOAP::Lite
	-> uri('urn:iControl:LocalLB/Pool')
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
$Pool->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
);

$Monitor = SOAP::Lite
	-> uri('urn:iControl:LocalLB/Monitor')
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
$Monitor->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
);


&setMonitorInstance(0);

if ( $sPool eq "" )
{
	&getAllPoolMemberMonitorInfo();
}
else
{
	&getPoolMemberMonitorInfo($sPool);
}


sleep 30; 

&setMonitorInstance(1);

if ( $sPool eq "" )
{
	&getAllPoolMemberMonitorInfo();
}
else
{
	&getPoolMemberMonitorInfo($sPool);
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

my $ATYPE_EXPLICIT_ADDRESS_EXPLICIT_PORT = 3;
my $INSTANCE_STATE_DISABLED = 5;

#----------------------------------------------------------------------------
# set monitor instance
#----------------------------------------------------------------------------
sub setMonitorInstance { 

    my ( $state ) = @_;

    $soapResponse = $Monitor->set_instance_state(
     
      SOAP::Data->name(instance_states => [ 
			{ 
				instance => { 
					template_name => "http_monitor",
					instance_definition => {
						address_type => "$ATYPE_EXPLICIT_ADDRESS_EXPLICIT_PORT",
						ipport => { 
							address => '10.2.72.99',
							port => '80',
						}
					}
							 
				}, 
			  	instance_state => "$INSTANCE_STATE_DISABLED", 
			  	enabled_state => $state,
			} 
      ] 
	
    ),
  );
  &checkResponse($soapResponse);
      
}

#----------------------------------------------------------------------------
# getAllPoolMemberMonitorInfo
#----------------------------------------------------------------------------
sub getAllPoolMemberMonitorInfo()
{
	$soapResponse = $Pool->get_list();
	&checkResponse($soapResponse);
	my @pool_list = @{$soapResponse->result};

	&getPoolMemberMonitorInfo(@pool_list);
}

#----------------------------------------------------------------------------
# getAddress()
#----------------------------------------------------------------------------
sub getAddress()
{
	($MonitorInstance) = (@_);
	$instance = $MonitorInstance->{"instance"};
	$template_name = $instance->{"template_name"};
	$instance_definition = $instance->{"instance_definition"};
	$ipport = $instance_definition->{"ipport"};
	$address = $ipport->{"address"};
	$port = $ipport->{"port"};

	return "$address:$port";
}

#----------------------------------------------------------------------------
# sort_by_member
#----------------------------------------------------------------------------
sub sort_by_member {
	return &getAddress($a) cmp &getAddress($b);
}


#----------------------------------------------------------------------------
# getPoolMemberMonitorInfo
#----------------------------------------------------------------------------
sub getPoolMemberMonitorInfo()
{
	my @pool_list = @_;

	my $last_member = "";

	# Get Member List
	$soapResponse = $Pool->get_monitor_instance
	(
		#SOAP::Data->name(pool_names => [@pool_list])
		SOAP::Data->name(pool_names => ['pool_72-99'])
	);
	&checkResponse($soapResponse);
	my @MonitorInstanceStateAofA = @{$soapResponse->result};
	for $i (0 .. $#MonitorInstanceStateAofA)
	{
		print "Pool $pool_list[$i] {\n";
		$MonitorInstanceStateList = $MonitorInstanceStateAofA[$i];

		foreach $MonitorInstance
		(
			sort sort_by_member @{$MonitorInstanceStateList}
		)
		{
			$instance = $MonitorInstance->{"instance"};
#			$template_name = $instance->{"template_name"};
			$template_name = $MonitorInstance->{"instance"}->{"template_name"};
			$instance_definition = $instance->{"instance_definition"};
			$address_type = $instance_definition->{"address_type"};
			$ipport = $instance_definition->{"ipport"};
			$address = $ipport->{"address"};
			$port = $ipport->{"port"};
			$instance_state = $MonitorInstance->{"instance_state"};
			$enabled_state = $MonitorInstance->{"enabled_state"};

			$current_member = "$address:$port";
			if ( $current_member ne $last_member ) 
			{
				# New member so print header
				$last_member = $current_member;
				print "  Member   : $current_member\n";
			}
			
			print "    Template : $template_name\n";
			print "               Address Type  : $address_type\n";
			print "               Instance State: $instance_state\n";
			print "               Enabled State :";
			if ( 0 == $enabled_state )
			{
				print "Disabled";
			}
			else 
			{
				print "Enabled";
			}
			print "\n";
		}
		print "}\n";
	}
}	
