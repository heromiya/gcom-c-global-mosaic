## install.packages("rgdal")
## install.packages("raster")
library("rgdal")
library("raster")

args = commandArgs(trailingOnly=TRUE)

R <- stack(args[1])
G <- stack(args[2])
B <- stack(args[3])

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
#input[input < th] <- NA

composite <- function(x){
    R = median(x[,3])
    G = median(x[,2])
    B = median(x[,1])
    c(R,G,B)
}

out <- apply(input,c(1,2),composite)
#out <- array(c(out[1,,],out[2,,],out[3,,]),dim=c(ysize,xsize,3))

Rout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Rout) <- extent(R)
values(Rout) <- flip(rotate(out[3,,]))

Gout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Gout) <- extent(G)
values(Gout) <- flip(rotate(out[2,,]))

Bout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Bout) <- extent(B)
values(Bout) <- flip(rotate(out[1,,]))

StackOut <- stack(Rout,Gout,Bout)

#writeRaster(StackOut,filename="out.tif",overwrite=TRUE,options="compress=deflate")
writeRaster(StackOut,filename=outfile
            ,datatype="INT2S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
