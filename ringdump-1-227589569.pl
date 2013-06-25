#!/usr/bin/perl
## VERSION v0.9b

#use strict;



###################iControl part############
###########################################

use SOAP::Lite;
use MIME::Base64;

BEGIN {push (@INC, "/var/tmp"); }
use iControlTypeCast;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = '127.0.0.1';
my $sPort = '443';
my $sUID = $ARGV[0];
my $sPWD = $ARGV[1];
my $sPool = $ARGV[2];
my $sProtocol = "https";
my $stat = '/var/tmp/poolstat.txt';


if ( ("80" eq $sPort) or ("8080" eq $sPort) )
{
        $sProtocol = "http";
}

if ( ($sUID eq "") or ($sPWD eq "") or ($sPool eq "") )
{
        die ("Usage: $0 <admin_user> <admin_password> <pool_name>\n");
}

open(my $fh, '>>', "$stat") or die $!;

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
        return "$sUID" => "$sPWD";
}

$Pool = SOAP::Lite
        -> uri('urn:iControl:LocalLB/Pool')
        -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
eval { $Pool->transport->http_request->header
(
        'Authorization' =>
                'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

$PoolMember = SOAP::Lite
        -> uri('urn:iControl:LocalLB/PoolMember')
        -> proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");
$PoolMember->transport->http_request->header
(
        'Authorization' =>
                'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
);



#----------------------------------------------------------------------------
# checkResponse
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

#----------------------------------------------------------------------------
# getAllPoolInfo
#----------------------------------------------------------------------------
sub getAllPoolInfo()
{
        $soapResponse = $Pool->get_list();
        &checkResponse($soapResponse);
        my @pool_list = @{$soapResponse->result};

        &getPoolInfo(@pool_list);
}
#----------------------------------------------------------------------------
# getPoolInfo
#----------------------------------------------------------------------------
sub getPoolInfo()
{
        my @pool_list = @_;

        # Get LBMethods
        $soapResponse = $Pool->get_lb_method
        (
                SOAP::Data->name(pool_names => [@pool_list])
        );
        &checkResponse($soapResponse);
        my @lb_methods = @{$soapResponse->result};

        # Get min/cur active members
        $soapResponse = $Pool->get_minimum_active_member
        (
                SOAP::Data->name(pool_names => [@pool_list])
        );
        &checkResponse($soapResponse);
        my @min_active_members = @{$soapResponse->result};

        $soapResponse = $Pool->get_active_member_count
        (
                SOAP::Data->name(pool_names => [@pool_list])
        );
        &checkResponse($soapResponse);
        my @cur_member_list = @{$soapResponse->result};

        # Get Pool Statistics
        foreach $pool (@pool_list)
        {
                $soapResponse = $Pool->get_statistics
                (
                        SOAP::Data->name(pool_names => [$pool])
                );
                &checkResponse($soapResponse);
                $pool_stats = $soapResponse->result;
                push @PoolStatisticsEntryList, @{$pool_stats->{"statistics"}};
        }
        print "\n";

        # Get Member Statistics
        foreach $pool (@pool_list)
        {
                $soapResponse = $PoolMember->get_all_statistics
                (
                        SOAP::Data->name(pool_names => [$pool])
                );
                &checkResponse($soapResponse);
                push @member_stats, @{$soapResponse->result}
        }
        print "\n";

        # Process Data
        $i = 0;
        my $time = localtime;
        print $fh "$time\n";
        foreach $pool_name (@pool_list)
        {
                print $fh "POOL $pool_name  ";
                print $fh "LB_METHOD @lb_methods[$i] ";
                print $fh "MIN/CUR ACTIVE MEMBERS: @min_active_members[$i]/@cur_member_list[$i]\n";

                foreach $PoolStatisticsEntry (@PoolStatisticsEntryList)
                {
                        $poolName = $PoolStatisticsEntry->{"pool_name"};
                        if ( $poolName eq $pool_name )
                        {
                                @statistics = @{$PoolStatisticsEntry->{"statistics"}};

                                foreach $stat (@statistics)
                                {
                                        $type = $stat->{"type"};
                                        $value = $stat->{"value"};
                                        $low  = $value->{"low"};
                                        $high  = $value->{"high"};
                                        $value64 = ($high<<32)|$low;
                                        $time_stamp = $statistics->{"time_stamp"};
                                        print $fh "|    $type : $value64\n" if ( $type eq 'STATISTIC_SERVER_SIDE_CURRENT_CONNECTIONS'
                                                                                        || $type eq 'STATISTIC_SERVER_SIDE_MAXIMUM_CONNECTIONS'
                                                                                        || $type eq 'STATISTIC_SERVER_SIDE_TOTAL_CONNECTIONS' ) ;
                                }
                        }
                }

                $MemberStatistics = @member_stats[$i];

                @MemberStatisticsEntryList = @{$MemberStatistics->{"statistics"}};
                $MemberStatisticsTimeStamp = $MemberStatistics->{"time_stamp"};

                foreach $MemberStatisticEntry (@MemberStatisticsEntryList)
                {
                        $member = $MemberStatisticEntry->{"member"};
                        $address = $member->{"address"};
                        $port = $member->{"port"};
                        print $fh "+-> MEMBER $address:$port\n";

                        @StatisticList = @{$MemberStatisticEntry->{"statistics"}};
                        foreach $stat (@StatisticList)
                        {
                                $type = $stat->{"type"};
                                $value = $stat->{"value"};
                                $low  = $value->{"low"};
                                $high  = $value->{"high"};
                                $value64 = ($high<<32)|$low;
                                $time_stamp = $stat->{"time_stamp"};

                                print $fh "    |    $type : $value64\n" if ( $type eq 'STATISTIC_SERVER_SIDE_CURRENT_CONNECTIONS'
                                                                                        || $type eq 'STATISTIC_SERVER_SIDE_MAXIMUM_CONNECTIONS'
                                                                                        || $type eq 'STATISTIC_SERVER_SIDE_TOTAL_CONNECTIONS' ) ;
                        }
                }

                $i++;
        }
}



##############iControl part end##############


#my $zero_vlan = "0.0:nnn";
my $zero_vlan = "dummy:nnn";
#my $zero_filter = "host ( 10.1.72.169 or 10.2.72.139 ) and port ( 20 or 21 )";
my $zero_filter = "dummy filter";
################
# tcpdump settings
##########

my %SETTINGS   = (
      $zero_vlan => { filter => $zero_filter },
);

my $SNAPLEN = 0;

################
# script settings
######

# free space checking
my $FREE_SPACE_CHECK_INTERVAL = 1;   # check free space every this number of seconds
my $MIN_FREE_SPACE            = 5;   # minimum percent space left on parition
#my $CAPTURE_LOCATION          = $ARGV[0];
my $CAPTURE_LOCATION          = '/var/tmp';

# file rotation settings
my $CAPTURES_TO_ROTATE        = 5;   # tcpdump capture files to rotate
my $DESIRED_CAPTURE_SIZE      = 200;   # megabytes per capture file before rotating
my $OVERLAP_DURING_ROTATE     = 5;   # seconds to overlap previous capture while starting a new one
my $CAPTURE_CHECK_INTERVAL    = 1;   # how often (seconds) to check the size of capture files for rotating

# trigger settings - time (run tcpdumps for x seconds)
#my $TRIGGER                  = "time-based";
my $TIME_TO_CAPTURE           = 300;

# trigger settings - log-message (stop tcpdump when log message is received)
my $TRIGGER                   = "log-message based";
my $LOG_FILE                  = "/var/log/ltm";
#my $LOG_MESSAGE               = "Interface 0\\.\\d+: HSB DMA lockup on transmitter failure";
my $LOG_MESSAGE               = "RST sent from .*? No available pool member";
my $FOUND_MESSAGE_WAIT        = 5;   # how many seconds to gather tcpdumps after we match the log message

# misc
my $IDLE_TIMER                = 5;      # if ! receiving log entries, how long before checking if log is rotated
my $MAX_ROTATED_LINES         = 10000;  # max lines to read from file we're re-reading because it's been rotated
my $PID_FILE                  = "/var/run/ring_dump.pid";
my $DEBUG                     = 0;      # 0/1




####################################################
# END OF THINGS THAT SHOULD NEED TO BE CONFIGURED
####################################################



########
# set defaults
###

$SNAPLEN                   ||= 0;
$TRIGGER                   ||= "time";
$CAPTURE_LOCATION          ||= "/var/tmp";
$TIME_TO_CAPTURE           ||= 60;
$FREE_SPACE_CHECK_INTERVAL ||= 5;
$CAPTURES_TO_ROTATE        ||= 3;
$DESIRED_CAPTURE_SIZE      ||= 10;
$OVERLAP_DURING_ROTATE     ||= 5;
$CAPTURE_CHECK_INTERVAL    ||= 5;
$MIN_FREE_SPACE            ||= 5;
$LOG_FILE                  ||= "/var/log/messages";
$LOG_MESSAGE               ||= "FAILED";
$FOUND_MESSAGE_WAIT        ||= 5;
$IDLE_TIMER                ||= 5;
$PID_FILE                  ||= "/var/run/ring_dump.pid";
$DEBUG                     ||= 0;


unless (-d $CAPTURE_LOCATION) {
   print "$CAPTURE_LOCATION isn't a directory, using /mnt instead\n\n";
   $CAPTURE_LOCATION = "/mnt";
}


if (! -r $LOG_FILE) {
   die "Can't read \"$LOG_FILE\", EXIT\n";
}

# insert code to find tcpdump instead of relying on path HERE:

my $tcpdump = "/usr/sbin/tcpdump";


######
# misc global variable declaration
##########

my($answer, $interface, $pid, $tail_child, $F_LOG);
my($current_size, $current_inode, $last_size, $last_inode);

my @child_pids;
my $ppid          = $$;
my $min_megabytes = $CAPTURES_TO_ROTATE * $DESIRED_CAPTURE_SIZE;

$current_size = $current_inode = $last_size = $last_inode = 0;
$|++;


###########
# functions
#######


# exit function that does does necessary child handling

sub finish {
   $_ = shift();
   if (defined($_) && $_ ne "") {
   print;
   }

   foreach $interface (keys( %SETTINGS )) {
   push(@child_pids, $SETTINGS{$interface}{pid});
   }

   $DEBUG && print "INTERRUPT: sending SIGINT and SIGTERM to: ", join(" ", @child_pids), "\n";
   kill(2, @child_pids);
   sleep(1);
   kill(15, @child_pids);
   $DEBUG && print "INTERRUPT: done, unlink pidfile and exit\n";

   unlink($PID_FILE);
   exit(0);
}

$SIG{INT}  = sub { finish(); };


# report usage on CAPTURE_LOCATION's MB free from df

sub free_megabytes {
   my $partition = shift();
   $partition  ||= $CAPTURE_LOCATION;

   my $free_megabytes;

   $DEBUG && print "free_megabytes(): capture partition is $partition\n";

   open(DF, "df -P $partition|");

   # discard the first line;
   $_ = <DF>;

   # parse the usage out of the second line
   $_ = <DF>;
   $free_megabytes = (split)[3];
   $free_megabytes = int($free_megabytes / 1024);

   close(DF);

   $DEBUG && print "free_megabytes(): finished reading df, output is: $free_megabytes\n";

   $free_megabytes;
}


# report usage on CAPTURE_LOCATION's % usage from df

sub free_percent {
   my $partition = shift();
   $partition  ||= $CAPTURE_LOCATION;

   my $free_percent;

   $DEBUG && print "free_percent(): capture partition is $partition\n";

   open(DF, "df -P $partition|");

   # discard the first line;
   $_ = <DF>;

   # parse the usage out of the second line
   $_ = <DF>;
   $free_percent = (split)[4];
   chop($free_percent);  ## chop off '%'
   $free_percent = (100 - $free_percent);

   close(DF);

   $DEBUG && print "free_percent(): finished reading df, output is: $free_percent\n";

   $free_percent;
}


# simple sub to send SIGHUP to syslogd

sub restart_syslogd () {
   if (-f "/var/run/syslog.pid") {
   open(PIDFILE, "</var/run/syslog.pid");
   } elsif (-f "/var/run/syslogd.pid") {
   open(PIDFILE, "</var/run/syslogd.pid");
   } elsif (-f "/var/run/syslog-ng.pid") {
   open(PIDFILE, "</var/run/syslog-ng.pid");
   } else {
   print "restart_syslogd(): couldn't find pid file\n";
   }

   if (!defined(fileno(PIDFILE)) ) {
   print "FAILED to send SIGHUP to syslogd\n";
   return 0;
   }

   $_ = <PIDFILE>;
   chomp;

   kill(1, ($_));

   1;
}


# simple wrapper to start tcpdumps, assuming obvious globals

sub start_tcpdump {
   my $interface    = shift();
   my $capture_file = shift();
   my $filter       = shift();

   my @cmd = ("$tcpdump", "-s$SNAPLEN", "-i$interface", "-w$capture_file");
   # Add a filter, if specified ('' is treated as a wide-open capture)
   if ($filter ne '') {
      push @cmd, "$filter";
   }
 
   $DEBUG || open(STDERR, ">/dev/null");
   $DEBUG && print "start_tcpdump(): about to start: ", join(" ", @cmd), "\n";
   print "tcpdump command: @cmd\n";
   exec($cmd[0], @cmd[1..$#cmd]) ||
   print "start_tcpdump(): FAILED to start: ", join(" ", @cmd), ", command not found\n";
   $DEBUG || close(STDERR);

   exit(1);
}


# sub to see how much space a given capture file is using (to decide to rotate or not)

sub capture_space ($) {
   my $capture_file = shift();
   my $size         = ( stat($capture_file) )[7];

   $DEBUG && print "capture_space(): size of $capture_file is $size\n";

   # return size of argument in megabytes, but don't divide by zero
   if ($size == 0) {
   return 0;
   } else {
   return ($size / 1048576);
   }
}


# gives user the option to create a MFS

sub create_mfs () {
   if (-d $CAPTURE_LOCATION) {
   $DEBUG && print "create_mfs(): directory $CAPTURE_LOCATION exists\n";
   } else {
   mkdir($CAPTURE_LOCATION, oct(0755)) || die "FAILED to create $CAPTURE_LOCATION\n";
   print "Capture directory ($CAPTURE_LOCATION) did not exist, so it was created\n";
   }

   # figure out the partition CAPTURE_LOCATION is on.  This is cheap... fixme
   my $partition = $CAPTURE_LOCATION;
   $partition    =~ s!(/[A-z0-9]*)/{0,1}.*!$1!g;

   open(MOUNT, "mount|") || die "FAILED to run \"mount\": !$\n";
   while (<MOUNT>) {
   next unless ((split())[2] =~ /^$partition$/);

   $DEBUG && print "create_mfs(): partition: $partition is already mounted, return\n";

   # return 1 if it's already mounted
   return 1;
   }
   close(MOUNT);

   print "Mount a Memory File System (MFS) on ${CAPTURE_LOCATION}?  [y/n]: ";

   my $answer = <STDIN>;

   if (lc($answer) =~ "y") {
   print "Enter size of MFS in blocks (200000 = 100M), or just press enter for 100M: ";

   chomp (my $mfs_size = <STDIN>);
   $mfs_size = 200000 if ($mfs_size eq "");

   print "Allocating $mfs_size blocks to $CAPTURE_LOCATION for MFS\n";
   system("mount_mfs -s $mfs_size $CAPTURE_LOCATION");

   if (($? >> 8) != 0) {
      print "an error occurring trying to mount the MFS filesystem, exit status: $?\n";
      0;
   } else {
      print "MFS file system established\n\n";
      1;
   }
   }
}


sub fork_to_background ($) {
   my $cmd = shift();

   my $pid = fork();

   if ($pid == 0) {
        exec($cmd) || die "exec() failed: $!\n";
   } else {
        return($pid);
   }
}


sub popen_read ($) {
   my $cmd   = shift();
   my $child;

   $DEBUG && print "Background: \"$cmd\"\n";

   pipe(READLOG, WRITELOG);
   select(READLOG); $|++; select(WRITELOG); $|++; select(STDOUT);

   ## dup STDOUT and STDERR
   open(T_STDOUT, ">&STDOUT");
   open(T_STDERR, ">&STDERR");

   ## redir STDOUT to pipe for child
   open(STDOUT, ">&WRITELOG");
   open(STDERR, ">&WRITELOG");

   $child = fork_to_background($cmd);

   ## close STDOUT, STDERR and FILE
   close(STDOUT); close(STDERR);

   ## re-open STDOUT as normal and close dup
   open(STDOUT, ">&T_STDOUT"); close(T_STDOUT);
   open(STDERR, ">&T_STDERR"); close(T_STDERR);

   return($child, \*READLOG);
}


sub open_log ($$) {
   my $LOG_FILE = shift();
   my $lines    = shift();

   if (defined($F_LOG) && defined(fileno($F_LOG)) ) {
        $DEBUG && print "Killing child before closing LOG\n";
        kill(15, $tail_child);
        waitpid($tail_child, 0);

        $DEBUG && print "Closing LOG\n";
        close($F_LOG);
   }

   $DEBUG && print "Opening \"$LOG_FILE\"\n";

   ($tail_child, $F_LOG) = popen_read("tail -n $lines -f $LOG_FILE");
   push(@child_pids, $tail_child);

   1;
}


## check to see if log is rotated, returns true if rotated

sub is_rotated ($) {
   my $LOG_FILE = shift();
   
   $DEBUG && print "enter is_rotated()\n";
   
   ($current_inode, $current_size) = (stat($LOG_FILE))[1,7];
   
   if (($last_size != 0) && ($last_size > $current_size)) {
        $DEBUG && print "File is now smaller.  File must have been rotated\n";
        $last_size  = $current_size;
        $last_inode = $current_inode;
       
        open_log($LOG_FILE, $MAX_ROTATED_LINES) || die "open_log $LOG_FILE failed: $!\n";
        return(1);
       
   } elsif (($last_inode != 0) && ($last_inode != $current_inode)) {
        $DEBUG && print "Inode changed.  File must have been rotated\n";
        $last_inode = $current_inode;
        $last_size  = $current_size;
       
        open_log($LOG_FILE, $MAX_ROTATED_LINES) || die "open_log $LOG_FILE failed: $!\n";
        return(1);
       
   }

   ($last_inode, $last_size) = ($current_inode, $current_size);

   0;
}


sub rstCause {
  my $flag = shift;
  if ( $flag ) {
    print "turned on reset cause!\n\n";
    my $cmd = "/usr/bin/tmsh modify sys db tm.rstcause.log value \"enable\" ";
    system($cmd);
  } else {
    print "turned off reset cause\n\n";
    my $cmd = "/usr/bin/tmsh modify sys db tm.rstcause.log value \"disable\" ";
    system("$cmd");
  }
}


###########
# MAIN
########


if (free_megabytes() < $min_megabytes) {
   print "free space on $CAPTURE_LOCATION is below ${min_megabytes}MB, you must create a Memory File System or choose another location to gather tcpdumps\n";
   goto MUST_MFS;
}

######### GET USER INPUT ###############

if (free_percent() < $MIN_FREE_SPACE) {
   print "free space on $CAPTURE_LOCATION is below ${MIN_FREE_SPACE}%, you must create a Memory File System or choose another location to gather tcpdumps\n";

MUST_MFS:
   # require the user to create a MFS if they don't have enough free space
   exit(1) unless (create_mfs());
} else {
   create_mfs();
}

if (free_percent() < $MIN_FREE_SPACE || free_megabytes() < $min_megabytes) {
   print "it appears the Memory File System is in place, but there is still insufficient space, exiting\n";
   exit(1);
}

rstCause(1);

print "capturing to $CAPTURE_LOCATION using the following interfaces and filters:\n";



foreach $interface (keys( %SETTINGS )) {
   $interface =~ /^([^:]+)/o;
   my $noiseless_interface = $1;

   # If it wasn't "0.0", ensure it's a valid interface
   # 'any' is purposefully not supported here.
   if ($noiseless_interface ne '0.0') {
      system("ifconfig $noiseless_interface >/dev/null 2>&1");

      if ( ($? >> 8) != 0) {
         print "couldn't ifconfig $noiseless_interface, removing from list\n";
         delete( $SETTINGS{$interface} );
         next;
      }
   }
   print "   $interface: '$SETTINGS{$interface}{filter}'\n";
}

print "does this look right?  [y/n]: ";

$answer = <STDIN>;
exit unless lc($answer) =~ "y";



####### DAEMONIZE #############
chdir("/");
exit unless (fork() == 0);
    
    
# kill old self, write pid file
if (-f $PID_FILE) {
   open(PIDFILE, "<$PID_FILE");
   kill(15, <PIDFILE>);
   close(PIDFILE);
}

open(PIDFILE, ">$PID_FILE");
syswrite(PIDFILE, $$);
close(PIDFILE);



########### START PROCESSING ###############

foreach $interface (keys( %SETTINGS )) {
   my $filter = $SETTINGS{$interface}{filter};
   $pid       = fork();
   $SETTINGS{$interface}{rotate_number} = 1;

   if (!defined($pid)) {
   print "fork() failed! exiting\n";
   exit 1;
   }

   if ($pid == 0) {

=for head

   start_tcpdump(
      $interface,
      "$CAPTURE_LOCATION/${interface}.dump.$SETTINGS{$interface}{rotate_number}",
      $filter
   );

=cut

   exit 1;
   } else {
   $SETTINGS{$interface}{pid} = $pid;
   print "started tcpdump as pid $pid on \"$interface\" filtered as \"$filter\"\n";
   }
}



######
# fork off a process to keep an eye on free space
########

$pid  = fork();

if ($pid == 0) {
   while (1) {
   my $sleep_return = sleep($FREE_SPACE_CHECK_INTERVAL);
   $DEBUG && ($sleep_return != $FREE_SPACE_CHECK_INTERVAL) && print "WARN: free_percent() loop: sleep returned $sleep_return instead of $FREE_SPACE_CHECK_INTERVAL !\n";

   if (free_percent() < $MIN_FREE_SPACE) {
      print "WARN: free space is below ${MIN_FREE_SPACE}%, killing main script\n";

      kill(2, $ppid);
      sleep(1);
      kill(15, $ppid);

      print "WARN: sent SIGTERM to $ppid (main script), exiting\n";
      exit 1;
   } else {
      $DEBUG && print "free_percent(): space is fine, continue\n";
   }
   }
} else {
   push(@child_pids, $pid);
   $DEBUG && print "started free_percent watcher as: $pid\n";
}


######
# fork off a process to rotate capture files as necessary
########

$pid  = fork();

if ($pid == 0) {
   my $capture_file;

   while (1) {
   my $sleep_return = sleep($CAPTURE_CHECK_INTERVAL);
   $DEBUG && ($sleep_return != $CAPTURE_CHECK_INTERVAL) && print "WARN: start_tcpdump() loop: sleep returned $sleep_return instead of $CAPTURE_CHECK_INTERVAL !\n";

   foreach $interface (keys( %SETTINGS )) {
      if (capture_space("$CAPTURE_LOCATION/${interface}.dump.$SETTINGS{$interface}{rotate_number}") >= $DESIRED_CAPTURE_SIZE) {

      if ($SETTINGS{$interface}{rotate_number} == $CAPTURES_TO_ROTATE) {
         print "reached maximum number of captures to rotate: $CAPTURES_TO_ROTATE, starting over at 1\n";
         $SETTINGS{$interface}{rotate_number} = 1;
      } else {
         $SETTINGS{$interface}{rotate_number}++;
      }

      print "rotating capture file: ${interface}.dump, new extension .$SETTINGS{$interface}{rotate_number}\n";

      $pid = fork();

      if ($pid == 0) {


         start_tcpdump(
         $interface,
         "$CAPTURE_LOCATION/${interface}.dump.$SETTINGS{$interface}{rotate_number}",
         $SETTINGS{$interface}{filter},
         );


         exit 0;
      }
      push(@child_pids, $pid);

      # get some overlap in the two files
      sleep($OVERLAP_DURING_ROTATE);

      # kill the old tcpdump
      kill(2, $SETTINGS{$interface}{pid});
      $DEBUG && print "sent SIGINT to $interface: $SETTINGS{$interface}{pid}, new pid $pid\n";

      # record the new pid
      $SETTINGS{$interface}{pid} = $pid;
      } else {
      $DEBUG && print "capture file doesn't need to be rotated yet: ${interface}.dump\n";
      }
   }

   # Reap any zombies from old tcpdumps
   $DEBUG && print "start_tcpdump() loop: \@child_pids = (", join(' ', @child_pids), ")\n";
   while (1) {
      use POSIX ":sys_wait_h";
      my $child = waitpid(-1, WNOHANG);
      if (defined $child and $child > 0) {
          # remove PID from @child_pids
          @child_pids = grep {$_ != $child} @child_pids;
          $DEBUG && print "start_tcpdump() loop: reaped child PID $child\n";
      } else {
          # no one to reap
          last;
      }
   }
   }
} else {
   push(@child_pids, $pid);
   $DEBUG && print "started capture file watcher as: $pid\n";
}


################
# watch triggers (time or log based)
####################

$SIG{TERM} = sub { finish(); };

if (lc($TRIGGER) =~ /time/) {
   print "time-based trigger, will capture for $TIME_TO_CAPTURE seconds\n";

   sleep($TIME_TO_CAPTURE);

   print "captured for $TIME_TO_CAPTURE seconds, stopping tcpdumps\n";

} elsif (lc($TRIGGER) =~ /log/) {
   print "log-based trigger, waiting for \"$LOG_MESSAGE\" in \"$LOG_FILE\"\n";

   # creates global $F_LOG filehandle of $LOG_FILE
   open_log($LOG_FILE, 0) || finish("open_log $LOG_FILE failed: $!\n");

   # flush syslogd's buffers (avoid never getting the message due to "last message repeated....")
   restart_syslogd() || finish("Restarting syslogd failed, EXIT\n");

   # tail -f the log and wait for message
   while (1) {
   # reap any zombies during each loop
   my $return;

   while (1) {
      use POSIX ":sys_wait_h";
      my $child = waitpid(-1, WNOHANG);
      if (defined $child and $child > 0) {
          $DEBUG && print "log trigger loop: reaped child PID $child\n";
      } else {
          # no one to reap
          last;
      }
   }

   eval {
      $SIG{ALRM} = sub { die("ALRM\n"); };
           
      alarm($IDLE_TIMER);
      $_ = <$F_LOG>;
      alarm(0);
   };
        
   if ($@) {
      # this only occurs if we're idle for $IDLE_TIMER seconds because no new log entries are occuring
           
      $@ = undef;
      is_rotated($LOG_FILE);
           
      next;
   }
        
   $DEBUG && print "in LOG reading loop, current line: \"$_\"\n";

   if (/$LOG_MESSAGE/) {
      $DEBUG && print "Current line matches: \"$LOG_MESSAGE\"\n";

      last;
   }
        
   $DEBUG && print "no match, next\n";
   }

   print "received log message, sleeping $FOUND_MESSAGE_WAIT seconds then stopping tcpdumps and write pool state to $stat\n";
   &getPoolInfo($sPool);
   rstCause(0);
   sleep($FOUND_MESSAGE_WAIT);
}


# figure out current tcpdump child_pids and push them onto the list

foreach $interface (keys( %SETTINGS )) {
   push(@child_pids, $SETTINGS{$interface}{pid});
}


# kill all tcpdumps + free space watcher + capture file rotator -- doesn't return
finish();

0;

