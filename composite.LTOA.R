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

outfile <- args[4]

ysize <- dim(R)[1]
xsize <- dim(R)[2]
ndays <- dim(R)[3]

rotate <- function(x) apply(t(x),2,rev)
flip <- function(m) m[c(nrow(m):1),]

input <- array(
    c(values(B)
     ,values(G)
     ,values(R)
      )
   ,dim=c(xsize,ysize,ndays,3)
)

composite <- function(x){

    intencity <- mean(c(x[,1:3]))
    q90 <- quantile(intencity,probs=seq(0.9,1.0,0.1),type=3,na.rm=TRUE)[1]
    idx <- match(q90,intencity)

    R <- x[idx,3]
    G <- x[idx,2]
    B <- x[idx,1]
    
    c(R,G,B)
}

out <- apply(input,c(1,2),composite)

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
           ,datatype="FLT4S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
