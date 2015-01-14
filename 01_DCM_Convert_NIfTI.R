rm(list=ls())
## this chunk is real special; allows me VIP access to THE 
# John Muschelli's private CTTools
library(devtools)
# options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl on local machine.
# install_github("cttools", username="muschellij2", auth_user="swihart",
#                auth_token="2c0bd630bc0c2bd8d66d155d7af1885022da68a3")
library(cttools)
install_dcm2nii()

library(cttools)
library(fslr)
library(plyr)
##options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
## Note:  matlab.path is for the tilt; it looks as that the DICOM lung files
## were not taken as a tilt.  
# John opened up some characteristic file in Osirix and confirmed it.
## Need to ask him exactly what and how that was confirmed.

user = Sys.info()[["user"]]
# if ( grepl("musch", user)) {
#   rootdir = "~/Desktop/Lungs"
#   options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
# } else {
#   rootdir = "~/Desktop/Lungs"  
#   options(matlab.path='/Applications/MATLAB_R2014a.app/bin')
# }
rootdir = "/dcs01/oasis/biostat/bswihart"
## need ABSOLUTE path (relative breaks code)
rootdir = path.expand(rootdir)
homedir = file.path(rootdir, "data")

ids = list.dirs(homedir, recursive=FALSE, full.names=FALSE)
ids = basename(ids)
length(ids)


ROIformat = FALSE
#### setting up if things are on the cluster or not
verbose =TRUE
untar = FALSE
convert <- TRUE
skullstrip <- FALSE
plotss = TRUE
regantry <- FALSE
untgantry <- FALSE
runall <- TRUE
useRdcmsort= TRUE
useRdcm2nii= FALSE
removeDups = TRUE
isSorted = NULL
useOro = FALSE ## false means we're using dcm; TRUE means we're using oro
if (ROIformat) isSorted = FALSE
dcm2niicmd = "dcm2nii_2009"


iid = 1
# basedir = file.path(rootdir, "NIfTI")

for (iid in seq_along(ids)){

  id = ids[iid]

  basedir = file.path(homedir, id)
  ### time for conversion
  contime <- NULL
  gf = getfiles(basedir)
  ## check gf list...
  names(gf)
  length(gf)
  ## files in first slot
  head(gf[[1]])
  ## paths in second slot
  head(gf[[2]])

  # dcmsortopt <- ifelse(id %in% c("301-520", "191-309"), 
  #     '-s ', "")
  dcmsortopt = "-s "

  ## contime took __ time on NIH Macbook with files on H drive
  ## this creates some folders...   ./Sorted and 
  ## writes a crapload of .dcm in the rootdir and then 
  # they get compressed (I think...)
  ## contime is around 57 seconds:
  ## it does print "sh: fslmerge: command not found" when executed in RStudio
  contime <- system.time(convert_DICOM(basedir, 
                          verbose=verbose, untar=untar, 
                          useRdcmsort= useRdcmsort, 
                          useRdcm2nii= useRdcm2nii,
                          id = id, 
                          isSorted = isSorted,
                          removeDups=removeDups,
                          dcmsortopt=dcmsortopt, 
                          ROIformat = ROIformat,
                          dcm2niicmd=dcm2niicmd,
                          dcmsortopt = dcmsortopt,
                          useStudyDate = FALSE,
                          useOro= useOro,
                          rescale=FALSE))


  files = list.files(basedir, pattern="_CT_.*.nii.gz", 
    full.names=TRUE)
  min.val = -1024
  max.val = 3071
  # bad = sapply(files, function(x) {
  #   r = fslrange(x)
  #   check = r[1] < min.val | r[2] > max.val
  #   check
  # })
  # files = files[bad]
  if (length(files) > 0){
    for (ifile in files){
      rescale_img(ifile, min.val=min.val, 
        max.val = max.val)
    }
  }

}