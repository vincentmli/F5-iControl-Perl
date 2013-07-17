use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'iControl',
    VERSION_FROM      => 'iControl.pm',
    PREREQ_PM         => {
        'IO::Socket::SSL'     => 0,
        'MIME::Base64'        => 0,
        'Net::SSH::Expect'    => 0,
        'POSIX'               => 0,
        'SOAP::Lite'          => 0,
        'Socket'              => 0,
        'Sys::Syslog'         => 0,
        'Time::HiRes'         => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'iControl.pm', # retrieve abstract from module
       AUTHOR         => 'Vincent Li - https://github.com/vincentmli') : ()),
);

