#!/usr/bin/perl

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;
use Sys::Syslog;
use POSIX qw(strftime);

my $PID_FILE = "/var/run/get_persist.pid";
my $program  = "GET_PERSIST";

use Time::HiRes
  qw( usleep ualarm gettimeofday tv_interval nanosleep clock_gettime clock_getres clock_nanosleep);

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified SSL.pm to remove the SSL verification alert, got better idea ?

my $urnMap;

sub BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    $urnMap = {
        "{urn:iControl}Common.ProtocolType"     => 1,
        "{urn:iControl}LocalLB.AddressType"     => 1,
        "{urn:iControl}LocalLB.PersistenceMode" => 1,
        "{urn:iControl}LocalLB.ProfileMode"     => 1,
        "{urn:iControl}LocalLB.ProfileType"     => 1,

    };
}
sub END { }

#Implement Typecast for iControl enumeration Elements
sub SOAP::Deserializer::typecast {
    my ( $self, $value, $name, $attrs, $children, $type ) = @_;
    my $retval = undef;
    if ( 1 == $urnMap->{$type} ) {
        $retval = $value;
    }
    return $retval;
}

# End Of File

#----------------------------------------------------------------------------
# Validate Arguments, customer can change
#----------------------------------------------------------------------------
my $sHost;
my $sPort     = "443";
my $sUID      = "admin";    #change username
my $sPWD      = "admin";    #change password
my $sProtocol = "https";

#----------------------------------------------------------------------------
# Validate Arguments, customer change end
#----------------------------------------------------------------------------

my $virtualname = $ARGV[0];

if ( $virtualname eq "" ) {
    die("Usage: $0 virtualname\n");
}

# the debug log variable is a bit mask
# debug = 0 NO LOGGING
# debug | 1 STDOUT
# debug | 2 syslog
# you can enable none, either or both
use constant DEBUG_STDOUT => 1;
use constant DEBUG_SYSLOG => 2;
my $debug = 2;

sub doDebug {
    my @args = @_;
    if ( $debug & DEBUG_STDOUT ) {
        print STDOUT @args;
    }
    if ( $debug & DEBUG_SYSLOG ) {
        syslog( 'LOG_LOCAL0|LOG_DEBUG', @args );
    }
}

openlog( 'GET_PERSIST', 'pid', 'LOG_LOCAL0' );

####### DAEMONIZE #############

sub daemonize {
    use POSIX;
    POSIX::setsid or die "setsid: $!";
    my $pid = fork();
    if ( $pid < 0 ) {
        die "fork: $!";
    }
    elsif ($pid) {
        exit 0;
    }
    chdir "/";
    umask 0;
    foreach ( 0 .. ( POSIX::sysconf(&POSIX::_SC_OPEN_MAX) || 1024 ) ) {
        POSIX::close $_;
    }
    open( STDIN,  "</dev/null" );
    open( STDOUT, ">/dev/null" );
    open( STDERR, ">&STDOUT" );

}

# kill old self, write pid file
if ( -f $PID_FILE ) {
    open( PIDFILE, "<$PID_FILE" );
    kill( 15, <PIDFILE> );
    close(PIDFILE);
}

open( PIDFILE, ">$PID_FILE" );
syswrite( PIDFILE, $$ );
close(PIDFILE);

daemonize();

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

my %node;

sub PersistR() {
    my ( $sHost, $virtualname ) = @_;
    my $virtual = &GetInterface( "$sHost", "LocalLB", "VirtualServer" );
    $soapResponse = $virtual->get_persistence_record(
        SOAP::Data->name( virtual_servers => ["$virtualname"] ),
        SOAP::Data->name(
            persistence_modes => ["PERSISTENCE_MODE_SOURCE_ADDRESS_AFFINITY"]
        ),

    );
    &checkResponse($soapResponse);
    my @prsAofA = @{ $soapResponse->result };

    print "virtual name: $virtualname\n\n";

    foreach my $prsofA (@prsAofA) {
        print
          "pool_name\t\taddress\t\tport\tsource_address\tcreate_time\tage\n\n";

        foreach my $prs ( @{$prsofA} ) {
            my $pool_name         = $prs->{"pool_name"};
            my $address           = $prs->{node_server}->{address};
            my $port              = $prs->{node_server}->{port};
            my $mode              = $prs->{mode};
            my $persistence_value = $prs->{persistence_value};
            my $create_time       = $prs->{create_time};
            my $age               = $prs->{age};
            print
"$pool_name\t$address\t$port\t$persistence_value\t$create_time\t$age\n\n";

            if ( exists $node{$persistence_value} ) {

                if ( $node{$persistence_value} ne $address ) {

#                        doDebug("New record: client ip: $persistence_value node: $address create_time: $create_time age: $age\n");
                    doDebug(
"ALARM: client ip: $persistence_value persist record: $node{$persistence_value}, $address\n"
                    );

#print "client ip: $persistence_value persist record: $node{$persistence_value}, $address\n";
                    exit(1);
                }

            }
            else {

                $node{$persistence_value} = $address;

#             doDebug("client ip: $persistence_value persist record: $address first found\n");
            }

        }

#clear the hash after each get_persistence_record run to fix the bug of false two records
# because if not doing so, the first found persist record stays in the hash memory and
#a second new persist record of course not the same as the first one, thus false alarm

        for ( keys %node ) {
            delete $node{$_};
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

while (1) {
    my ( $seconds, $microseconds ) = gettimeofday;

    my $localtime = scalar localtime("$seconds");

    print "-----------------------------------------------------\n\n";

    print "time: $localtime, microseconds: $microseconds\n\n";

    &PersistR( "127.0.0.1", "$virtualname" );
    usleep(100);

    #sleep(5);

}

closelog();
