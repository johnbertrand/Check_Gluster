#!/usr/bin/perl

use warnings;
use strict;
use Nagios::Plugin;
use Nagios::Plugin::Functions;
use Nagios::Plugin::Getopt;

#Check_GLuster.pl
# John C. Bertrand <john.bertrand@gmail.com>
# Florian Panzer <rephlex@rephlex.de>
# Sebastian Gumprich <sebastian.gumprich@38.de>
# This nagios plugins checks the status
# and checks to see if the volume has the correct
# number of bricks
# Checked against gluster 3.2.7 and 3.6.2 and 3.8.1
# Rev 4 2016.07.27

#SET THESE
my $SUDO="/usr/bin/sudo";
my $GLUSTER="/usr/sbin/gluster";

my $opts = Nagios::Plugin::Getopt->new(
        usage   => "Usage: %s  -v --volume Volume_Name -n --numbricks -s --sudo -b --split-brain",
        version => Nagios::Plugin::->VERSION,
        blurb   => 'checks the volume state, brick count and split-brain state of GlusterFS.'
);

$opts->arg(
    spec => 'volume|v=s',
    help => 'Volume name',
    required => 1,
  );

$opts->arg(
    spec => 'numberofbricks|n=i',
    help => 'Target number of bricks',
    required => 1,
);

$opts->arg(
   spec => 'sudo|s',
   help => 'use sudo',
   required => 0,
   default => 0,
);

$opts->arg(
   spec => 'split-brain|b',
   help => 'check for split-brain',
   required => 0,
   default => 0,
);

$opts->getopts;

my $volume=$opts->get("volume");
my $bricktarget=$opts->get("numberofbricks");
my $use_sudo=$opts->get("sudo");
my $check_sb=$opts->get("split-brain");

my $returnCode=UNKNOWN;
my $returnMessage="~";

# Check for cluster state
my $result= undef;
my $heal = undef;

if ($use_sudo == 1) {
  $result=`$SUDO $GLUSTER volume info $volume`;
}else {
  $result=`$GLUSTER volume info $volume`;
}

if ($result =~ m/Status: Started/){
    if ($result =~ m/Number of Bricks: .*(\d+)/){
        my $bricks=$1;

        if ($bricks != $bricktarget){
                $returnCode=CRITICAL;
                $returnMessage="Brick count is $bricks, should be $bricktarget";
          }
        elsif ($check_sb == 1){
          # Check for split-brain
          if ($use_sudo == 1) {
            $heal=`$SUDO $GLUSTER volume heal $volume info`;
          }
          else {
            $heal=`$GLUSTER volume heal $volume info`;
          }
          if ($heal !~ m/Number of entries: 0/){
            $returnCode=CRITICAL;
            $returnMessage="Failed replication between cluster members. Possible split-brain!";
          } else {
            $returnCode=OK;
            $returnMessage="Volume $volume is stable";
            }
        } else {
           $returnCode=OK;
           $returnMessage="Volume $volume is stable";
        }
    }else{
        $returnCode=CRITICAL;
        $returnMessage="Could not grep bricks";
    }
}elsif($result =~ m/Status: (\S+)/){
 $returnCode=CRITICAL;
 $returnMessage="Volume Status is $1";

}else{
    $returnCode=CRITICAL;
    $returnMessage="Could not grep Status $result for $volume";
}

Nagios::Plugin->new->nagios_exit(return_code => $returnCode,
  message => $returnMessage
);
