#! /bin/bash

#for FILE in $(find composite/2000/ -type f -regex ".*tif");do
function chkGDAL() {
    FILE=$1
    
    if [ $(gdalinfo -stats $FILE 2>&1 | grep ERROR | wc -l) -gt 0 ]; then
	rm -f $FILE
    fi
}
export -f chkGDAL

LIST=$(mktemp)
find composite/CLFG/2000/ -type f -regex ".*tif" > $LIST
parallel chkGDAL :::: $LIST
#done
