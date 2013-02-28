#!/usr/bin/perl
#iControl BIGIP software install script Vincent v.li@f5.com, 2013-02-13

#for some reason when strict in use, got "Use of uninitialized value in array dereference"
#in my @status = @{ $soap_response->result } when script used in --scan_esnet mode; 

#use strict;

use warnings;
use Getopt::Long;

#since iControl has no iso checksum method, have to use SSH to login to run md5sum 
#which is taking time and ssh login could fail for some unknow reason, unless you
#have to, there is really no need to run checksum because if the checksum is bad
#the installation would fail anyway, hope future iControl release can include ISO
#checksum method, that would make life much easier
use Net::SSH::Expect;

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified IO::Socket::SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #    push( @INC, "/usr/local/lib" );
}

#use iControlTypeCast;

my $sPort     = "443";
my $sUID      = "admin";
my $sPWD      = "admin";
my $sProtocol = "https";
my $soap_response;
my $timeout = 5;

#my $defaultChunkSize = 65536/2;
my $defaultChunkSize = 16777216;

my $FILE_UNDEFINED      = "FILE_UNDEFINED";
my $FILE_FIRST          = "FILE_FIRST";
my $FILE_MIDDLE         = "FILE_MIDDLE";
my $FILE_UNUSED         = "FILE_UNUSED";
my $FILE_LAST           = "FILE_LAST";
my $FILE_FIRST_AND_LAST = "FILE_FIRST_AND_LAST";

my $help;
my @ips;
my $volume;
my $image;
my $show;
my $list;
my $upload;
my $checksum;
my $scan_esnet;
my ($major, $isoname, $version, $build);

my @esnet = ( 101 .. 120 );

GetOptions(
    "help|h"        => \$help,
    "ips|i=s"       => \@ips,
    "volume|v=s"    => \$volume,
    "image|m=s"     => \$image,
    "show|s"        => \$show,
    "list|l"        => \$list,
    "upload|u"      => \$upload,
    "checksum|c"    => \$checksum,
    "scan_esnet|sc" => \$scan_esnet,
);

@ips = split( /,/, join( ',', @ips ) );

if ($image) {

	 $major = $image =~ /(?:Hotfix-BIGIP-|BIGIP-)(\d+)\.?/;
	($isoname, $version, $build) = $image  =~ /(Hotfix-BIGIP-|BIGIP-)(\d+\.\d+\.\d+)[-.](\d+\.\d+)/;
}
	

usage() if ($help);

foreach my $ip (@ips) {

    if ( $upload and $image and $volume ) {
        my $success = upload( $ip, $image );
        if ($success) {
            if ($checksum) {
                my $sum_ok = checkSum( $ip, $image );
                if ($sum_ok) {
                    install( $ip, $image, $volume );
                }
            }
            else {
                install( $ip, $image, $volume );
            }
        }
    }
    elsif ( $image and $volume ) {
        if ($checksum) {
            my $sum_ok = checkSum( $ip, $image );
            if ($sum_ok) {
                install( $ip, $image, $volume );
            }
        }
        else {
            install( $ip, $image, $volume );
        }
    }
    else {
        softStatus($ip) if ($show);
        imageList($ip)  if ($list);
    }
}

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0
       --help|-h \t\thelp message
       --ips|-i \t\tlist of ip addresses to install software,example --ips '1.1.1.1,2.2.2.2' 
       --volume|-v \t\tvolume to install
       --image|-m \t\timage file to upload and install, for example '/path-to/BIGIP-11.1.0.1943.0.iso'
       --show|-s \t\tshow software status
       --list|-l \t\tlist images available on BIGIP
       --upload|-u \t\tswitch to upload image to BIGIP ?
       --checksum|-c \t\tswitch to checksum iso image ?
       --scan_esnet|-sc \t\tscan esnet BIGIP software installation status
       \n";
    exit;
}

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

if ($scan_esnet) {
    foreach my $oct ( 101 .. 120 ) {
        my $ip = "172.24.100.$oct";
        print "scaning  $ip ....\n";
        my $ret = softStatus($ip);
        print "next...  \n";
        next if ( !$ret );
    }

}

