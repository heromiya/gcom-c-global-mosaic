# coding:utf-8
#ORIGINAL TTY6335
#L1B_VNR_NP 可視近赤外（非偏光）をバンド毎にtiffにする
import h5py
import numpy as np
from osgeo import gdal, ogr, osr, gdalconst
import os, sys
import tifffile

if __name__ == '__main__':

########################
        #入力するファイルの情報#
        ########################
	input_data=sys.argv[1]

########################
#出力するファイルの情報#
########################
	output_file=sys.argv[2]

	#hdf5のファイルを開く
	f=h5py.File(input_data,'r')

	lat_arr=np.array(f['Geometry_data']['Latitude'],dtype='float64')
	lon_arr=np.array(f['Geometry_data']['Longitude'],dtype='float64')

	#GCPのリストを作る
	gcp_list=[]
	#東経180度西経-180度の線を越えていないかチェック
	top_left_lon=lon_arr[0][0]
	top_right_lon=lon_arr[0][-1]
	bottom_left_lon=lon_arr[-1][0]
	bottom_right_lon=lon_arr[-1][-1]

	#東経180度西経-180度の線をまたぐ場合
	if((top_left_lon>top_right_lon) or\
	   (top_left_lon>bottom_right_lon) or\
	   (bottom_left_lon>top_right_lon) or\
	   (bottom_left_lon>bottom_right_lon)\
	):
		lon_arr=np.where(lon_arr<0,lon_arr+360,lon_arr)
		for column in range(0,lat_arr.shape[0],20):
			for row in range(0,lat_arr.shape[1],20): 
				gcp=gdal.GCP(lon_arr[column][row],lat_arr[column][row],0,row*10,column*10)
				gcp_list.append(gcp)
	                        #東経180度西経-180度の線をまたがない場合
	else:	
		for column in range(0,lat_arr.shape[0],20):
			for row in range(0,lat_arr.shape[1],20): 
				gcp=gdal.GCP(lon_arr[column][row],lat_arr[column][row],0,row*10,column*10)
				gcp_list.append(gcp)
		                

#RGBの3バンドだけ抽出する
	sgli_bands=['Lt_VN04','Lt_VN06','Lt_VN07']
	rgb_list=[]

	for sgli in (sgli_bands):
		print(sgli)
		band_image_arr=f['Image_data'][sgli]
		slope=f['Image_data'][sgli].attrs['Slope']
		offset=f['Image_data'][sgli].attrs['Offset']
		#numpyの行列にする
		band_image_arr=np.array(band_image_arr,dtype='uint16')
		#MSBを0にする
		band_image_arr=np.where(band_image_arr>=32768,band_image_arr-32768,band_image_arr)
		#15ビット目を0にする
		band_image_arr=np.where(band_image_arr>=16384,band_image_arr-16384,band_image_arr)
		#欠損値をnanで埋める 0で埋めたときよりもgdalWarpの処理が速くなる?
		band_image_arr=np.where(band_image_arr==16383,np.nan,band_image_arr)
		#大気上端放射輝度を求める
		Lt=slope*band_image_arr+offset
		Lt=np.array(Lt,dtype='float32')
		rgb_list.append(Lt)

	print(Lt.shape)

	#行数
	row_size=Lt.shape[0]
	#列数
	col_size=Lt.shape[1]

	#出力
	dtype = gdal.GDT_Float32
	#バンド数
	band=3
	output = gdal.GetDriverByName('GTiff').Create(output_file,col_size,row_size,band,dtype)
	output.GetRasterBand(1).WriteArray(rgb_list[2])
	output.GetRasterBand(2).WriteArray(rgb_list[1])
	output.GetRasterBand(3).WriteArray(rgb_list[0])
	wkt = output.GetProjection()
	output.SetGCPs(gcp_list,wkt)
	#GCPを使ってEPSG4326に投影変換
	output = gdal.Warp(output_file,\
			   output,\
			   dstSRS='+proj=longlat +datum=WGS84 +no_defs',\
			   tps = True,\
			   dstNodata=np.nan,\
			   outputType=dtype,\
			   multithread=True,\
                           xRes=0.016666666, yRes=0.016666666, \
			   resampleAlg=gdalconst.GRIORA_CubicSpline,\
                           creationOptions=["COMPRESS=Deflate"])
	output = None 	



f.close()
