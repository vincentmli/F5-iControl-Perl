#!/usr/bin/perl

#iControl device group configuration script Vincent v.li@f5.com, 2013-02-21

use strict;

use warnings;
use Getopt::Long;

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;
use Data::Dumper;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified IO::Socket::SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

        push( @INC, "/usr/local/lib" );
}

use iControlTypeCast;

my $sPort     = "443";
my $sUID      = "admin";
my $sPWD      = "admin";
my $sProtocol = "https";
my $soap_response;

my $timeout = 5;

my $help;
my $syncstatus;
my $devgroup;
my $ip;

my $SyncMode =
{
        0 => "CONFIGSYNC_BASIC",
        1 => "CONFIGSYNC_RUNNING",
        2 => "CONFIGSYNC_ALL",
};
my $SyncModeValue =
{
        "CONFIGSYNC_BASIC" => 0,
        "CONFIGSYNC_RUNNING" => 1,
        "CONFIGSYNC_ALL" => 2,
};

my $CONFIGSYNC_BASIC = "CONFIGSYNC_BASIC";
my $CONFIGSYNC_RUNNING = "CONFIGSYNC_RUNNING";
my $CONFIGSYNC_ALL = "CONFIGSYNC_ALL";

my $STATE_DISABLED = 0;
my $STATE_ENABLED = 1;

my $interface = "2.1";
my $state;






GetOptions(
    "help|h"       => \$help,
    "ip|i=s"   => \$ip,
    "devgroup|g:s" => \$devgroup,
    "state|s:s" => \$state,
    "syncstatus|ss" => \$syncstatus,
);

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0
       --help|-h \t\thelp message
       --ip|-i \t\tmgmt ip
       --devgroup|-g \t\tdevice group name
       --state|-s \t\tinterface state
       --syncstatus|-ss \t\tget sync status

     \n";
    exit;
}



usage() if ( defined $help );

my $STATE = defined ($state) ? $state : $STATE_ENABLED; 

#setInterfaceState($ip, $interface, $STATE_ENABLED, 0);
#syncConfiguration($ip,$CONFIGSYNC_ALL, 0); 
#sleep 30;
setInterfaceState($ip, $interface, $STATE, 0);
syncConfiguration($ip,$CONFIGSYNC_ALL, 0); 
#dgSyncstatus($ip, $devgroup) if ( defined  $syncstatus );




# GetInterface
#----------------------------------------------------------------------------
sub GetInterface() {
    my ( $sHost, $module, $name ) = @_;
    my $Interface;

    $Interface =
      SOAP::Lite->uri("urn:iControl:$module/$name")->readable(1)
      ->proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

   #----------------------------------------------------------------------------
   # Attempt to add auth headers to avoid dual-round trip
   #----------------------------------------------------------------------------

    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm($timeout);

        $Interface->transport->http_request->header( 'Authorization' => 'Basic '
              . MIME::Base64::encode( "$sUID:$sPWD", '' ) );
        alarm(0);
    };

    if ($@) {

        #   warn "caught exception $@: $!";
        return 0;

    }
    else {

        #  warn "no exception $@: $!";
        return $Interface;
    }

}


#----------------------------------------------------------------------------
# checkResponse makes sure the error isn't a SOAP error
#----------------------------------------------------------------------------
sub checkResponse() {
    my ($soap_response) = (@_);
    if ( $soap_response->fault ) {
        print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
        exit();
    }
}

sub dgSyncstatus {
    my ( $ip, $devgroup ) = @_;
    my $dgmgmt = &GetInterface( "$ip", "Management", "DeviceGroup" );
    $soap_response = $dgmgmt->get_sync_status(
        SOAP::Data->name( device_groups => ["$devgroup"] ),
    );
    &checkResponse($soap_response);
    my @syncstatus = @{ $soap_response->result };
#    print Dumper(@syncstatus);
    print "-----sync status---------------------------\n";
    foreach my $st (@syncstatus) {
       my $color = $st->{color};
       my $summary = $st->{summary};
       my $status = $st->{status};
       my $member_state = $st->{member_state};
       print "color: $color\nsummary:$summary\nstatus:$status\nmember_state:$member_state\n"; 
    }
}

#----------------------------------------------------------------------------
# sub syncConfiguration
#----------------------------------------------------------------------------
sub syncConfiguration {
    my ( $adaddr, $syncFlag, $quiet ) = (@_);

    my $success = 0;

    my $configsync = &GetInterface( "$ip", "System", "ConfigSync" );

    $soap_response = $configsync->synchronize_configuration(
        SOAP::Data->name( sync_flag => $syncFlag ) );
    if ( $soap_response->fault ) {
        if ( 1 != $quiet ) {
            print $soap_response->faultcode, " ", $soap_response->faultstring,
              "\n";
        }
    }
    else {
        $success = 1;
        if ( 1 != $quiet ) {
            print "Configuration synchronized successfully!\n";
        }
    }
    return $success;
}

sub setInterfaceState {

    my ( $adaddr, $interface, $state, $quiet ) = (@_);

    my $success = 0;

    my $int = &GetInterface( "$ip", "Networking", "Interfaces" );

    $soap_response = $int->set_enabled_state(
        SOAP::Data->name( interfaces => [ $interface ]  ), 
        SOAP::Data->name( states => [ $state ]  ), 
    );
    if ( $soap_response->fault ) {
        if ( 1 != $quiet ) {
            print $soap_response->faultcode, " ", $soap_response->faultstring,
              "\n";
        }
    }
    else {
        $success = 1;
        if ( 1 != $quiet ) {
            print "$interface state set to $state successfully!\n";
        }
    }
    return $success;


}

