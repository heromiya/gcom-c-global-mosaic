## install.packages("rgdal")
## install.packages("raster")
library("rgdal")
library("raster")

args = commandArgs(trailingOnly=TRUE)

paste(date(),"Loading inputs")

R <- stack(args[1])
G <- stack(args[2])
B <- stack(args[3])

outfile <- args[4]

ysize <- dim(R)[1]
xsize <- dim(R)[2]
ndays <- dim(R)[3]

rotate <- function(x) apply(t(x),2,rev)
flip <- function(m) m[c(nrow(m):1),]

paste(date(),"Converting inputs")

input <- array(
    c(values(B)
     ,values(G)
     ,values(R)
      )
   ,dim=c(xsize,ysize,ndays,3)
)
                                        #input[input < th] <- NA

composite <- function(x){
    R = median(x[,3],na.rm=TRUE)
    G = median(x[,2],na.rm=TRUE)
    B = median(x[,1],na.rm=TRUE)
    c(R,G,B)
}

paste(date(),"Merging.")

out <- apply(input,c(1,2),composite)
rm(input)

paste(date(),"Exporting.")

Rout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Rout) <- extent(R)
values(Rout) <- flip(rotate(out[3,,]))
rm(R)

writeRaster(Rout,filename=paste(outfile,".R.tif",sep="")
           ,datatype="FLT4S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)

rm(Rout)

Gout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Gout) <- extent(G)
values(Gout) <- flip(rotate(out[2,,]))
rm(G)

writeRaster(Gout,filename=paste(outfile,".G.tif",sep="")
           ,datatype="FLT4S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)

rm(Gout)

Bout <- raster(ncol=xsize, nrow=ysize, crs=NA)
extent(Bout) <- extent(B)
values(Bout) <- flip(rotate(out[1,,]))
rm(B)

writeRaster(Bout,filename=paste(outfile,".B.tif",sep="")
           ,datatype="FLT4S"
           ,options="COMPRESS=Deflate"
           ,overwrite=TRUE)
rm(Bout)

if(FALSE){
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
}
