#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT FOR F5
# Software Development Kit for iControl"; you may not use this file except in
# compliance with the License. The License is included in the iControl
# Software Development Kit.
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
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2004 F5 Networks,
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
use MIME::Base64;
$| = 1;

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #    push( @INC, "/usr/local/lib" );
}


$sHost = $ARGV[0];
$sPort = $ARGV[1];
$sUID = $ARGV[2];
$sPWD = $ARGV[3];
$sCOMMAND = $ARGV[4];
$sArg1 = $ARGV[5];
$sArg2 = $ARGV[6];

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------

my $sConfigName = "";
my $sLocalFile = "";
my $sSaveMode = "";
my $sProtocol;
my $defaultChunkSize = 65536/2;

my $FileChainType =
{
	0 => "FILE_UNDEFINED",
	1 => "FILE_FIRST",
	2 => "FILE_MIDDLE",
	3 => "FILE_UNUSED",
	4 => "FILE_LAST",
	5 => "FILE_FIRST_AND_LAST",
};
my $FileChainTypeValue =
{
	"FILE_UNDEFINED" => 0,
	"FILE_FIRST" => 1,
	"FILE_MIDDLE" => 2,
	"FILE_UNUSED" => 3,
	"FILE_LAST" => 4,
	"FILE_FIRST_AND_LAST" => 5,
};

my $FILE_UNDEFINED = "FILE_UNDEFINED";
my $FILE_FIRST = "FILE_FIRST";
my $FILE_MIDDLE = "FILE_MIDDLE";
my $FILE_UNUSED = "FILE_UNUSED";
my $FILE_LAST = "FILE_LAST";
my $FILE_FIRST_AND_LAST = "FILE_FIRST_AND_LAST";

my $SaveMode = 
{
	0 => "SAVE_FULL",
	1 => "SAVE_COMMON",
};
my $SaveModeValue =
{
	"SAVE_FULL" => 0,
	"SAVE_COMMON" => 1,
};

my $SAVE_FULL = "SAVE_FULL";
my $SAVE_COMMON = "SAVE_COMMON";

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


