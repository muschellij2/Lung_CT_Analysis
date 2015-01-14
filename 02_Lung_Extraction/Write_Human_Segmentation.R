rm(list=ls())
library(cttools)
library(fslr)
options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl on local 
## machine.
library(plyr)
##options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
## Note:  matlab.path is for the tilt; it looks as that the DICOM lung files
## were not taken as a tilt.  John opened up some characteristic file in 
## Osirix and confirmed it.
## Need to ask him exactly what and how that was confirmed.

user = Sys.info()[["user"]]
if ( grepl("musch", user)) {
  rootdir = "~/Desktop/Lungs"
  options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
} else {
  rootdir = "~/Desktop/Lungs"
  options(matlab.path='/Applications/MATLAB_R2014a.app/bin')
}
## need ABSOLUTE path (relative breaks code)
rootdir = path.expand(rootdir)
homedir = file.path(rootdir, "data")

ids = list.dirs(homedir, recursive=FALSE, full.names=FALSE)
ids = basename(ids)
length(ids)

iid = 5
# basedir = file.path(rootdir, "NIfTI")

for (iid in seq_along(ids)){

  id = ids[iid]

  basedir = file.path(homedir, id)

  outdir = file.path(basedir, "human")
  if (!file.exists(outdir)){
    dir.create(outdir)
  }

  niis = list.files(pattern="_CT_.*.nii.gz$", 
                    path = basedir, full.names= TRUE)
  # imgs = llply(niis, readNIfTI, .progress= "text")
  # names(imgs) = niis

  ## what does this do? -- nothing -- need matlab  try on cluster
  ## try to get software on macbook
  ##lmask = CT_lung_mask(img = imgs[[1]])

  ## what does this do? - simple threshold and print the threshold to png
  i = 3
  for (i in seq_along(niis)){
    stub = nii.stub(niis[i], bn = TRUE)
    outfile = file.path(outdir, paste0(stub, "_Human"))
    ofile =  paste0(outfile, "_Mask")
    if ( !file.exists(paste0(ofile, ".nii.gz"))){
      lmask = CT_human_mask(
        img = niis[[i]], 
        outfile = ofile, 
        retimg = FALSE)
    }
    
    print(i)
  }
   
}

# ## first apply rough threshold.  Then do a refined mask and get rid of 
#  extra material.
# ##par(mfrow=c(1,2)) ##no-go in RStudio
# mask.overlay(imgs[[1]], lrough)
# lmask = segment_lung(img = imgs[[1]])
# mask.overlay(imgs[[1]], lmask)
# 
# ## run segment_lung on each image
# lmasks = llply(niis, function(x){
#   ostub = file.path(nii.stub(x, bn=TRUE))
#   ostub = paste0(ostub, "_lung")
#   segment_lung(img = x, outfile = ostub)
# }, .progress = "text")

