## install.packages("rgdal")
## install.packages("raster")
library("rgdal")
library("raster")

args = commandArgs(trailingOnly=TRUE)

R <- stack(args[1])
G <- stack(args[2])
B <- stack(args[3])
N <- stack(args[4])

outfile <- args[5]
th <- as.integer(args[6])

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
#input[input < th] <- NA
#input[input > 8000] <- NA
#input[ input[,,,3] / input[,,,1] > 5 ] <- NA
rm(N)
composite <- function(x){

    ndvi <- (x[,4] - x[,3]) / (x[,4] + x[,3] +1)
    q90 <- quantile(ndvi,probs=seq(0.9,1.0,0.1),type=3,na.rm=TRUE)[1]
    idx <- match(q90,ndvi)

    x[ x > 5000 ] <- NA 
    x[ x < 10 ] <- NA
    x[ x[,1] / (x[,3] + 1) < 0.2, ] <- NA

    if(is.na(q90)) {
        R <- median(x[,3],na.rm=TRUE)
    	G <- median(x[,2],na.rm=TRUE)
    	B <- median(x[,1],na.rm=TRUE)
    } else if( q90 > 0.5 && ! is.na( x[idx,1] ) && ! is.na( x[idx,2] ) && ! is.na( x[idx,3] ) ) {
    	R <- x[idx,3]
      	G <- x[idx,2]
      	B <- x[idx,1]
    } else {
        R <- median(x[,3],na.rm=TRUE)
    	G <- median(x[,2],na.rm=TRUE)
   	B <- median(x[,1],na.rm=TRUE)
    }
#    if ( is.na(G) && ! is.na(R) && ! is.na(B) ) {
#       G <- (R + G) / 2
#    }
    c(R,G,B)
}

out <- apply(input,c(1,2),composite)
#out <- array(c(out[1,,],out[2,,],out[3,,]),dim=c(ysize,xsize,3))
rm(input)

Rout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Rout) <- extent(R)
values(Rout) <- flip(rotate(out[3,,]))
rm(R)

writeRaster(Rout,filename=paste(outfile,".R.tif",sep="")
            ,datatype="INT2S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)

rm(Rout)

Gout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Gout) <- extent(G)
values(Gout) <- flip(rotate(out[2,,]))
rm(G)

writeRaster(Gout,filename=paste(outfile,".G.tif",sep="")
            ,datatype="INT2S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)

rm(Gout)

Bout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Bout) <- extent(B)
values(Bout) <- flip(rotate(out[1,,]))
rm(B)

writeRaster(Bout,filename=paste(outfile,".B.tif",sep="")
            ,datatype="INT2S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
rm(Bout)
#StackOut <- stack(Rout,Gout,Bout)

#writeRaster(StackOut,filename="out.tif",overwrite=TRUE,options="compress=deflate")
