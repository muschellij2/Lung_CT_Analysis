rm(list=ls())
library(cttools)
library(fslr)
options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl on local machine.
library(plyr)
##options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
## Note:  matlab.path is for the tilt; it looks as that the DICOM lung files
## were not taken as a tilt.  John opened up some characteristic file in Osirix and confirmed it.
## Need to ask him exactly what and how that was confirmed.

user = Sys.info()[["user"]]
if ( grepl("musch", user)) {
  rootdir = "~/Dropbox/_LoriLungs (3)/"
  options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
} else {
  rootdir = "~/Dropbox/Professional/_LoriLungs"  
  options(matlab.path='/Applications/MATLAB_R2014a.app/bin')
}
## need ABSOLUTE path (relative breaks code)
rootdir = path.expand(rootdir)

basedir = file.path(rootdir, "NIfTI")
outdir = file.path(basedir, "lungs")


niis = list.files(pattern="_CT_*.nii.gz$", 
                  path = basedir, full.names= TRUE)
imgs = llply(niis, readNIfTI, .progress= "text")
names(imgs) = niis

sapply(imgs, hist, breaks=2000)

## what does this do? -- nothing -- need matlab  try on cluster
## try to get software on macbook
##lmask = CT_lung_mask(img = imgs[[1]])

## what does this do? - simple threshold and print the threshold to png
for (i in seq_along(imgs)){
  pngname = paste0(nii.stub(names(imgs)[i]), ".png")
  png(pngname)                       
    lrough = imgs[[i]]
    lrough = niftiarr(lrough, lrough >= -900 & lrough <= -150)
    ## if you just run this line, not in loop, but with correct i value,
    ## it produces "plot" in R.
    mask.overlay(imgs[[i]], lrough)
  dev.off()
  print(i)
}

## first apply rough threshold.  Then do a refined mask and get rid of extra material.
##par(mfrow=c(1,2)) ##no-go in RStudio
mask.overlay(imgs[[1]], lrough)
lmask = segment_lung(img = imgs[[1]])
mask.overlay(imgs[[1]], lmask)

## run segment_lung on each image
lmasks = llply(niis, function(x){
  ostub = file.path(nii.stub(x, bn=TRUE))
  ostub = paste0(ostub, "_lung")
  segment_lung(img = x, outfile = ostub)
}, .progress = "text")
