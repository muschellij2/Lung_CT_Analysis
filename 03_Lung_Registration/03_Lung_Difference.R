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
diffdir = file.path(basedir, "Differences")


niis = list.files(pattern="_CT_*.nii.gz$", 
                  path = basedir, full.names= TRUE)
# imgs = llply(niis, readNIfTI, .progress= "text")
# names(imgs) = niis

# adder = "_SPM"
adder = ""

lung.files = file.path(outdir, nii.stub(niis, bn=TRUE))
lung.files = paste0(lung.files, adder, "_LungSeg.nii.gz")

fixed = lung.files[1]
lung.files = lung.files[-1]

temp.fixed = readNIfTI(fixed, reorient=FALSE)
temp.mask = paste0(nii.stub(fixed), "_Mask")
temp.mask = readNIfTI(temp.mask, reorient=FALSE)

typeofTransforms = c("Affine", "Rigid", "SyN")

itype = 1
ifile = 1

for (itype in seq_along(typeofTransforms)){
  typeofTransform = typeofTransforms[itype]

  for (ifile in seq_along(lung.files)){
    infile = lung.files[ifile]
    infile = nii.stub(infile, bn = TRUE)
    reg.file = file.path(regdir, infile)
    reg.file = paste0(reg.file, "_Registered_", 
      typeofTransform, ".nii.gz")

    reg.img = readNIfTI(reg.file, reorient=FALSE)
    dimg = niftiarr(temp.fixed, reg.img - temp.fixed)
    dimg[temp.mask == 0] = NA

    m = mean(dimg[temp.mask == 1])
    s = sd(dimg[temp.mask == 1])
    zimg = niftiarr(dimg, (dimg - m)/s)
    pngstub = file.path(diffdir, 
      paste0(nii.stub(reg.file, bn=TRUE)))

    pngname = paste0(pngstub, ".png")
    png(filename = pngname)
      orthographic(dimg, text="Difference Image")
    dev.off()

    pngname = paste0(pngstub, "_Diff_Z2.png")
    png(filename = pngname)
      mask.overlay(dimg, cal_img(zimg > 2), 
        text="Difference Image\n with Z > 2")
    dev.off()

    print(ifile)
  }
}