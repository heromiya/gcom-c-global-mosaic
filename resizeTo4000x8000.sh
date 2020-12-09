#! /bin/bash

gdalwarp -overwrite -r cubicspline -s_srs EPSG:4087 -te -20026376.39 -9462156.72 20026376.39 9462156.72 -tr 5006.594098 4731.07836 -co COMPRESS=Deflate -multi RSRF.2000.filled.vrt RSRF.NWLRK.8000x4000.tif

gdal_translate -ot Byte -of JPEG -scale_1 0 3200 1 255 -scale_2 0 2600 1 255 -scale_3 0 2900 1 255 RSRF.NWLRK.8000x4000.tif  RSRF.NWLRK.8000x4000.jpg
