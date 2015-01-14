rm(list=ls())
library(cttools)
library(fslr)
options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl on local 
## machine.
library(plyr)
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
outdir = file.path(basedir, "lungs")
regdir = file.path(basedir, "Registered")


niis = list.files(pattern="_CT_*.nii.gz$", 
                  path = basedir, full.names= TRUE)
# imgs = llply(niis, readNIfTI, .progress= "text")
# names(imgs) = niis

lung.files = file.path(outdir, nii.stub(niis, bn=TRUE))
lung.files = paste0(lung.files, "_SPM_LungSeg.nii.gz")

fixed = lung.files[1]
lung.files = lung.files[-1]

temp.fixed = readNIfTI(fixed, reorient=FALSE)

typeofTransform = "Affine"

ifile = 1
for (ifile in seq_along(lung.files)){
  infile = lung.files[ifile]
  reg.file = file.path(regdir, nii.stub(infile, bn = TRUE))
  reg.file = paste0(reg.file, "_Registered_", 
    typeofTransform, ".nii.gz")

  if (!file.exists(reg.file)){
    ants_regwrite(filename = infile, retimg = FALSE,
      outfile = reg.file, template.file = fixed,
      interpolator = "Linear",
      remove.warp = TRUE,
      typeofTransform = typeofTransform   
      )
  }
  print(ifile)
}