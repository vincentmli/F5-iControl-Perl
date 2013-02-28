#!/usr/bin/perl
#if BIGIP 10.x support activate_license method, it would save way much code lines, sigh :(.
#Todo:  figure out handle Perl excption properly to skip unreachble BIG-IP devices if there is
#connection error, it would be more efficient and less script lines

#use SOAP::Lite + trace => qw(method debug);
use Socket;
use IO::Socket::SSL;
use Net::SSH::Expect;
use SOAP::Lite;
use MIME::Base64;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified SSL.pm to remove the SSL verification alert, got better idea ?

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

sub renewKey {
    my ( $sHost, $reg ) = @_;

    my $ssh = Net::SSH::Expect->new(
        host     => "$sHost",
        password => "root",
        user     => 'root',
        raw_pty  => 1,

        #workaround the ssh uknown host key question
        ssh_option => '-o StrictHostKeyChecking=no',
    );

    my $login_output = $ssh->login();
    if ( $login_output !~ /Last/ ) {
        $ssh = Net::SSH::Expect->new(
            host       => "$sHost",
            password   => 'default',
            user       => 'root',
            raw_pty    => 1,
            ssh_option => '-o StrictHostKeyChecking=no',
        );
        $login_output = $ssh->login();
        if ( $login_output !~ /Last/ ) {
            die "Login has failed. Login output was $login_output";

        }

    }

    $ssh->exec("stty raw -echo");

#wish bigip 10.x had iControl activate_license feature, SOAPLicenseClient take too long to activate the license
#have to give 60 seconds timeout for exec, may need to be longer depending the the timeout of SOAPLicenseClient
    my $renew =
      $ssh->exec( "/usr/local/bin/SOAPLicenseClient --basekey $reg", 60 );
    my $ls = $ssh->exec("echo $reg");

    $ssh->close();
}

sub Licdevice() {
    my ($sHost) = @_;
    my $MgmtLic =
      &GetInterface( "$sHost", "Management", "LicenseAdministration" );
    my $SysInfo = &GetInterface( "$sHost", "System", "SystemInfo" );
    $soapResponse = $MgmtLic->get_evaluation_license_expiration();
    &checkResponse($soapResponse);
    my $EvalExp    = $soapResponse->result;
    my $curr_time  = scalar localtime( $EvalExp->{"current_system_time"} );
    my $eval_start = scalar localtime( $EvalExp->{"evaluation_start"} );
    my $eval_exp   = scalar localtime( $EvalExp->{"evaluation_expire"} );
    my $time_diff =
      $EvalExp->{"evaluation_expire"} - $EvalExp->{"current_system_time"};
    my $hour_to_exp = $time_diff / 3600;
    print
"Host $sHost system time: $curr_time evaluation_start $eval_start evaluation_expire $eval_exp expire in $hour_to_exp hour\n";

    if ( $hour_to_exp < 5 ) {
        $soapResponse = $MgmtLic->get_registration_keys();
        &checkResponse($soapResponse);
        my $reg = ( @{ $soapResponse->result } )[0];

        #print "regkey: $reg\n";

        $soapResponse = $SysInfo->get_product_information();
        &checkResponse($soapResponse);
        my $sysinfo         = $soapResponse->result;
        my $product_version = $sysinfo->{"product_version"};
        my $major_version   = ( split( /([.])/, $product_version ) )[0];

        #print "product version $major_version\n";

        if ( $major_version >= 11 ) {

            $soapResponse = $MgmtLic->activate_license(
                SOAP::Data->name( registration_keys => ["$reg"] ),
            );
            &checkResponse($soapResponse);
        }
        else {
            &renewKey( $sHost, $reg );

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

my $timeout = 5;

sub portAlive {
    my ($host) = @_;

    #print "host $host\n";
    my $proto = getprotobyname('tcp');
    my $iaddr = inet_aton($host);
    my $paddr = sockaddr_in( $sPort, $iaddr );

    socket( SOCKET, PF_INET, SOCK_STREAM, $proto ) || warn "socket: $!";

    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm($timeout);
        connect( SOCKET, $paddr ) || error();
        alarm(0);
    };

    if ($@) {
        close SOCKET || warn "close: $!";

        # print "$hostname is NOT listening on tcp port $portnumber.\n";
        return 0;
    }
    else {
        close SOCKET || warn "close: $!";

        # print "$hostname is listening on tcp port $portnumber.\n";
        return 1;
    }
}

sub sslAlive {
    my ($host) = @_;

    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm($timeout);
        my $client = IO::Socket::SSL->new("$host:$sPort")
          || warn "I encountered a problem: " . IO::Socket::SSL::errstr();

        print $client "GET / HTTP/1.0\r\n\r\n";

        #      print <$client>;

        alarm(0);
    };

    if ($@) {

        #      close $client || warn "close: $!";
        #      print "$host $sPort is not working properly $.\n";
        return 0;
    }
    else {

        #      close $client || warn "close: $!";
        #       print "$host $sPort is working properly.\n";
        return 1;
    }

}

#&Licdevice("172.24.100.117");

###############main script ###########

=for head
#weird negative comparision isn't working as it suppose to, I must be miss something simple!
# skip esnet EM device id 115 and 116, device 109 not exist, 114, 120 seems not in use neither  
foreach my $oct ( 101 .. 120 ) {
    my $ip = "172.24.100.$oct";
    if ( $oct != 115 or $oct != 116 ) {
        if ( portAlive("$ip") and sslAlive("$ip") ) {
            &Licdevice("$ip");

        }
    }
    else {
      print "oct $oct\n";
    }
}

=cut

foreach my $oct ( 101 .. 120 ) {
    my $ip = "172.24.100.$oct";
    if ( $oct == 115 or $oct == 116 or $oct == 114 or $oct == 120 ) {
    }
    else {
        if ( portAlive($ip) and sslAlive("$ip") ) {
            &Licdevice("$ip");

        }
    }
}

