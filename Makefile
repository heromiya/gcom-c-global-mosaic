GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5:
	wget --user=heromiya --password=anonymous ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/2/$(YYYY)/$(MM)/$(DD)/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5 -O $@

GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.VN04.vrt: GCOM-C/GC1SG1_$(YYYY)$(MM)$(DD)A01D_T$(TILE)_L2SG_RSRFQ_2000.h5
	gdalinfo $< | grep -e Geometry_data_Lower -e Geometry_data_Upper

$(H5FILE).$(B).gcp.tif: $(H5FILE)
	python3 h5_2_tiff.LTOA.py $< Lt_$(B) $@ $(GCP_INTERVAL)

$(RESAMPLED_TIFF): $(H5FILE).$(B).gcp.tif
	gdalwarp $(WARPOPT) $< $@

$(VRTDIR)/$(TILE).$(B).vrt: $(INPUT_FILES)
	gdalbuildvrt -q -separate -overwrite $@ $(INPUT_FILES)

$(OUTFILE): $(VRTDIR)/$(TILE).VN04.vrt $(VRTDIR)/$(TILE).VN06.vrt $(VRTDIR)/$(TILE).VN07.vrt
	./composite.LTOA.sub.sh $(TILE) $(OUTFILE)

composite/LTOA/2000/20210328_$(BUF)/composite.2000.$(TILE).20210328_$(BUF).mean.tif: composite/LTOA/2000/20210328_$(BUF)/composite.2000.$(TILE).20210328_$(BUF).tif
	gdal_calc.py --quiet --calc="(A+B+C)/3" --NoDataValue=0 --outfile $@ --co="COMPRESS=Deflate" -A $< -B $< -C $<

