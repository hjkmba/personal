#!/usr/local/bin/perl5 -w

use strict;
use warnings;

#########################################
#                                       #
#             version 1.1               #
#                                       #
#########################################

################################################################################
# Modified By: He Dong
# Modified At: 2015-1-25
#
# Updates:
#	1. changes the output dir and output file name
#	2. extract server name from the file name
#	3. add a gzip step after the file is processed
#	4. backup the source file to ${source_dir}/backup after processed
#
# Usage:
#	./tm_hw_group.pl [source_dir] [source_file_pattern]
#	e.g:	./tm_hw_group.pl /home/users/nitang/DBA_LOG [${server_name}.check_processes.out.${date}.gz]
#
# Further instruction:
# 	1. source dir: /home/users/nitang/DBA_LOG/
# 	2. output dir: /home/users/hdong/sybase_log
# 	3. target: all files under source dir, matching ${server_name}.check_processes.out.${date}.gz
#	   (no failover if fetching files are not matched the pattern with default pattern)
# 	4. output: ${server_name}.hw.${date}.bcp.gz
#	5. tm_hw.pl accept both compressed or uncomparessed files 
#
################################################################################
my $output_dir = '/home/users/hdong/sybase_log';
# current directory
my $Dir;
if(!$ARGV[0]){
	$Dir = ".\/";
}
else{
	$Dir = $ARGV[0];
}
opendir(DH, "$Dir") or die "Can't open: $!\n" ;

# get the file search pattern
my $log_pattern;
if(!$ARGV[1]){
	$log_pattern = "check_processes.out.*";
}
else{
	$log_pattern = $ARGV[1];
}

# get all files matching the pattern
my @list = sort grep {/$log_pattern$/ && -f "$Dir/$_" } readdir(DH);
closedir(DH);

my $file_count = @list;
print "Find ".$file_count." Hardware log files with pattern \'".$log_pattern."\'\n\n";

my $user = `/usr/ucb/whoami`;
chomp($user);
print $user."\n";
my $date="";
my @file_str = "";
my $out_file_name= "";
my $plfile = "/home/users/".$user."/bin/tm_hw.pl";
print $plfile."\n";
my $count = 1;

# calling 'tm_hw.pl' to deal each log file
foreach my $file (@list){
	print "*** Hardware Log File".$count." - ".$file." ***\n";
	## new added by DH, extracting server info	
	$file =~ /(\w+)\.check_processes\.out\.\d+/;
	my $server_name = $1;	
	print "servername: $server_name\n"	;
	## end
	$count++;
	$file =~ /check_processes\.out\.(\d+)/;
	$file = "$Dir/$file";
	$date = $1;
	# TODO: change later to specify a location to store the result files
	$out_file_name = $output_dir."/$server_name.hw.".$date.".bcp";

	system("$plfile $file $out_file_name");
	my $is_success = $? >> 8;
   # print dealing result
    if( $is_success == 0 ){
		print "$file --> $out_file_name"." succeed ^.^\n\n";
		system("gzip -f $out_file_name");
		system("mv -f $file $Dir/backup");
	}
	else
	{
		print "$file --> $out_file_name"." failed!!!\n\n";
	}
}
