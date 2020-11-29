# coding:utf-8
#L2 海洋プロダクトをgeotiff出力する。
import h5py
import numpy as np
import gdal, ogr, os, osr, sys
import tifffile

if __name__ == '__main__':

#入力するファイルの情報#
	#ファイル名
        input_file=sys.argv[1]
	#バンド名
        band_name=sys.argv[2]

#出力ファイル名
        output_file=sys.argv[3]

        try:
            hdf_file = h5py.File(input_file, 'r')
        except:
            print('%s IS MISSING.' % input_file)
            exit(1);
	
        hdf_file = h5py.File(input_file, 'r')

        print('OPEN %s.' % input_file)

        #L2のHDF5ファイルのImage_data以下にデータが入っている。
        try:
            Image_var=hdf_file['Image_data'][band_name]
        except:
            print('%s IS MISSING.' % band_name)
            print('SELECT FROM')
            print(hdf_file['Image_data'].keys())
            exit(1);

        input_file_name=str(hdf_file['Global_attributes'].attrs['Product_file_name'][0][2:45])

        lat_arr=np.array(hdf_file['Geometry_data']['Latitude'],dtype='float64')
        lon_arr=np.array(hdf_file['Geometry_data']['Longitude'],dtype='float64')

        #GCPのリストを作る
        gcp_list=[]
        for column in range(0,lat_arr.shape[0],20):
            for row in range(0,lat_arr.shape[1],20): 
                gcp=gdal.GCP(lon_arr[column][row],lat_arr[column][row],0,row*10,column*10)
                gcp_list.append(gcp)
		
#hdfファイルに格納されているファイル名からファイルに入っていプロダクト名を選択する。
        print(band_name)
        band_image_arr=hdf_file['Image_data'][band_name]
        slope=hdf_file['Image_data'][band_name].attrs['Slope']
        offset=hdf_file['Image_data'][band_name].attrs['Offset']

        #float32の行列にする
        band_image_arr=np.array(band_image_arr,dtype='float32')

		#プロダクトの値を計算する
        Error_DN=hdf_file['Image_data'][band_name].attrs['Error_DN']
        Maximum_valid_DN=hdf_file['Image_data'][band_name].attrs['Maximum_valid_DN']
		#陸域、エラーのピクセルはすべて-9999で埋める
        product=np.where(band_image_arr<=Maximum_valid_DN,band_image_arr*slope+offset,-9999)

        #行数
        row_size=product.shape[0]
        #列数
        col_size=product.shape[1]

        #出力
        dtype = gdal.GDT_Float32
        #バンド数
        band=1
        output = gdal.GetDriverByName('GTiff').Create(output_file,col_size,row_size,band,dtype)
        output.GetRasterBand(1).WriteArray(product)
        wkt = output.GetProjection()
        output.SetGCPs(gcp_list,wkt)
	#GCPを使ってEPSG4326に投影変換
        #output = gdal.Warp(output_file,output,	dstSRS='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs',tps = True,outputType=dtype,srcNodata=Error_DN,dstNodata=-9999,multithread=True)
        output = None


hdf_file.close()
