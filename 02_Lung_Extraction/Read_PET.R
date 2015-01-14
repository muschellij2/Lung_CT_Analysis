rm(list=ls())
library(cttools)
library(fslr)
options(fsl.path="/usr/local/fsl")  ## need to put this in for fsl 
## machine.
library(plyr)
##options(matlab.path='/Applications/MATLAB_R2013b.app/bin')
## Note:  matlab.path is for the tilt; it looks as that the DICOM
## files
## were not taken as a tilt.  John opened up some characteristic  
##in 
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
progdir = file.path(rootdir, "programs")
source(file.path(progdir, "SUV.R"))
homedir = file.path(rootdir, "data")

ids = list.dirs(homedir, recursive=FALSE, full.names=FALSE)
ids = basename(ids)
length(ids)

rerun = TRUE
iid = 1
# basedir = file.path(rootdir, "NIfTI")

# for (iid in seq_along(ids)){

  id = ids[iid]

  basedir = file.path(homedir, id)

  niis = list.files(pattern="_PT_.*.nii.gz$", 
                    path = basedir, full.names= TRUE)
  # imgs = llply(niis, readNIfTI, .progress= "text")
  # names(imgs) = niis

  ## what does this do? -- nothing -- need matlab  try on cluster
  ## try to get software on macbook
  ##lmask = CT_lung_mask(img = imgs[[1]])

  ## what does this do? - simple threshold and print the threshold
  i = 1

pet_df = function(dcmtables){
    colnames(dcmtables) = paste0("X", colnames(dcmtables))
    colnames(dcmtables) = gsub("-", ".", colnames(dcmtables))
    cn = colnames(dcmtables)
    if (!"X0054.0016.0018.1072.RadiopharmaceuticalStartTime" %in% cn){
    dcmtables[, "X0054.0016.0018.1072.RadiopharmaceuticalStartTime"] = 
        dcmtables[, "X0018.1072.RadiopharmaceuticalStartTime"]
    }
    if (!"X0054.0016.0018.1074.RadionuclideTotalDose" %in% cn){
      dcmtables[, "X0054.0016.0018.1074.RadionuclideTotalDose"] = 
         as.numeric(dcmtables[, "X0018.1074.RadionuclideTotalDose"])
    }
    if (!"X0054.0016.0018.1075.RadionuclideHalfLife" %in% cn){
      dcmtables[, "X0054.0016.0018.1075.RadionuclideHalfLife"] = 
         as.numeric(dcmtables[, "X0018.1075.RadionuclideHalfLife" ])
    }
    if (!"X0010.1030.PatientsWeight" %in% cn){
      dcmtables[, "X0010.1030.PatientsWeight"] = 
        as.numeric(dcmtables[, "X0010.1030.PatientWeight" ])
    }
    cols = c("X0054.0016.0018.1074.RadionuclideTotalDose",
      "X0054.0016.0018.1075.RadionuclideHalfLife", 
      "X0010.1030.PatientsWeight")
    for (icol in cols){
      dcmtables[, icol] = as.numeric(dcmtables[, icol])
    }
    dcmtables[, "X0028.1053.RescaleSlope"] = as.numeric(
      dcmtables[, "X0028.1053.RescaleSlope"])
    dcmtables[, "X0028.1052.RescaleIntercept"] = as.numeric(
      dcmtables[, "X0028.1052.RescaleIntercept"])
    return(dcmtables)
}

x = readDICOM('/Users/johnmuschelli/Desktop/Lungs/data/A225/Sorted/A225_20120806_1056_PT_198590_CHEST_ITRC__p1591s2_wb_ctac.img_/')
dcmtables = dicomTable(x$hdr)
dcmtables = pet_df(dcmtables)
seriesnum = dcmtables[1, "X0020.0011.SeriesNumber"]
img = array(NA, dim= c(144, 144, length(x$img)))
for (i in 1:87) img[,,i] = x$img[[i]]
dim(img) = c(dim(img), 1)

suv = SUV(pixelData = img, 
  CSV = dcmtables, 
  seriesNumber = seriesnum)

dim(img) = dim(img)[1:3]
nim = readNIfTI('/Users/johnmuschelli/Desktop/Lungs/data/A225/A225_20120806_1056_PT_198590_CHEST_ITRC__p1591s2_wb_ctac.img_', 
  reorient=FALSE)
ap = aperm(suv$SUVbw[,,,1], c(2, 1, 3))
corr.img = niftiarr(nim, ap)


for (i in seq_along(niis)){

  img = readNIfTI(niis[i], reorient=FALSE)
  stub = nii.stub(niis[i], bn = TRUE)
  rda = file.path(basedir,
    "Sorted", paste0(stub, "_Header_Info.Rda"))
  load(rda)

  dcmtables = pet_df(dcmtables)

  seriesnum = dcmtables[1, "X0020.0011.SeriesNumber"]

  dim(img) = c(dim(img), 1)
  suv = SUV(pixelData = img, 
    CSV = dcmtables, 
    seriesNumber = seriesnum)
  dim(img) = dim(img)[1:3]
  corr.img = niftiarr(img, suv$SUVbw[,,,1])

  print(i)
}
   