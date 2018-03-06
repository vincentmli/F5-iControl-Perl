#!/usr/bin/perl
#if BIGIP 10.x support activate_license method, it would save way much code lines, sigh :(.
#Todo:  figure out handle Perl excption properly to skip unreachble BIG-IP devices if there is
#connection error, it would be more efficient and less script lines

#use SOAP::Lite + trace => qw(method);
use SOAP::Lite;
use MIME::Base64;
use Data::Dumper;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #comment out following line if iControlTypeCast needed
#    push( @INC, "/usr/local/lib" );
}
#use iControlTypeCast;

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
      ->proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

   #----------------------------------------------------------------------------
   # Attempt to add auth headers to avoid dual-round trip
   #----------------------------------------------------------------------------
    eval {
        $Interface->transport->http_request->header( 'Authorization' => 'Basic '
              . MIME::Base64::encode( "$sUID:$sPWD", '' ) );
    };

    return $Interface;
}

my $lock_name = "testlock";
my $duration_sec = 60;
my $comment = "test lock";
&aquireLock("172.24.22.16", $lock_name, $duration_sec, $comment);
&getLock("172.24.22.16");

&aquireLock("10.3.72.33", $lock_name, $duration_sec, $comment);
&getLock("10.3.72.33");

sub getLock() {
    my ($sHost) = @_;
    my $lock =
      &GetInterface( "$sHost", "System", "SystemInfo" );
    $soapResponse = $lock->get_lock_list(); 
    &checkResponse($soapResponse);
    my $locklist = $soapResponse->result;
    print Dumper($locklist);
#    print "geo info: $locklist\n";
}

sub aquireLock() {
    my ($sHost, $lock_name, $duration_sec, $comment) = @_;
    my $lock =
      &GetInterface( "$sHost", "System", "SystemInfo" );
    $soapResponse = $lock->acquire_lock(
		SOAP::Data->name( lock_name => "$lock_name" ),
		SOAP::Data->name( duration_sec => "$duration_sec" ),
		SOAP::Data->name( comment => "$comment" ),
	); 
    &checkResponse($soapResponse);
}

sub getLockstatus() {
    my ($sHost, $lock_name, $duration_sec, $comment) = @_;
    my $lock =
      &GetInterface( "$sHost", "System", "SystemInfo" );
    $soapResponse = $lock->get_lock_status(
		SOAP::Data->name( lock_names => [$lock_name] ),
	); 
    &checkResponse($soapResponse);
}




sub checkResponse() {
    my ($soapResponse) = (@_);
    if ( $soapResponse->fault ) {
        print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
        exit();
    }
}



