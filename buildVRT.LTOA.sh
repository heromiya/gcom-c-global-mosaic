#! /bin/bash

DIR=GCOM-C-LTOA/2000/

for B in VN04 VN06 VN07; do
    find $DIR -type f -regex .*.${B}.tif > $B.lst
    gdalbuildvrt -srcnodata 0 -vrtnodata -9999 -input_file_list $B.lst -overwrite $B.vrt
done

gdalbuildvrt -separate -overwrite composite.vrt VN04.vrt VN06.vrt VN07.vrt
