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

mean.na.rm <- function(x) mean(x, na.rm=TRUE)

composite.max.mean <- function(x){
    intencity <- apply(x,1,mean.na.rm)
    #q90 <- quantile(intencity,probs=seq(0.9,1.0,0.1),type=3,na.rm=TRUE)[1]
    #idx <- match(q90,intencity)
    idx <- match(max(intencity,na.rm=TRUE),intencity)

    R <- x[idx,3]
    G <- x[idx,2]
    B <- x[idx,1]
    A <- intencity[idx]
    
    c(R,G,B,A)
}

out <- apply(input,c(1,2),composite.max.mean)

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

Aout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Aout) <- extent(B)
values(Aout) <- flip(rotate(out[4,,]))

writeRaster( stack(Rout,Gout,Bout,Aout)
           ,filename=outfile
           ,datatype="FLT4S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
