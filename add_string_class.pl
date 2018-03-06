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
# sub get string class member and memer value pair 
#----------------------------------------------------------------------------
sub getStringClassMemberValuePair()
{
  ($class) = (@_);
  $soapResponse = $Class->get_string_class
  (
    SOAP::Data->name(class_names => [$class])
  );
  &checkResponse($soapResponse);
  @StringClassList = @{$soapResponse->result};
  foreach $StringClass (@StringClassList)
  {
    $name = $StringClass->{"name"};
    print "Name : $name\n";
    my @members = @{$StringClass->{"members"}};
    foreach $member (@members
    {
     my @memberValues = getStringsClassMemberDataValue($class, $member);
     #print "member     : $member\n";

     foreach my $memberValue (@memberValues) {
        foreach (@$memberValue) {
                print  "$member|$_\n";
                print $fh "$member|$_\n";
        }
     }
     
    }
  }
}

sub getStringsClassMemberDataValue()
{
  my ($class, $member) = (@_);
  $soapResponse = $Class->get_string_class_member_data_value(
    SOAP::Data->name(class_members => [  { name => $class, members => [$member] }   ])
    #SOAP::Data->name(class_members => [  $class_members  ])
  );
  &checkResponse($soapResponse);
  @StringClassList = @{$soapResponse->result};
  return (@StringClassList);

=for head

  # print "Class Name : $class\n";
  foreach $StringValue (@StringClassList) {
	foreach (@$StringValue) {
		print "$_\n";
	}
 } 
#  print Dumper(@StringClassList);

=cut

}


#----------------------------------------------------------------------------
# Main program logic
#----------------------------------------------------------------------------

#my $member1 = '4401';
#my $member2 = '5401';
#my $member3 = '6401';


#push @members, $member1;
#push @members, $member2;
#push @members, $member3;
#my $class_members = { name => $sClass, members => [ @members ] };


#my @test = ("test1", "test2");
#my @test_values = ("11", "12");
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
# sub listClasses
#----------------------------------------------------------------------------
sub listClasses()
{
  $soapResponse = $Class->get_string_class_list();
  &checkResponse($soapResponse);
  @ClassList = @{$soapResponse->result};
  foreach $ClassName (@ClassList)
  {
    print "Class Name: $ClassName\n";
  }
}


sub listStringsClassMemberDataValue()
{
  my ($class, $class_members) = (@_);
  $soapResponse = $Class->get_string_class_member_data_value
  (
    #SOAP::Data->name(class_members => [  { name => $class, members => [4401, 5401, 6401] }   ])
    SOAP::Data->name(class_members => [  $class_members  ])
  );
  &checkResponse($soapResponse);
  @StringClassList = @{$soapResponse->result};
   print "Class Name : $class\n";
  foreach $StringValue (@StringClassList) {
	foreach (@$StringValue) {
		print "$_\n";
	}
 } 
#  print Dumper(@StringClassList);
}

#----------------------------------------------------------------------------
# sub modifyClass
#----------------------------------------------------------------------------
sub modifyClass()
{
  my ($class, $string) = (@_);
  @values = split(/,/, $string);

  $StringClass =
  {
    name => $class, 
    members => [@values]
  };
  
  $soapResponse = $Class->modify_string_class
  (
    SOAP::Data->name(classes => [$StringClass])
  );
  &checkResponse($soapResponse);
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
