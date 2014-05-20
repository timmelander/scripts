#!/bin/bash
# SCRIPT:   ldif2csv.sh
# VERSION:  2.3
# AUTHOR:   Timothy Melander
# Copyright (c) 2104 Timothy Melander.
# License: http://www.apache.org/licenses/LICENSE-2.0.html
# MODIFIED: 05/20/2014
# PURPOSE:  Converts LDIF data to a tab delimited CSV formated file.

# Modify the following variable with the list of attributes delimited using a comma delimiter.
attributes="uid,title,employeenumber,mail,postaladdress,postalcode"


# Show usage if we don't have the right params
if [ "$1" == "" ]; then
echo ""
echo "Usage: ./ldif2csv.sh <input.ldif>"
echo "Where <input.ldif> is the LDIF file to be processed."
echo ""
exit 99
fi

# Input and ouput variables
INPUT=$1
OUTPUT=`echo $1 | sed "s/.[^.]*$/.csv/"`

# Create the column headers from the attribute list
function createHeader() {
	# Split the attributes variable into an array
	IFS=',' read -a arrAttrib <<< "${attributes}"
	typeset -i attrLen=${#arrAttrib[@]}
	typeset -i eoa=${attrLen}-1

	headers=""
	for i in "${!arrAttrib[@]}"
	do
		if [ $i -ne $eoa ]; then
			headers=${headers}"\"${arrAttrib[i]}"\""\t"
		else
			headers=${headers}"\"${arrAttrib[i]}\""
		fi
	done
	echo -e $headers > $OUTPUT
}

# Calulate the timelapse
function timelapse() {
	typeset -i t=$(( $END - $START ))
	if [ $t -gt 3600 ]; then
	   h=$(($t/3600))
	   m=$(( ($t%3600)/60 ))
	   s=$(( ($t%3600)-($m*60) ))
	elif [ $t -ge 60 ]; then
	   h=$(($t/3600))
	   m=$(($t/60))
	   s=$(($t%60))
	else
	   h=$(($t/3600))
	   m=$(($t/60))
	   s=$(($t%60))
	fi
}

# Output a message to the screen when starting
typeset -i e=`grep -c "^dn: " $INPUT`
entries=`printf "%'d\n" $e`
#clear
echo ""
echo "Total $entries entries to be processed from file $INPUT; please be patient."
echo ""

# Process the LDIF and output the results to a CSV
START=$(date +%s)
createHeader
awk -v attr="$attributes" -F": " '{
		split(attr,arrayAttr,",");
		arrayLength=length(arrayAttr);

		# Check if it is an entry and skip the first line because it is empty
		if ($1=="dn" && NR!=1) {
		 	# Create the delimiter framework
		 	delimList="\""
		 	for (i=1; i<=arrayLength-1; i++) {
		 		delimList=delimList value[i]"\"\t\""
		 	}
			delimList=delimList value[arrayLength]"\"";
			print delimList;

			# Reset the current record values so they do not bleed from a previous entry
			for (i in arrayAttr) {
				value[i]="";
			}

		} else {
			# Populate each column with data from the LDIF
			for (i in arrayAttr) {
				if (tolower(arrayAttr[i])==tolower($1)) {
					value[i]=$2;
				}
			}
		}
	}
	END {
		# Output the last record before we quit
		delimList="\""
	 	for (i=1; i<=arrayLength-1; i++) {
	 		delimList=delimList value[i]"\"\t\""
	 	}
		delimList=delimList value[arrayLength]"\"";
		print delimList;

 }' $INPUT >> $OUTPUT
END=$(date +%s)

# Get time lapse stats
timelapse $START $END

# Get the final count of records processed
typeset -i c
c=`tail -n +2 $OUTPUT | wc -l`
count=`printf "%'d\n" $c`

# Print out stats
echo "STATS:"
echo "	Input File: 		$INPUT"
echo "	Output File: 		$OUTPUT"
echo "	Entries Processed:  	${count}"
echo "	Time Lapsed:  		${h}h ${m}m ${s}s"
echo ""