#----------------------------------------------------------------------------
# Verify connection info
#----------------------------------------------------------------------------
if ( ($sHost eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	&usage();
}

if ( ($sPort ne "80") and ($sPort ne "8080") )
{
	$sProtocol = "https";
}
else
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

$ConfigSync = SOAP::Lite
	-> uri('urn:iControl:System/ConfigSync')
	-> readable(1)
	-> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $ConfigSync->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

&checkParameters(); 


#----------------------------------------------------------------------------
# Get Command Parameters 
#----------------------------------------------------------------------------
sub getParamsAndGo
{
	my $theCommandID = $_[0];
	if ( 1 eq $theCommandID )
	{
		print " Filename for configuration backup (empty for default): ";
		chomp ($configName = <STDIN>);
		if ( "" eq $configName )
		{
			$configName = generateConfigName();
		}
		$localFile = $sConfigName;

		print "Backing up configuration $configName\n";
	
		$success = &backupConfiguration($configName, $localFile, 1);
		if ( 1 == $success )
		{
			print "Backup succeeded\n";
		}
		else
		{
			print "Backup failed\n";
		}
         
	}
	elsif ( 2 eq  $theCommandID)
	{
		print " Config back up file to restore: ";
		chomp ($sConfigName = <STDIN>);
		print " Sync devices after install? (y/n): ";
		chomp ($sDoSync = <STDIN>);
		$sLocalFile = $sConfigName;
		$sSaveMode = "full";

		print "Restoring configuration $sLocalFile\n";
		$success = &restoreConfiguration($sLocalFile, $sDoSync, 1);
		if ( 1 == $success )
		{
			print "Restore succeeded\n";
		}
		else
		{
			print "Restore failed\n";
		}
	}
	elsif ( 3 eq $theCommandID )
	{
		usage();
	}
	else
	{
		print "Synching\n\n";
	}
}

#----------------------------------------------------------------------------
# Check Parameters 
#----------------------------------------------------------------------------
sub checkParameters
{
	if
	(
		("list" ne $sCOMMAND) and
		("checksum" ne $sCOMMAND) and
		("delete" ne $sCOMMAND) and
		("save" ne $sCOMMAND) and
		("install" ne $sCOMMAND) and
		("rollback" ne $sCOMMAND) and
		("download" ne $sCOMMAND) and
		("upload" ne $sCOMMAND) and
		("backup" ne $sCOMMAND) and
		("restore" ne $sCOMMAND) and
		("sync" ne $sCOMMAND)
	)
	{
		&usage();
	}
    
	if ( "list" eq $sCOMMAND )
	{
		&listConfigurations();
	}
    
	if ( "checksum" eq $sCOMMAND )
	{
		&checksumConfiguration($sArg1);
	}
    
	if ( "delete" eq $sCOMMAND )
	{
		&deleteConfiguration($sArg1);
	}
    
	if ( "save" eq $sCOMMAND )
	{
		if ( "" eq $sArg1 )
		{
			$sArg1 = generateConfigName();
		}
		&saveConfiguration($sArg1, &saveModeFromArg($sArg2));
	}
    
	if ( "install" eq $sCOMMAND )
	{
		&installConfiguration($sArg1);
	}
    
	if ( "rollback" eq $sCOMMAND )
	{
		&rollbackConfiguration();
	}
    
	if ( "download" eq $sCOMMAND )
	{
		&downloadConfiguration($sArg1, $sArg2);
	}

	if ( "upload" eq $sCOMMAND )
	{
		&uploadConfiguration($sArg1, $sArg2);
	}

	if ( "backup" eq $sCOMMAND )
	{
		$configName = generateConfigName();
		$localFile = $configName;

		print "Backing up configuration $configName\n";
	
		$success = &backupConfiguration($configName, $localFile, 1);
		if ( 1 == $success )
		{
			print "Backup succeeded\n";
		}
		else
		{
			print "Backup failed\n";
		}
	}

	if ( "restore" eq $sCOMMAND )
	{
		print "Restoring configuration $sArg1\n";
		$success = &restoreConfiguration($sArg1, 0, 1);
		if ( 1 == $success )
		{
			print "Restore succeeded\n";
		}
		else
		{
			print "Restore failed\n";
		}
	}

	if ( "sync" eq $sCOMMAND )
	{
		&syncConfiguration(&syncModeFromArg($sArg1));
	}
}

#----------------------------------------------------------------------------
# sub usage()
#----------------------------------------------------------------------------
sub usage()
{
	my ($subKey) = (@_);

	print "Usage: ConfigSync.pl host port uid pwd command [command_args]\n";
	print "    command\n";
	print "    --------\n";

	if ( ("" eq $subKey) or ("list" eq $subKey) )
	{
		print "    list\n";
		print "              Lists available configuration files on the server.\n";
		print "        Args: None\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("checksum" eq $subKey) )
	{
#		print "    checksum  config_name\n";
#		print "              Retrieves the checksum for the given configuration file.\n";
#		print "\n";
	}
	if ( ("" eq $subKey) or ("save" eq $subKey) )
	{
		print "    save      Creates a snapshot of the current configuration.\n";
		print "        Args: config_name [full | common]\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("install" eq $subKey) )
	{
		print "    install   Installs a given configuration file.\n";
		print "        Args: config_name\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("rollback" eq $subKey) )
	{
		print "    rollback  Performs a rollback to the last loaded configuration.\n";
		print "        Args: None\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("delete" eq $subKey) )
	{
		print "    delete    Deletes a given configuration file.\n";
		print "        Args: config_name\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("download" eq $subKey) )
	{
		print "    download  Downloads a given configuration file from the server.\n";
		print "        Args: config_name local_file\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("upload" eq $subKey) )
	{
		print "    upload    Uploads a file to the server from the client machine.\n";
		print "        Args: local_file config_name\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("sync" eq $subKey) )
	{
		print "    sync      Signals a configuration sync between HA devices.\n";
		print "        Args: [basic | running | all]\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("backup" eq $subKey) )
	{
		print "    backup    Saves configuration and downloads the configuration file.\n";
		print "        Args: None\n";
		print "\n";
	}
	if ( ("" eq $subKey) or ("restore" eq $subKey) )
	{
		print "    restore   Restores a configuration from the client machine.\n";
		print "        Args: local_file\n";
	}
	exit(1);
}

#============================================================================
#
# Helper Methods
#
#============================================================================

#----------------------------------------------------------------------------
# sub generateConfigName
#----------------------------------------------------------------------------
sub generateConfigName()
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$sName = sprintf("%s-%04d%02d%02d_%02d%02d%02d.ucs", $sHost, $year, $mon, $mday, $hour, $min, $sec);
	return $sName;
}

#----------------------------------------------------------------------------
# sub saveModeFromArg
#----------------------------------------------------------------------------
sub saveModeFromArg()
{
	my $sSaveModeArg = @_;
	my $sSaveMode = $SAVE_FULL;

	if ( ("full" ne $sSaveModeArg) and ("common" ne $sSaveModeArg) )
	{
		$sSaveModeArg = "full";
	}

	if ( "full" eq $sSaveModeArg )
	{
		$sSaveMode = $SAVE_FULL;
	}
	else
	{
		$sSaveMode = $SAVE_COMMON;
	}
	return $sSaveMode;
}

#----------------------------------------------------------------------------
# syncModeFromArg
#----------------------------------------------------------------------------
sub syncModeFromArg()
{
	my $sSyncModeArg = @_;
	my $sSyncMode = $CONFIGSYNC_ALL;

	if ( ("basic" ne $sSyncModeArg) and ("running" ne $sSyncModeArg) and ("all" ne $sSyncModeArg) )
	{
		$sSyncModeArg = "all";
	}
	
	if ( "all" eq $sSyncModeArg )
	{
		$sSyncMode = $CONFIGSYNC_ALL;
	}
	if ( "basic" eq $sSyncModeArg )
	{
		$sSyncMode = $CONFIGSYNC_BASIC;
	}
	if ( "running" eq $sSyncModeArg )
	{
		$sSyncMode = $CONFIGSYNC_RUNNING;
	}

	return $sSyncMode;
}


#============================================================================
#
# Command Methods
#
#============================================================================

#----------------------------------------------------------------------------
# sub listConfigurations
#----------------------------------------------------------------------------
sub listConfigurations()
{
	$soap_response = $ConfigSync->get_configuration_list();
	if ( $soap_response->fault )
	{
		print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
	}
	else
	{
		my @ConfigFileEntryList = @{$soap_response->result};
		print "Available Configurations:\n";
		my $configNumber = 0;
		foreach my $ConfigFileEntry (@ConfigFileEntryList)
		{
			print "    (",
				substr($ConfigFileEntry->{"file_datetime"}, 0, -1),
				") : '",
				$ConfigFileEntry->{"file_name"},
				"'\n";
			$configNumber++;
		}
	}
}

#----------------------------------------------------------------------------
# sub checksumConfiguration
#----------------------------------------------------------------------------
sub checksumConfiguration()
{
	my ($configName, $quiet) = (@_);
	my $success = 0;

	if ( "" eq $configName )
	{
		&usage("checksum");
	}

	eval
	{
		$soap_response = $ConfigSync->get_configuration_checksum
		(
			SOAP::Data->name(filename => $configName)
		);
	};

	if ( $soap_response and $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		$checksum = $soap_response->result;
		if ( 1 != $quiet )
		{
			print "Configuration '$sConfigName' checksum: '$checksum'\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub deleteConfiguration
#----------------------------------------------------------------------------
sub deleteConfiguration()
{
	my ($configName, $quiet) = (@_);
	my $success = 0;

	if ( "" eq $configName )
	{
		&usage("delete");
	}
	
	eval
	{
		$soap_response = $ConfigSync->delete_configuration
		(
			SOAP::Data->name(filename => $configName)
		);
	};

	if ( $soap_response and $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		if ( 1 != $quiet )
		{
			print "Configuration '$configName' deleted successfully!\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub saveConfiguration
#----------------------------------------------------------------------------
sub saveConfiguration()
{
	my ($configName, $saveMode, $quiet) = (@_);
	my $success = 0;

	if ( ("" eq $configName) or ("" eq $saveMode) )
	{
		&usage("save");
	}

	$soap_response = $ConfigSync->save_configuration
	(
		SOAP::Data->name(filename => $configName),
		SOAP::Data->name(save_flag => $saveMode)
	);
	if ( $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		if ( 1 != $quiet )
		{
			print "Configuration '$configName' saved successfully!\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub installConfiguration
#----------------------------------------------------------------------------
sub installConfiguration()
{
	my ($configName, $quiet) = (@_);
	my $success = 0;

	if ( "" eq $configName )
	{
		&usage("install");
	}

	eval
	{
		$soap_response = $ConfigSync->install_configuration
		(
			SOAP::Data->name(filename => $configName)
		);
	};

	if ( $soap_response and $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		if ( 1 != $quiet )
		{
			print "Configuration '$configName' installed successfully!\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub rollbackConfiguration
#----------------------------------------------------------------------------
sub rollbackConfiguration()
{
	my ($quiet) = (@_);
	my $success = 0;

	eval
	{
		$soap_response = $ConfigSync->rollback_configuration();
	};

	if ( $soap_response and $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		if ( 1 != $quiet )
		{
			print "Configuration rollback successful!\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub downloadConfiguration
#----------------------------------------------------------------------------
sub downloadConfiguration()
{
	my ($configName, $localFile, $quiet) = (@_);
	$success = 0;

	if ( "" eq $localFile )
	{
		$localFile = $configName;
	}

	if ( "" eq $configName )
	{
		&usage("download");
	}

	open (LOCAL_FILE, ">$localFile") or die("Can't open $localFile for output: $!");
	binmode(LOCAL_FILE);

	my $file_offset = 0;
	my $chunk_size = $defaultChunkSize;
	my $chain_type = $FILE_UNDEFINED;
   	my $bContinue = 1;

   	print "\n";
	while ( 1 == $bContinue )
	{
		$soap_response = $ConfigSync->download_configuration
		(
			SOAP::Data->name(config_name => $configName),
			SOAP::Data->name(chunk_size => $chunk_size),
			SOAP::Data->name(file_offset => $file_offset)
		);

		if ( $soap_response->fault )
		{
			if ( 1 != $quiet )
			{
				print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
			}
			$bContinue = 0;
		}
		else
		{
			$FileTransferContext = $soap_response->result;
			$file_data = $FileTransferContext->{"file_data"};
			$chain_type = $FileTransferContext->{"chain_type"};
			@params = $soap_response->paramsout;
			$file_offset = @params[0];

			# Append Data to File
			print LOCAL_FILE $file_data;

#			if ( 1 != $quiet )
#			{
				print "Bytes Transferred: $file_offset\n";
#			}

			if ( ("FILE_LAST" eq $chain_type) or
			     ("FILE_FIRST_AND_LAST" eq $chain_type) )
			{
				$bContinue = 0;
				$success = 1;
			}
		}
	}
	print "\n";

	close(LOCAL_FILE);

	return $success;
}

#----------------------------------------------------------------------------
# sub uploadConfiguration
#----------------------------------------------------------------------------
sub uploadConfiguration()
{
	my ($localFile, $configName, $quiet) = (@_);
	$success = 0;

	if ( "" eq $configName )
	{
		$configName = $localFile;
	}

	if ( "" eq $localFile )
	{
		&usage("upload");
	}

	$bContinue = 1;
	$chain_type = $FILE_FIRST;
	$preferred_chunk_size = $defaultChunkSize;
	$chunk_size = $defaultChunkSize;
	$total_bytes = 0;

	open(LOCAL_FILE, "<$localFile") or die("Can't open $localFile for input: $!");
	binmode(LOCAL_FILE);

	while (1 == $bContinue )
	{
		$file_data = "";
		$bytes_read = read(LOCAL_FILE, $file_data, $chunk_size);

		if ( $preferred_chunk_size != $bytes_read )
		{
			if ( $total_bytes == 0 )
			{
				$chain_type = $FILE_FIRST_AND_LAST;
			}
			else
			{
				$chain_type = $FILE_LAST;
			}
			$bContinue = 0;
		}
		$total_bytes += $bytes_read;

		$FileTransferContext =
		{
			file_data => SOAP::Data->type(base64 => $file_data),
			chain_type => $chain_type
		};


		$soap_response = $ConfigSync->upload_configuration
		(
			SOAP::Data->name(config_name => $configName),
			SOAP::Data->name(file_context => $FileTransferContext)
		);

		if ( $soap_response->fault )
		{
#			if ( 1 != $quiet )
#			{
				print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
#			}
			$success = 0;
			$bContinue = 0;
		}
		else
		{
#			if ( 1 != $quiet )
#			{
				print "Uploaded $total_bytes bytes\n";
#			}
			$success = 1;
		}

		$chain_type = $FILE_MIDDLE;
	}
	print "\n";

	close(LOCAL_FILE);

	return $success;
}

#----------------------------------------------------------------------------
# sub syncConfiguration
#----------------------------------------------------------------------------
sub syncConfiguration()
{
	my ($syncFlag, $quiet) = (@_);
	my $success = 0;

	if ( "" eq $syncFlag )
	{
		&usage("sync");
	}

	$soap_response = $ConfigSync->synchronize_configuration
	(
		SOAP::Data->name(sync_flag => $syncFlag)
	);
	if ( $soap_response->fault )
	{
		if ( 1 != $quiet )
		{
			print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
		}
	}
	else
	{
		$success = 1;
		if ( 1 != $quiet )
		{
			print "Configuration synchronized successfully!\n";
		}
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub backupConfiguration
#----------------------------------------------------------------------------
sub backupConfiguration()
{
	my ($configName, $localFile, $quiet) = (@_);

	if ( "" eq $configName )
	{
		$configName = generateConfigName();
	}
	if ( "" eq $localFile )
	{
		$localFile = $configName;
	}

	if ( ("" eq $configName) or ("" eq $localFile) )
	{
		&usage("backup");
	}

	sleep(1);
	$success = &saveConfiguration($configName, $SAVE_FULL, $quiet);
	if ( 1 == $success )
	{
		sleep(1);
		$success = &downloadConfiguration($configName, $localFile, $quiet);
		if ( 1 == $success )
		{
			if ( 1 != $quiet )
			{
				print "Configuration file $configName successfully backed up.\n";
			}
		}
		sleep(1);
		$success = &deleteConfiguration($configName, $quiet);
	}
	return $success;
}

#----------------------------------------------------------------------------
# sub restoreConfiguration
#----------------------------------------------------------------------------
sub restoreConfiguration()
{
	my ($localFile, $doSync, $quiet) = (@_);

	$configName = $localFile;

	if ( ("" eq $configName) or ("" eq $localFile) )
	{
		&usage("restore");
	}

	sleep(1);
	$success = &uploadConfiguration($localFile, $configName, $quiet);
	if ( 1 == $success )
	{
		sleep(1);
		$success = &installConfiguration($configName, $quiet);
		if ( 1 == $success )
		{
			if ( ("1" eq $doSync) or ("y" eq $doSync) or ("Y" eq $doSync) )
			{
				# Give server time to recover from restart.
				sleep(5);
				&syncConfiguration(&syncModeFromArg("all"), $quiet);
			}
		}
		sleep(1);
		&deleteConfiguration($configName, $quiet);
	}
	return $success;
}

