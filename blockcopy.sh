#!/bin/bash
# blockcopy.sh 
# copies the changed blocks of a file or device via ssh and dd
# invocation: blockcopy.sh infile username@host outfile
# (C) 2012 Lates Viktor
# still not finished

DIRNAME=~
DIRNAME+="/.blockcopy"
echo $DIRNAME
if [ ! -d $DIRNAME ]
then
mkdir $DIRNAME
fi

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
HASHFILE=`echo "hash.$FILENAME$OUTFILENAME"|tr // @`
HASHFILE="$DIRNAME/$HASHFILE"
TEMPFILE=`echo $HASHFILE".temp"`
echo "HASHFILE: $HASHFILE"

FILESIZE=$(stat -c%s "$FILENAME")
echo "Size of $FILENAME = $FILESIZE bytes."
touch $HASHFILE
STARTTIME=$(date +%s.%N)
PTR=0
P=0
CHANGED=0
COPIEDBYTES=0
COUNT=" count=1 "
while [ "$PTR" -lt "$FILESIZE" ]
do
let "PTR2= $PTR + $BLOCKSIZE"
if [ "$PTR2" -ge "$FILESIZE" ]
then
COUNT=""
fi
echo "count:$COUNT"
HASH=`dd if=$FILENAME skip=$P bs=$BLOCKSIZE $COUNT  status=noxfer 2>/dev/null|md5sum|cut -d ' ' -f 1`
read HASH2
if [ "$HASH" != "$HASH2" ]
then
echo "not match" $P $HASH
let "CHANGED+=1"
let "COPIEDBYTES+=$BLOCKSIZE"
dd if=$FILENAME skip=$P bs=$BLOCKSIZE $COUNT status=noxfer 2>/dev/null|ssh -C -c blowfish-cbc $OUTUSER dd of=$OUTFILENAME seek=$P bs=$BLOCKSIZE status=noxfer 
conv=notrunc2>/dev/null
#dd if=$FILENAME skip=$P bs=$BLOCKSIZE $COUNT  status=noxfer 2>/dev/null|dd of=$OUTFILENAME seek=$P bs=$BLOCKSIZE $COUNT status=noxfer conv=notrunc 2>/dev/null
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
