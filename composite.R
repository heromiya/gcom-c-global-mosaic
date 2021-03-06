## install.packages("rgdal")
## install.packages("raster")
## install.packages("ijtiff")
library("rgdal")
library("raster")
library("ijtiff")

args = commandArgs(trailingOnly=TRUE)

B <- stack(args[1])
G <- stack(args[2])
R <- stack(args[3])
N <- stack(args[4])

outfile <- args[5]

ysize <- dim(R)[1]
xsize <- dim(R)[2]
ndays <- dim(R)[3]

rotate <- function(x) apply(t(x),2,rev)
flip <- function(m) m[c(nrow(m):1),]

input <- array(
    c(values(B)
     ,values(G)
     ,values(R)
     ,values(N)
      )
   ,dim=c(xsize,ysize,ndays,4)
)
rm(N)

composite <- function(x){

    x[apply(x,1,function(a){a[1] == 0 || a[2] == 0 || a[3] == 0 || a[4] == 0 || a[3]/(a[2]+1) > 2}),] <- NA
    x[ x > 10000 ] <- 10000

    ndvi <- (x[,4] - x[,3]) / (x[,4] + x[,3] +1)
    q90 <- quantile(ndvi,probs=seq(0.9,1.0,0.1),type=3,na.rm=TRUE)[1]
    idx <- match(q90,ndvi)

    ave.ref <- apply(x,1,mean)
    med.ave.ref <- quantile(ave.ref,type=3,na.rm=TRUE)[3]
    idx.ref <- match(med.ave.ref,ave.ref)

    if(is.na(q90)) {
        R <- x[idx.ref,3]
        G <- x[idx.ref,2]
        B <- x[idx.ref,1]
    } else if( q90 > 0.5 && ! is.na( x[idx,1] ) && ! is.na( x[idx,2] ) && ! is.na( x[idx,3] ) ) {
    	R <- x[idx,3]
      	G <- x[idx,2]
      	B <- x[idx,1]
    } else {
        R <- x[idx.ref,3]
        G <- x[idx.ref,2]
        B <- x[idx.ref,1]
    }
#    c(as.numeric(R)/10000,as.numeric(G)/10000,as.numeric(B)/10000)
    c(R,G,B)
}

out <- apply(input,c(1,2),composite)
#rm(input)

#for(i in c(1:3)){ 
#      write_tif(flip(rotate(out[i,,])), paste(outfile,".",i,".tif",sep=""))
#}


Rout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Rout) <- extent(R)
values(Rout) <- flip(rotate(out[1,,]))
#writeRaster(Rout,filename=paste(outfile,".R.tif",sep=""))
#rm(R,Rout)

Gout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Gout) <- extent(G)
values(Gout) <- flip(rotate(out[2,,]))
#writeRaster(Gout,filename=paste(outfile,".G.tif",sep=""))
#rm(G,Gout)

Bout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Bout) <- extent(B)
values(Bout) <- flip(rotate(out[3,,]))
#writeRaster(Bout,filename=paste(outfile,".B.tif",sep=""))
#rm(B,Bout)

writeRaster( stack(Rout,Gout,Bout)
	     ,filename=outfile
	     ,datatype="INT2S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
