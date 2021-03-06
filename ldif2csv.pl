#!/usr/bin/perl -w
# Name: ldif2csv.pl
# Copyright (c) 2014 Oracle Fusion Middleware A-Team
# License: http://www.apache.org/licenses/LICENSE-2.0.html
# Description:  Converts a LDIF file into a tab delimited file.

# Load any required Perl modules
use Net::LDAP::LDIF;

# Add your own attributes to the following list using a comma as a delimiter
$attributes = "uid,title,employeenumber,mail,postaladdress,postalcode";

# Format numbers
sub commify {
    local($_) = shift;
    1 while s/^(-?\d+)(\d{3})/$1,$2/;
    return $_;
} 

# Clear the screen
print "\033[2J";    #clear the screen
print "\033[0;0H"; #jump to 0,0

# Check for the input file
$input_file=$ARGV[0];
if ( !$input_file ) {
  print "\nThe LDIF file \"perl ldif2csv.pl <filename.ldif>\" is missing.\n\n";
  exit;
}
elsif ( -f $input_file ) {
  $ouptut_file = "$input_file";
  $ouptut_file =~ s/\..*$/.txt/;
  open FILE, ">$ouptut_file" or die $!;
  print "\n";
} 
else {
  print "\nThe LDIF file $input_file does not exist.\n\n";
  exit;
}

# Open the LDIF file to be processed
$ldif = Net::LDAP::LDIF->new( "$input_file", "r", onerror => 'undef' );

# Put the attribute list into an array
@attributes = split(/,/, $attributes);

# Create the header columns in the output file
foreach (@attributes) {
  print FILE "\"" . $_ . "\"\t";
}
print FILE "\n";

# Iterate through the LDIF, find the attributes, and output the results to the output file
$count=0;
while( not $ldif->eof ( ) ) {
   $entry = $ldif->read_entry ( );
   if ( $ldif->error ( ) ) {
     print "Error msg: ", $ldif->error ( ), "\n";
     print "Error lines:\n", $ldif->error_lines ( ), "\n";
   } else {
  
      foreach (@attributes) {
        print FILE "\"" . $entry->get_value( "$_" ) . "\"\t";
      }
      print FILE "\n";
      $count++;
    
      $total = &commify($count);
      print "Total entries processed $total\r";
   }
 }

# Print some final details
print "\033[2J";    #clear the screen
print "\nA total of $total records was output into file $ouptut_file";

# Let's close any open files
$ldif->done ( );
close FILE;
print "\n\n";