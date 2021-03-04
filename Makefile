GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5:
	wget --user=heromiya --password=anonymous ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/2/$(YYYY)/$(MM)/$(DD)/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5 -O $@

GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.VN04.vrt:GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5
	gdalinfo $< | grep -e Geometry_data_Lower -e Geometry_data_Upper
gdal_translate 
