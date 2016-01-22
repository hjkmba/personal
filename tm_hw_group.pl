#!/usr/local/bin/perl5 -w

use strict;
use warnings;

#########################################
#                                       #
#             version 1.1               #
#                                       #
#########################################

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
	$count++;
	$file =~ /check_processes\.out\.(\d+)/;
	$file = "$Dir/$file";
	$date = $1;
	$out_file_name = $Dir."/hw_".$date.".bcp";

	system("$plfile $file $out_file_name");
	my $is_success = $? >> 8;
   # print dealing result
    if( $is_success == 0 ){
		print "$file --> $out_file_name"." succeed ^.^\n\n";
	}
	else
	{
		print "$file --> $out_file_name"." failed!!!\n\n";
	}
}
