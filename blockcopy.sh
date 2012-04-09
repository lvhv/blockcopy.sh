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

TEMPFILE=temphashes.txt
HASHFILE=`echo "hash."$FILENAME |tr // @`
echo "HASHFILE: $HASHFILE"
FILESIZE=$(stat -c%s "$FILENAME")
echo "Size of $FILENAME = $FILESIZE bytes."
touch $HASHFILE

PTR=0
P=0

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
# dd if=$FILENAME skip=$P seek=$P bs=$BLOCKSIZE count=1 status=noxfer of=$OUTFILENAME 2>/dev/null
else
echo "match"
fi



let "PTR+=$BLOCKSIZE"
let "P+= 1"
echo $HASH >> "$TEMPFILE"
done < "$HASHFILE" 

# mv "$TEMPFILE" "$HASHFILE" 

