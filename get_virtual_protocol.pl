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
my $virtual;
my $ip;


GetOptions(
    "help|h"       => \$help,
    "ip|i=s"   => \$ip,
    "virtual|v:s" => \$virtual,
);

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0
       --help|-h \t\thelp message
       --ip|-i \t\tmgmt ip
       --virtual|-v \t\tvirtual name

     \n";
    exit;
}

usage() if ( defined $help );
getVirtualProtocol($ip, $virtual) if ( defined  $virtual );




# GetInterface
#----------------------------------------------------------------------------
sub GetInterface() {
    my ( $sHost, $module, $name ) = @_;
    my $Interface;

    $Interface =
      SOAP::Lite->uri("urn:iControl:$module/$name")->readable(1)
      ->proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi", ssl_opts => [ SSL_verify_mode => 0 ]);

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

sub getVirtualProtocol {
    my ( $ip, $virtual ) = @_;
    my $ic = &GetInterface( "$ip", "LocalLB", "VirtualServer" );
    $soap_response = $ic->get_protocol(
        SOAP::Data->name( virtual_servers => ["$virtual"] ),
    );
    &checkResponse($soap_response);
    my @protocols = @{ $soap_response->result };
#    print Dumper(@syncstatus);
    print "-----virtual protocol---------------------------\n";
    foreach my $p (@protocols) {
	
       print "$p\n"; 
    }
}
