#!/usr/bin/perl

# Simple script to monitor the "aliveness" of an http server
# Uses wget and date to simplify life.  
# This can easily be done in multiple ways to avoid shelling out
# if that is desired using 
# use DateTime; to replace the use of date
# and
# use HTTP::Lite; to replace wget
# but this adds dependencies on the modules being present

# Frankly there are so many variations that could be done here
# but I opted for something simple and straightforward that was
# easy to understand for future upgrades or refinements
# There are lots more refinements that could be added depending
# on system setup and other requirements

use v5.10;
use strict;
use warnings;


chomp( my $now = `date +%F-%T`);

# Parametize everything for easy modification
my $log_dir = "log";
my $log = "$log_dir/wget_log-$now";
my $html = "$log_dir/html_output-$now";
my $logfile = "$log_dir/monitor-http.log";

my $host = '10.0.0.8';

# These wget options will retry the request 3 times, timeout each request
# after 5 seconds, capture the server responses and place the 
# server responses in one log file and the result in another.
my $wget = "wget --tries=3 --server-response  --timeout=5 --retry-connrefused -o $log -O $html";

my ($got_http, $got_html_open, $got_html_close);

# Create the log_dir if it doesn't exist
unless (-e $log_dir && -d $log_dir)  { mkdir("$log_dir"); }

# System returns the return code of the shell which would indicate an 
# error if it was anything other than 0 which is normally false
system("$wget $host") == 0
    or die "system $wget $host failed: $?";


# Verify we got an HTTP 200 OK code (don't worry about HTTP version
open (LOG, "$log") || die "Can't read $log: $!\n";

while (<LOG>) { 
    chomp;
    if (/HTTP\/\d\.\d 200 OK/) { $got_http = 1; last; }
}

close LOG;

# Verify we got an <html> and a </html>
# This is of course dependent on the page we are checking being html
open (HTML, "$html") || die "Can't read $html: $!\n";

while (<HTML>) { 
    chomp;
    if (/\<html\>/) { $got_html_open = 1; next; }
    if (/\<\/html\>/) { $got_html_close = 1; last; }
}

close HTML;

# Keep a simple log file with date/time and either alive or dead
open (LOGFILE, ">>$logfile") || die "Can't read $logfile: $!\n";
if ($got_http && $got_html_open && $got_html_close) {
    print LOGFILE "$now http server alive\n";
}
else {
    print LOGFILE "$now http server dead\n";
}

close LOGFILE;
