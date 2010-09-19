#!/bin/bash
while [ 0 = 0 ]
do
    FILENAME=`date +%Y%m%d%H%M%S01`.jpg
    uvccapture -x1600 -y1200 -G200 -w -o${FILENAME}
    scp ${FILENAME} $1
    rm ${FILENAME}
    sleep 10
done

