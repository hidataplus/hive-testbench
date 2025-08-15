#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

# PROTOTYPES
sub dieWithUsage(;$);

# GLOBALS
my $SCRIPT_NAME = basename( __FILE__ );
my $SCRIPT_PATH = dirname( __FILE__ );

# MAIN
dieWithUsage("one or more parameters not defined") unless @ARGV >= 1;
my $suite = shift;
my $scale = shift || 2;
dieWithUsage("suite name required") unless $suite eq "tpcds" or $suite eq "tpch";

chdir $SCRIPT_PATH;
if( $suite eq 'tpcds' ) {
	chdir "sample-queries-tpcds-trino";
} else {
	chdir 'sample-queries-tpch';
} # end if
my @queries = glob '*.sql';

my $db = { 
	'tpcds' => "tpcds_bin_partitioned_orc_$scale",
	'tpch' => "tpch_flat_orc_$scale"
};

print "filename,status,time,rows\n";
for my $query ( @queries ) {
	my $logname = "$query.log";
        my $beeline_mr3 = "beeline -u 'jdbc:hive2://datanode01:2181/tpcds_bin_partitioned_orc_2;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2-mr3' -n hive ";
	#my $cmd="echo 'use $db->{${suite}}; source $query;' | $beeline_mr3 -i testbench.settings 2>&1  | tee $query.log";
	#
	my $cmd="trino --server http://datanode01:8380/hive --schema tpcds_bin_partitioned_orc_2  --user=trino --progress -f $query 2>&1  | tee query12.sql.log";
#	my $cmd="cat $query.log";
	#print $cmd ; exit;
	#print "$cmd\n";
	
	my $hiveStart = time();

	my @hiveoutput=`$cmd`;
	die "${SCRIPT_NAME}:: ERROR:  hive command unexpectedly exited \$? = '$?', \$! = '$!'" if $?;

	my $hiveEnd = time();
	my $hiveTime = $hiveEnd - $hiveStart;
	foreach my $line ( @hiveoutput ) {
                #print "$line\n";

                if( $line =~ /(\d+|No) rows selected \(([\d\.]+) seconds\)/ ) {
                        my $rows = $1 eq 'No' ? 0 : $1;
                        # print $line;
                        print "$query,success,$hiveTime,$rows,$2\n";
                } elsif( $line =~ /(\d+) row selected \(([\d\.]+) seconds\)/ ) {
                       # print $line;
                        print "$query,success,$hiveTime,$1,$2\n";
                } elsif ($line =~ /^([\d\.]+)\s+\[([\d\.]+\w+)\s+rows,\s+([\d\.]+\w+)\]\s+\[([\d\.]+\w+)\s+rows\/s,\s+([\d\.]+\w+\/s)\]/) {
                        print "$query,success,$hiveTime,$2,$1\n";

                } elsif($line =~ /ERROR : FAILED: /) {
                        print "$query,failed,$hiveTime\n";
		} elsif( 
			$line =~ /^FAILED: /
			# || /Task failed!/ 
			) {
			print "$query,failed,$hiveTime\n"; 
		} # end if
	} # end while
} # end for


sub dieWithUsage(;$) {
	my $err = shift || '';
	if( $err ne '' ) {
		chomp $err;
		$err = "ERROR: $err\n\n";
	} # end if

	print STDERR <<USAGE;
${err}Usage:
	perl ${SCRIPT_NAME} [tpcds|tpch] [scale]

Description:
	This script runs the sample queries and outputs a CSV file of the time it took each query to run.  Also, all hive output is kept as a log file named 'queryXX.sql.log' for each query file of the form 'queryXX.sql'. Defaults to scale of 2.
USAGE
	exit 1;
}

