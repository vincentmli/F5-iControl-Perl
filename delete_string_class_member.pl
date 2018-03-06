#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the iControl Public License
# Version 4.5 (the "License"); you may not use this file except in
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
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2003 F5 Networks,
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
use Data::Dumper;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sPort = $ARGV[1];
my $sUID = $ARGV[2];
my $sPWD = $ARGV[3];
my $partition = $ARGV[4];
my $sClass = $ARGV[5];
my $sString = $ARGV[6];
my $sProtocol = "https";
my @stringClassMembers;

my $datagroup = "./datagroup.txt";
open($fh, '<', $datagroup) or die "couldn't open: $!";

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
#    push( @INC, "/usr/local/lib" );
}


sub usage()
{
  die ("Usage: stringClass.pl host port uid pwd [partition] [classname] [string] \n");
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

#----------------------------------------------------------------------------
# support for custom enum types
#----------------------------------------------------------------------------
sub SOAP::Deserializer::typecast
{
  my ($self, $value, $name, $attrs, $children, $type) = @_;
  my $retval = undef;
  if ( "{urn:iControl}Class.ClassType" == $type )
  {
    $retval = $value;
  }
  return $retval;
}


$Partition = SOAP::Lite
        -> uri('urn:iControl:Management/Partition')
        -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $NodeAddress->transport->http_request->header
(
        'Authorization' =>
                'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

$Transaction = SOAP::Lite
        -> uri('urn:iControl:System/Session')
        -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $NodeAddress->transport->http_request->header
(
        'Authorization' =>
                'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };


#set active partition
sub setActivePartition()
{
        $soapResponse = $Partition->set_active_partition(
                SOAP::Data->name(active_partition => $partition)
        );
        &checkResponse($soapResponse);

}

#get active partition
sub getActivePartition()
{
        $soapResponse = $Partition->get_active_partition();
        &checkResponse($soapResponse);
        my $active_partition = $soapResponse->result;
        print "my active partition is $active_partition\n";

}

&setActivePartition(); #<==========set partition
&getActivePartition(); #<========get partition

$Class = SOAP::Lite
  -> uri('urn:iControl:LocalLB/Class')
  -> readable(1)
  -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

#----------------------------------------------------------------------------
# sub delete string class member  
#----------------------------------------------------------------------------
sub delStringClassMember()
{
  my ($class, $member_ref) = (@_);
  $soapResponse = $Class->delete_string_class_member
  (
    SOAP::Data->name(class_members => [ { name => $class, members => [@$member_ref] }])
  );
  &checkResponse($soapResponse);
     
}

#----------------------------------------------------------------------------
# sub add string class member  
#----------------------------------------------------------------------------
sub addStringClassMember()
{
  my ($class, $member_ref) = (@_);
  $soapResponse = $Class->add_string_class_member
  (
    SOAP::Data->name(class_members => [ { name => $class, members => [@$member_ref] }])
  );
  &checkResponse($soapResponse);
     
}

#----------------------------------------------------------------------------
# sub set string class member  
#----------------------------------------------------------------------------
sub setStringClassMember()
{
  my ($class, $member_ref, $values_ref) = (@_);
  $soapResponse = $Class->set_string_class_member_data_value
  (
    SOAP::Data->name('class_members' => [ { name => $class, members => [@$member_ref] }]),
    SOAP::Data->name('values' => [ [ @$values_ref ]]),
  );
  &checkResponse($soapResponse);
     
}


#----------------------------------------------------------------------------
# Main program logic
#----------------------------------------------------------------------------

my @test;
my @test_values;



while (<$fh>) {
 my ($key, $value) = split(/\|/, $_);
 push @test, $key;
 push @test_values, $value;
}



if ( "" eq $sClass )
{
  &listClasses();
}
elsif ( "" eq $sString )
{
    
    $Transaction->start_transaction;

    &delStringClassMember($sClass, \@test);
#    &addStringClassMember($sClass, \@test);
#    &setStringClassMember($sClass, \@test, \@test_values);

    $Transaction->submit_transaction;

    #&getStringClassMemberValuePair($sClass);
   
  #&listStringsClassMemberDataValue($sClass, $class_members);
}
else
{
#  &modifyClass($sClass, $sString);
}


#----------------------------------------------------------------------------
# checkResponse makes sure the error isn't a SOAP error
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