sub checkSum {
    my ( $sHost, $remoteFile ) = @_;

    $remoteFile =~ s|.*/|| if ($upload);

    my $ssh = Net::SSH::Expect->new(
        host     => "$sHost",
        password => "root",
        user     => 'root',
        raw_pty  => 1,
        timeout  => 5,
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

    #10 seconds timeout to checksum image
    print "checksuming $remoteFile, please wait...\n";
    my $sum = $ssh->exec(
        "cd /shared/images; md5sum --check /shared/images/$remoteFile.md5",
        10 );
    if ( $sum =~ /OK/ ) {
        print "Checksum $sum\n";
        $ssh->close();
        return 1;

    }
    else {

        print "Checksum $sum\n";
        $ssh->close();
        return 0;
    }
}

sub install {
    my ( $ip, $remoteFile, $install_volume ) = @_;
    my $SoftMgmt = &GetInterface( "$ip", "System", "SoftwareManagement" );

    $remoteFile =~ s|.*/|| if ($upload);

    my ( $version, $build ) =
      $remoteFile =~ /(?:Hotfix-BIGIP-|BIGIP-)(\d+.\d+\.\d+)[-.](\d+\.\d+)/;

    $soap_response = $SoftMgmt->install_software_image(
        SOAP::Data->name( install_volume => "$install_volume" ),
        SOAP::Data->name( product        => 'BIGIP' ),
        SOAP::Data->name( version        => "$version" ),
        SOAP::Data->name( build          => "$build" )
    );
    &checkResponse($soap_response);
    print "$remoteFile started install on $ip $volume\n";
    print "run bigip_install.pl -s -i $ip to check software status\n";

}

sub softStatus {

    my ($ip) = @_;
    my $SoftMgmt = &GetInterface( "$ip", "System", "SoftwareManagement" );
    eval { $soap_response = $SoftMgmt->get_all_software_status(); };
    return 0 if ($@);
    &checkResponse($soap_response);
    my @status = @{ $soap_response->result };

    print "$ip software status\n";
    print "volume\tslot\tproduct\tversion\tbuild\tactive\tstatus\n";
    print "--------------------------------------------------------\n";
    foreach my $softstatus (@status) {
        my $InstallationID = $softstatus->{'installation_id'};
        my $slot_id        = $InstallationID->{'chassis_slot_id'};
        my $install_volume = $InstallationID->{'install_volume'};
        my $product        = $softstatus->{'product'};
        my $version        = $softstatus->{'version'};
        my $build          = $softstatus->{'build'};
        my $base_build     = $softstatus->{'base_build'};
        my $active         = $softstatus->{'active'};
        my $edition        = $softstatus->{'edition'};
        my $status         = $softstatus->{'status'};
        print
"$install_volume\t$slot_id\t$product\t$version\t$build\t$active\t$status\n";
    }
    print "--------------------------------------------------------\n\n";
    return 1;
}

sub imageList {
    my ($ip) = @_;

    my $SoftMgmt = &GetInterface( "$ip", "System", "SoftwareManagement" );
    $soap_response = $SoftMgmt->get_software_image_list();
    &checkResponse($soap_response);
    my @imagelist = @{ $soap_response->result };

    print "$ip image list\n";
    print "slot_id\tfilename\n";
    print "--------------------------------------------------------\n";
    foreach my $im (@imagelist) {
        my $chassis_slot_id = $im->{'chassis_slot_id'};
        my $filename        = $im->{'filename'};
        print "$chassis_slot_id\t$filename\n";
    }
    print "--------------------------------------------------------\n\n";

}

sub upload {
    my ( $ip, $localFile ) = @_;
    my $ConfigSync = &GetInterface( "$ip", "System", "ConfigSync" );
    my $remoteFile = $localFile;
    $remoteFile =~ s|^/.*/||;
    my $success;
    if ($upload) {
        $success = uploadFile( $ip, $ConfigSync, "$localFile", "/shared/images/$remoteFile", 0 );
        if($checksum) {

	        if ($major > 10 or $isoname =~ /^Hotfix/ ) {
        		$success = uploadFile( $ip, $ConfigSync, "$localFile.md5", "/shared/images/$remoteFile.md5", 0 );
        	} else {
        		$success = uploadFile( $ip, $ConfigSync, "$localFile.md5", "/shared/images/$remoteFile.md5", 0 );
       		}
        }
     }
    return $success;
}

sub uploadFile {
    my ( $ip, $ConfigSync, $localFile, $fileName, $quiet ) = (@_);
    my $success = 0;

    if ( "" eq $fileName ) {
        $fileName = $localFile;
    }

    my $bContinue            = 1;
    my $chain_type           = $FILE_FIRST;
    my $preferred_chunk_size = $defaultChunkSize;
    my $chunk_size           = $defaultChunkSize;
    my $total_bytes          = 0;
    my $file_data;
    my $bytes_read;
    my $FileTransferContext;

    print "upload $localFile to $ip\n";
    open( my $fh, "<$localFile" ) or die("Can't open $localFile for input: $!");
    binmode($fh);

    while ( 1 == $bContinue ) {
        $file_data = "";
        $bytes_read = read( $fh, $file_data, $chunk_size );

        if ( $preferred_chunk_size != $bytes_read ) {
            if ( $total_bytes == 0 ) {
                $chain_type = $FILE_FIRST_AND_LAST;
            }
            else {
                $chain_type = $FILE_LAST;
            }
            $bContinue = 0;
        }
        $total_bytes += $bytes_read;

        $FileTransferContext = {
            file_data  => SOAP::Data->type( base64 => $file_data ),
            chain_type => $chain_type
        };

        $soap_response =
          $ConfigSync->upload_file( SOAP::Data->name( file_name => $fileName ),
            SOAP::Data->name( file_context => $FileTransferContext ) );

        if ( $soap_response->fault ) {
            if ( 1 != $quiet ) {
                print $soap_response->faultcode, " ",
                  $soap_response->faultstring, "\n";
            }
            $success   = 0;
            $bContinue = 0;
        }
        else {
            if ( 1 != $quiet ) {
                print "Uploaded $total_bytes bytes, continue...\n";
            }
            $success = 1;
            if ( $chain_type eq $FILE_LAST ) {
                my $total_mb = $total_bytes / ( 1024 * 1024 );
                print "Uploaded $total_mb mb, Done! \n";
            }
        }
        $chain_type = $FILE_MIDDLE;
    }
    print "\n";

    close($fh);

    return $success;
}

#----------------------------------------------------------------------------
# checkResponse makes sure the error isn't a SOAP error
# if method not implemented or excption occurs, dont exit
# in scan_esnet mode, so exit() commented 
#----------------------------------------------------------------------------
sub checkResponse() {
    my ($soapResponse) = (@_);
    if ( $soapResponse->fault ) {
        print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
        #        exit();
    }
}

