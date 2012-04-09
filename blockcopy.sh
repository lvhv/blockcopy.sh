#!/bin/bash
# blockcopy.sh 
# copies the changed blocks of a file or device via ssh and dd
# invocation: blockcopy.sh infile username@host outfile
# (C) 2012 Lates Viktor
# still not finished


if [ -n "$1" ]
# Test whether command-line argument is present (non-empty).
then
  FILENAME=$1
else  
  echo "usage: $0 [ -f ] [ -q ] infile username outfile."
  exit 1
fi 

if [ -n "$2" ]
# Test whether command-line argument is present (non-empty).
then
  OUTUSER=$2
else  
  echo "No username given."
  exit 1
fi 

if [ -n "$3" ]
# Test whether command-line argument is present (non-empty).
then
  OUTFILENAME=$3
else  
  echo "No outfile given."
  exit 1
fi 

BLOCKSIZE=1048576
DIRNAME="~/.blockcopy"
#echo $DIRNAME
#mkdir -p $DIRNAME
HASHFILE=`echo "hash."$FILENAME |tr // @`
TEMPFILE=`echo "temp."$HASHFILE`
echo "HASHFILE: $HASHFILE"
FILESIZE=$(stat -c%s "$FILENAME")
echo "Size of $FILENAME = $FILESIZE bytes."
touch $HASHFILE
STARTTIME=$(date +%s.%N)
PTR=0
P=0
CHANGED=0
COPIEDBYTES=0
while [ "$PTR" -lt "$FILESIZE" ]
do
let "PTR2= $PTR + $BLOCKSIZE"
if [ "$PTR2" -gt "$FILESIZE" ]
then
let "BLOCKSIZE= $FILESIZE - $PTR"
fi
HASH=`dd if=$FILENAME skip=$P bs=$BLOCKSIZE count=1 status=noxfer 2>/dev/null|md5sum|cut -d ' ' -f 1`
read HASH2
if [ "$HASH" != "$HASH2" ]
then
echo "not match" $P $HASH
let "CHANGED+=1"
let "COPIEDBYTES+=$BLOCKSIZE"
dd if=$FILENAME skip=$P seek=$P bs=$BLOCKSIZE count=1 status=noxfer of=$OUTFILENAME 2>/dev/null
fi



let "PTR+=$BLOCKSIZE"
let "P+= 1"
echo $HASH >> "$TEMPFILE"
done < "$HASHFILE" 
echo "Changed:$CHANGED"

mv "$TEMPFILE" "$HASHFILE" 
ENDTIME=$(date +%s.%N)
DIFFTIME=$(echo "$ENDTIME - $STARTTIME" | bc)
echo "Time: $DIFFTIME"
echo "Copied bytes $COPIEDBYTES"
SPD=$(echo "$COPIEDBYTES / $DIFFTIME / 1024 / 1024" | bc)
echo "Speed: $SPD mb/s"
