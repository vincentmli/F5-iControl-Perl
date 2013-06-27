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
my $sProtocol = "https";

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
#    push( @INC, "/usr/local/lib" );
}


sub usage()
{
	die ("Usage: togglePoolMember.pl host port uid pwd [pool [addr:port]]\n");
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

$Pool = SOAP::Lite
	-> uri('urn:iControl:LocalLB/Pool')
	-> readable(1)
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
$PoolMember = SOAP::Lite
	-> uri('urn:iControl:LocalLB/PoolMember')
	-> readable(1)
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

#----------------------------------------------------------------------------
# Attempt to add auth headers to avoid dual-round trip
#----------------------------------------------------------------------------
eval { $Pool->transport->http_request->header
(
	'Authorization' =>
	'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };
eval { $PoolMember->transport->http_request->header
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
if ( "" eq $sPool )
{
	#------------------------------------------------------------------------
	# No pool supplied.  Query pool list and display members for given pool
	#------------------------------------------------------------------------
	$soapResponse = $Pool->get_list();
	&checkResponse($soapResponse);
	@pool_list = @{$soapResponse->result};
	
	&showPoolMembers(@pool_list);
}
elsif ( "" eq $sNodeAddr )
{
	#------------------------------------------------------------------------
	# Pool supplied, but now member so display given pools members
	#------------------------------------------------------------------------
	&showPoolMembers($sPool);
}
else
{
	#------------------------------------------------------------------------
	# both pool and member supplied so toggle the specified member.
	#------------------------------------------------------------------------
	&togglePoolMember($sPool, $sNodeAddr);
}

#----------------------------------------------------------------------------
# Show list of pools and members
#----------------------------------------------------------------------------
sub showPoolMembers()
{
	my (@pool_list) = @_;
	my @member_state_lists = &getPoolMemberStates(@pool_list);
	
	print "Available pool members\n";
	print "======================\n";
	$i = 0;
	foreach $pool (@pool_list)
	{
		print "pool $pool\n{\n";
		@member_state_list = @{@member_state_lists[$i]};
		foreach $member_state (@member_state_list)
		{
			$member = $member_state->{"member"};
			$addr = $member->{"address"};
			$port = $member->{"port"};

			$session_state = $member_state->{"session_state"};

			print "    $addr:$port ($session_state)\n";
		}
		print "}\n";
		$i++;
	}
}

#----------------------------------------------------------------------------
# Toggle a specified pool member
#----------------------------------------------------------------------------
sub togglePoolMember()
{
	my ($pool_name, $member_def) = (@_);
	
	#------------------------------------------------------------------------
	# Split apart node:port 
	#------------------------------------------------------------------------
	($sNodeIP, $sNodePort) = split(/:/, $member_def, 2);
	if ( "" eq $sNodePort )
	{
		$sNodePort = "0";
	}
	$member = { address => $sNodeIP, port => $sNodePort };

	#--------------------------------------------------------------------
	# Query enabled state for given Node:port
	#--------------------------------------------------------------------
	$pool_member_state = &getPoolMemberState($pool_name, $member);

	#----------------------------------------------------------------
	# Set the state to be toggled to.
	#----------------------------------------------------------------
	my $toggleState = "STATE_DISABLED";
	if ( "STATE_DISABLED" eq $pool_member_state )
	{
		$toggleState = "STATE_ENABLED";
	}
	elsif ( "STATE_ENABLED" eq $pool_member_state )
	{
		$toggleState = "STATE_DISABLED";
	}
	else
	{
		die("Couldn't find member $member_def in pool $pool_name\n");
	}
	
	$MemberSessionState = 
	{
		member => $member,
		session_state => $toggleState
	};
	push @MembersList, $member;
	push @MemberSessionStateList, $MemberSessionState;
	push @MemberSessionStateLists, [@MemberSessionStateList];

	#----------------------------------------------------------------
	# Toggle the state.
	#----------------------------------------------------------------
	$soapResponse =
		$Pool->set_member_session_enabled_state
		(
			SOAP::Data->name ( pool_names => ( [$pool_name] ) ),
			SOAP::Data->name ( members => ( [ [ @MembersList ] ] ) ),
			SOAP::Data->name ( session_states => [ [ $toggleState ] ] )	
		);
	&checkResponse($soapResponse);

	print "Pool Member $pool_name {$sNodeIP:$sNodePort} state set from '$pool_member_state' to '$toggleState'\n";
}

#----------------------------------------------------------------------------
# returns the status structures for the members of the specified pools
#----------------------------------------------------------------------------
sub getPoolMemberStates()
{
	my (@pool_list) = @_;

	$soapResponse = $PoolMember->get_session_enabled_state
	(
		SOAP::Data->name(pool_names => [@pool_list])
	);
	&checkResponse($soapResponse);
	@member_state_lists = @{$soapResponse->result};

	return @member_state_lists;
}

#----------------------------------------------------------------------------
# Get the actual state of a given pool member
#----------------------------------------------------------------------------
sub getPoolMemberState()
{
	my ($pool_name, $member_def) = (@_);
	my $state = "";
	@member_state_lists = &getPoolMemberStates($pool_name);
	@member_state_list = @{@member_state_lists[0]};
	foreach $member_state (@member_state_list)
	{
		my $member = $member_state->{"member"};
		if ( ($member->{"address"} eq $member_def->{"address"}) and
		     ($member->{"port"} eq $member_def->{"port"}) )
		{
			$state = $member_state->{"session_state"}
		}
	}
	return $state;
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

