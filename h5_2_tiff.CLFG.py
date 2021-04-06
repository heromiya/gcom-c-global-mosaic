# coding:utf-8
import numpy as np
import gdal, ogr, os, osr,sys
import h5py
import math

#タイル番号、画素の位置に対応する緯度経度のメッシュを返す関数
#4800x4800ピクセルすべての緯度経度を求めても遅い＆gdal_translateでエラーになるので100ピクセル毎に間引き
#四隅が欲しいのでgcpの配列の大きさは縦横+1してある
def get_geomesh(filename,lin_tile,col_tile,gcp_interval):
        #グラニュールIDからタイルのIDを取得する
        v_tile=int(input_file_name[21:23])
        h_tile=int(input_file_name[23:25])
        
        #SGLI/L2なら固定だと思う
        v_tile_num=18
        h_tile_num=36
        
        #タイルでのメッシュの細かさ
        d=180.0/lin_tile/v_tile_num

        #南極から北極までの総画素数
        NL_0=int(round(180.0/d))
        #赤道における東西方向の総画素数
        NP_0=2*NL_0
	#gdal_translateに与えるGCPのリスト
        gcp_list=[]
	
        for lin in range(0,lin_tile+1,gcp_interval):
                for col in range(0,col_tile+1,gcp_interval):
                        if(lin==lin_tile):
                                lin=lin-1
                        if(col==col_tile):
                                col=col-1
                        lin_total=lin+v_tile*lin_tile
                        col_total=col+h_tile*col_tile
                        lat=90.0-(lin_total+0.5)*d
                        NP_i=NP_0*math.cos(math.radians(lat))
                        lon=360.0*(col_total+0.5-NP_0/2)/NP_i
                        gcp=gdal.GCP(round(lon,6),round(lat,6),0,col+0.5,lin+0.5)
                        gcp_list.append(gcp)
        return gcp_list

def getDN(x):
        flag = np.binary_repr(x,width=16)[0:4]
        if flag == '1000':
                cloud = 1 - 0.0
        elif flag == '1001':
                cloud = 1 - (0.00 + 0.17) / 2
        elif flag == '1010':
                cloud = 1 - (0.17 + 0.33) / 2
        elif flag == '1011':
                cloud = 1 - (0.33 + 0.50) / 2
        elif flag == '1100':
                cloud = 1 - (0.50 + 0.67) / 2
        elif flag == '1101':
                cloud = 1 - (0.67 + 0.83) / 2
        elif flag == '1110':
                cloud = 1 - (0.83 + 1.00) / 2
        elif flag == '1111':
                cloud = 1 - 1.0
        else:
                cloud = np.nan
        return cloud
                
#        flag = np.where(flag < 1000,np.nan,flag)
        
#        return int(np.binary_repr(x,width=16)[:4],2)

if __name__ == '__main__':

        #入力するファイルの情報#
        #ファイル名
        input_file=sys.argv[1]
        #バンド名
        band_name=sys.argv[2]

        #出力ファイル名
        output_file=sys.argv[3]
        gcp_interval=int(sys.argv[4])


        try:
                hdf_file = h5py.File(input_file, 'r')
        except:
                print('%s IS MISSING.' % input_file)
                exit(1);
	        
        hdf_file = h5py.File(input_file, 'r')

	#print('OPEN %s.' % input_file)

	#L2のHDF5ファイルのImage_data以下にデータが入っている。
        try:
                Image_var=hdf_file['Image_data'][band_name]
        except:
                print('%s IS MISSING.' % band_name)
                print('SELECT FROM')
                print(hdf_file['Image_data'].keys())
                exit(1);

        input_file_name=str(hdf_file['Global_attributes'].attrs['Product_file_name'][0][2:45])
        #L2のHDF5ファイルのImage_data以下にデータが入っている。
        Image_var=hdf_file['Image_data'][band_name]        
        #Slope=hdf_file['Image_data'][band_name].attrs['Slope']
        #Offset=hdf_file['Image_data'][band_name].attrs['Offset']
        Max_DN=hdf_file['Image_data'][band_name].attrs['Maximum_valid_DN']
        Min_DN=hdf_file['Image_data'][band_name].attrs['Minimum_valid_DN']
        
	#型変換とエラー値をnanに変換する
        Image_var=np.array(Image_var,dtype='uint16')

        getDN_vec = np.vectorize(getDN)

        DN = getDN_vec(Image_var)
        #DN = np.where(DN==16383,np.nan,DN)
	#値を求める
        #Value_arr=(DN)
	#Value_arr=np.array(Value_arr,dtype='int16')
        Value_arr=np.array(DN,dtype='float32')

	#行数
        lin_size=Image_var.shape[0]
	#列数
        col_size=Image_var.shape[1]

	#GCPのリストをつくる
        gcp_list=get_geomesh(input_file_name,lin_size,col_size,gcp_interval)

	#出力
        dtype = gdal.GDT_Float32
	#dtype = gdal.GDT_Int16
        band=1
        output = gdal.GetDriverByName('GTiff').Create(output_file,lin_size,col_size,band,dtype) 
        output.GetRasterBand(1).WriteArray(Value_arr)
        wkt = output.GetProjection()
        output.SetGCPs(gcp_list,wkt)
        
	#与えたGCPを使ってEPSG4326に投影変換
	#options = gdal.WarpOptions(xRes=0.020833325, yRes=0.020833325, dstSRS='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs',tps = True, multithread = True, outputType=dtype)
	#kwargs = { 'dstSRS': '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs', 'tps': True, 'outputType': dtype }
	#output = gdal.Warp(output_file, output)
	#output = gdal.Warp(output_file, output, dstSRS='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs',tps = True,outputType=dtype)
        
        output.FlushCache()
        output = None 	

        hdf_file.close()
