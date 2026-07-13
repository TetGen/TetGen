#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
# Copyright (c) 2024 Hang Si

# runtest.sh
#
#   A shell script to batch-run TetGen tests independent of CMake
#   The runtime information of TetGen is saved in file: log.txt.
#   The test report is found in file: report.txt
#
# Syntax:
#
#   ./runtest.sh tetgen options directory filetypes
#

syntax="Syntax: ./runtest.sh tetgen options directory [filetypes]"

if test -z $*
then
  echo -e $syntax
  exit 1
fi

report="$3$2-report.txt"
echo $* > $report

if test -f $1  # Does file $1 a regular file (not directory or device file)?
then
  if test -d $3  # Is $3 a directory?
  then
    echo -e "Test $1 on directory $3\n" >> $report
  else
    echo "Directory $3 doesn't exist."
    exit
  fi
else
  echo "File $1 doesn't exist."
  exit
fi

echo -e "Test begin: `date`\n" >> $report

testcount=0;
passcount=0;
inputerrcount=0;
failcount=0;

if test -z $4
then
  # Set default file types.
  ftypes='*.smesh *.poly *.mesh'
else
  ftypes=$4
fi

for ft in $ftypes
do
  files=`ls $3/$ft`
  result=$?
  if test $result -eq 0
  then
    for f in $files ;
    do
      $1 $2 $f
      result=$?
      if test $result -eq 0
      then
        string="$1 $2 $f \t\t(passed)";
        ((passcount++))
      elif test $result -eq 3
      then
        string="$1 $2 $f \t\t(PLC error detected)";
        ((inputerrcount++))
      elif test $result -eq 4
      then
        string="$1 $2 $f \t\t(Small feature detected)";
        ((inputerrcount++))
      elif test $result -eq 5
      then
        string="$1 $2 $f \t\t(Try -Y option)";
        ((inputerrcount++))
      elif test $result -eq 10
      then
        string="$1 $2 $f \t\t(Input error detected)";
        ((inputerrcount++))
      else
        string="$1 $2 $f \t\t(***failed***)";
        ((failcount++))
      fi
      echo -e "$string $result" >> $report
      ((testcount+=1))
    done
  else
    echo $syntax
    exit 1
  fi
done

echo -e "\nTest Statistics:" >> $report
echo -e "  $testcount tests performed." >> $report
echo -e "  $passcount tests passed." >> $report
echo -e "  $failcount tests failed." >> $report
echo -e "  $inputerrcount input errors detected." >> $report
echo -e "\n" >> $report

echo -e "Test end: `date`\n" >> $report

exit 0
