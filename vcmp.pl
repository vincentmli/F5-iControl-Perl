#!/usr/bin/perl
#iControl vcmp Vincent v.li@f5.com, 2013-02-05
use strict;
use warnings;
use Getopt::Long;

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    push( @INC, "/usr/local/lib" );
}
use iControlTypeCast;

#generate a random fourth octet for guest management ip
my $oct = int( rand(255) );

#generate random guest name starting with ivcmp
my @chars  = ( "a" .. "z" );
my $string = "ivcmp";
$string .= $chars[ rand @chars ] for 1 .. 3;

#----------------------------------------------------------------------------
# default settings user can change
#----------------------------------------------------------------------------
my $sPort     = "443";
my $sUID      = "admin";
my $sPWD      = "admin";
my $sProtocol = "https";
my $soapResponse;

my $vlans_ref = [ "esnet-ext", "esnet-int" ];    #vlans assign to guest
my $netmask  = "255.255.0.0";                    #guest management ip netmask
my $host     = '10.3.1.1';
my $mgmt     = "10.3.210.$oct";
my $guest    = "$string";
my $hostname = "$string.cluster1.es.f5net";
my $images   = 'BIGIP-11.1.0.1943.0.iso';
my $gateway  = '10.3.254.254';

#----------------------------------------------------------------------------
# default settings end
#----------------------------------------------------------------------------

my $create;
my $del;
my $rmvdisk;
my $help;

GetOptions(
    "help|?"       => \$help,
    "host|h=s"     => \$host,
    "mgmt|m=s"     => \$mgmt,
    "guest|g=s"    => \$guest,
    "images|im=s"  => \$images,
    "gateway|gw=s" => \$gateway,
    "vlans|v=s@"   => \$vlans_ref,
    "create|c"     => \$create,
    "del|d"        => \$del,
    "rmvdisk|r"    => \$rmvdisk,
);

usage() if ( defined $help or @ARGV < 0 );

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0 
       --help|? \t\thelp message
       --host|-h \t\thypervisor management ip
       --mgmt|-m \t\tguest management ip, if not given, random mgmt ip 10.3.210.xxx assigned
       --guest|-g \t\tguest name,if not given, random ivcmpxxx name generated 
       --hostname|-hn \t\tguest fqdn hostname, if not given  'ivcmpxxx.cluster1.es.f5net' assigned
       --images|-im \t\tguest initial image, for example 'BIGIP-11.1.0.1943.0.iso'  
       --gateway|-gw \t\tguest management gateway
       --vlans|-v \t\tvlans assigned to guest, for example '--vlans vlan1 --vlans vlan2'
       --create|-c \t\tcreate guest, if only given -c option, a random guest name ivcmpxxx and random mgmt ip 10.3.210.xxx assigned 
       --del|-d \t\tdelete guest, must give --guest/-g for specific guest
       --rmvdisk|-r \t\tremove virtual disk image, must give --guest/-g for specific guest 
       \n";
    exit;
}

vcmpCreate()  if ( defined $create );
vcmpDelete()  if ( defined $del );
vdiskDelete() if ( defined $rmvdisk );

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

sub vcmpCreate {
    my ($sHost) = $host;
    my $vcmp = &GetInterface( "$sHost", "System", "VCMP" );

    $soapResponse = $vcmp->create(
        SOAP::Data->name( guests    => ["$guest"] ),
        SOAP::Data->name( hostnames => ["$hostname"] ),
        SOAP::Data->name( images    => ["$images"] ),
        SOAP::Data->name(
            addresses => [ { address => "$mgmt", netmask => "$netmask" } ]
        ),
        SOAP::Data->name( gateways => ["$gateway"] ),
        SOAP::Data->name( vlans    => [ [@$vlans_ref] ] ),
    );
    &checkResponse($soapResponse);
    print "VCMP guest $guest created successfully\n";

    $soapResponse = $vcmp->set_guest_state(
        SOAP::Data->name( guests => ["$guest"] ),
        SOAP::Data->name( states => ["VCMP_GUEST_STATE_DEPLOYED"] ),
    );
    &checkResponse($soapResponse);
    print "VCMP guest $guest deployed set successfully\n";

}

sub vcmpDelete {

    my ($sHost) = $host;
    my $vcmp = &GetInterface( "$sHost", "System", "VCMP" );
    $soapResponse =
      $vcmp->delete_guest( SOAP::Data->name( guests => ["$guest"] ), );
    &checkResponse($soapResponse);

    print "VCMP guest $guest delete successfully\n";

}

sub vdiskDelete {

    my ($sHost) = $host;
    my $vcmp = &GetInterface( "$sHost", "System", "VCMP" );

    $soapResponse = $vcmp->get_virtual_disk_list();
    &checkResponse($soapResponse);
    my @vdlist = @{ $soapResponse->result };

    foreach my $vd (@vdlist) {
        my $slot_id  = $vd->{"slot_id"};
        my $filename = $vd->{"filename"};

        if ( $filename eq "$guest.img" ) {

            $soapResponse = $vcmp->delete_virtual_disk(
                SOAP::Data->name(
                    disks => [
                        {
                            slot_id  => "$slot_id",
                            filename => "$guest.img"
                        },
                    ]
                ),
            );
            &checkResponse($soapResponse);
            print "VCMP virtual disk $guest.img delete successfully\n";

        }
    }

}

sub checkResponse() {
    my ($soapResponse) = (@_);
    if ( $soapResponse->fault ) {
        print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
        exit();
    }
}