mean/mean.LTOA.$(BUF).vrt: composite/LTOA/2000/20210328_$(BUF)/*.mean.tif
	gdalbuildvrt -q -a_srs "EPSG:4087" -srcnodata 0 -overwrite $@ composite/LTOA/2000/20210328_$(BUF)/*.mean.tif

composite.LTOA.$(BUF).vrt:
	gdalbuildvrt -q -a_srs "EPSG:4087" -srcnodata 0 -overwrite $@ composite/LTOA/2000/20210328_$(BUF)/*.tif


mean/mean.LTOA.$(BUF).tif: composite.LTOA.$(BUF).vrt
	gdal_calc.py --quiet --calc="(A+B+C)/3" --NoDataValue=0 --outfile $@ --co="COMPRESS=Deflate" -A $< --A_band=1 -B $< --B_band=2 -C $< --C_band=3

2000/$(TILE)/GC1SG1_$(DATE)D01D_T$(TILE)_L2SG_LTOAK_2002.h5.mean.tif: 2000/$(TILE)/GC1SG1_$(DATE)D01D_T$(TILE)_L2SG_LTOAK_2002.h5.VN04.tif 2000/$(TILE)/GC1SG1_$(DATE)D01D_T$(TILE)_L2SG_LTOAK_2002.h5.VN06.tif 2000/$(TILE)/GC1SG1_$(DATE)D01D_T$(TILE)_L2SG_LTOAK_2002.h5.VN07.tif
	gdal_calc.py --quiet --calc="(A+B+C)/3" --NoDataValue=0 --outfile $@ --co="COMPRESS=Deflate" -A $(word 1,$^) -B $(word 2,$^) -C $(word 3,$^)


scaled/scaled.mean.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).vrt: mean/mean.LTOA.$(BUF).vrt
	gdal_translate -of VRT -a_srs "EPSG:4087" -a_nodata 0 -ot Byte -scale $(CLD_MIN) $(CLD_MAX) 0 255 $< $@

scaled/scaled.composite.LTOA.$(BUF).1.vrt: composite.LTOA.$(BUF).vrt
	gdal_translate -of VRT -ot Byte -scale -a_srs "EPSG:4087" -b 1 $< $@

scaled/scaled.composite.LTOA.$(BUF).2.vrt: composite.LTOA.$(BUF).vrt
	gdal_translate -of VRT -ot Byte -scale -a_srs "EPSG:4087" -b 2 $< $@

scaled/scaled.composite.LTOA.$(BUF).3.vrt: composite.LTOA.$(BUF).vrt
	gdal_translate -of VRT -ot Byte -scale -a_srs "EPSG:4087" -b 3 $< $@

cloud.alpha.d/cloud.alpha.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).vrt: scaled/scaled.composite.LTOA.$(BUF).1.vrt scaled/scaled.composite.LTOA.$(BUF).2.vrt scaled/scaled.composite.LTOA.$(BUF).3.vrt scaled/scaled.mean.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).vrt
	gdalbuildvrt -separate -overwrite -r average -tr 5006.594097500000316 4731.078360000000430 -te -20026376.390 -9462156.720 20026376.390 9462156.720 $@ $+

cloud.alpha.d/cloud.alpha.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).colorinterpret.tif: cloud.alpha.d/cloud.alpha.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).vrt
	gdal_translate -colorinterp_1 blue -colorinterp_2 green -colorinterp_3 red -colorinterp_4 alpha $< $@


RSRF.NWLRK.cloud.alpha.LTOA.20210328_$(BUF).$(CLD_MIN)-$(CLD_MAX).tif: cloud.alpha.d/cloud.alpha.LTOA.$(BUF).$(CLD_MIN)-$(CLD_MAX).colorinterpret.tif RSRF.NWLRK.8000x4000.hist-matched.Byte-mod.tif
	composite $+ $@

cloudMask.LTOA.20210328_$(BUF).$(TH).tif: mean.LTOA.$(BUF).tif
	gdal_calc.py --calc="numpy.where(numpy.logical_and(A > $(TH) , A < 9999), 1, numpy.nan)" --overwrite --outfile $@ -A $<

cloudMask.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).tif: cloudMask.LTOA.20210328_$(BUF).$(TH).tif
	gdal_sieve.py -8 -st $(SIEVE) $< $@

cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).1.tif: cloudMask.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).tif composite.LTOA.$(BUF).vrt
	gdal_calc.py --calc="numpy.where(A==1, B, numpy.nan)" --outfile $@ --co="COMPRESS=Deflate" -A $< -B composite.LTOA.$(BUF).vrt --B_band=1

cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).2.tif: cloudMask.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).tif composite.LTOA.$(BUF).vrt
	gdal_calc.py --calc="numpy.where(A==1, B, numpy.nan)" --outfile $@ --co="COMPRESS=Deflate" -A $< -B composite.LTOA.$(BUF).vrt --B_band=2

cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).3.tif: cloudMask.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).tif composite.LTOA.$(BUF).vrt
	gdal_calc.py --calc="numpy.where(A==1, B, numpy.nan)" --outfile $@ --co="COMPRESS=Deflate" -A $< -B composite.LTOA.$(BUF).vrt --B_band=3



cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt: cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).1.tif cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).2.tif cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).3.tif
	gdalbuildvrt -separate -overwrite -tr 5006.594097999999576 4731.078360000000430 $@ $+


scaled.cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt: cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt
	gdal_translate -of VRT -a_srs "EPSG:4087" -ot Byte -scale -a_nodata 0 $+ $@

alpha.cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt: scaled.cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt scaled.mean.LTOA.$(BUF).vrt
	gdalbuildvrt -separate $@ $+


RSRF.NWLRK.8000x4000.hist-matched.Byte-mod.geo.vrt: RSRF.NWLRK.8000x4000.hist-matched.Byte-mod.tif
	gdal_translate -of VRT -a_srs "EPSG:4087" -a_ullr -20026376.390 9462156.720 20026376.390 -9462156.720 -colorinterp undefined $< $@

RSRF.NWLRK.cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).tif: RSRF.NWLRK.8000x4000.hist-matched.Byte-mod.geo.vrt scaled.cloud.LTOA.20210328_$(BUF).$(TH).sieve$(SIEVE).vrt
	gdal_merge.py -co COMPRESS=Deflate -o $@ $+
#	gdalbuildvrt -overwrite -srcnodata 0 $@ $+
