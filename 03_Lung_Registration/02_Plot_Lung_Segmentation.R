rm(list=ls())
library(cttools)
library(fslr)
options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl on local 
## machine.
library(plyr)
#install_github("muschellij2/WhiteStripe")
#install_github("muschellij2/extrantsr")
library(WhiteStripe)
library(extrantsr)
##options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
## Note:  matlab.path is for the tilt; it looks as that the DICOM lung files
## were not taken as a tilt.  John opened up some characteristic file in 
## Osirix and confirmed it.
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
lungdir = file.path(basedir, "lungs")

outdir = file.path(basedir, "lung_plots")

niis = list.files(pattern=".nii.gz", recursive = FALSE, 
                  path=lungdir, full.names = TRUE)
niis = niis[!grepl("Mask", nii.stub(niis))]

iimg = 1
for (iimg in seq_along(niis)){
  nii = niis[iimg]
  img = readNIfTI(nii, reorient = FALSE)
  stub = nii.stub(nii, bn=TRUE)
  pngname = file.path(outdir, paste0(stub, ".png"))
  
  #######################
  # Multiply by -1 for plotting
  #######################
  #img = img * -1
  ## center of gravity
  xyz = cog(abs(img), ceil = TRUE)
  img[img == 0] = NA

  png(pngname)
    orthographic(img, xyz=xyz)
  dev.off()
  print(iimg)
}
