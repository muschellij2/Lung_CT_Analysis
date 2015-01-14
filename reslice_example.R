rm(list=ls())
library(fslr)
library(cttools)
homedir = '/dcs01/oasis/biostat/bswihart'
progdir = file.path(homedir, "programs")
source(file.path(progdir, "SUV.R"))
files = c("A225_20120312_1035_CT_2_CHEST_ITRC__Body-Low.nii.gz",
	"A225_20120312_1034_PT_179490_CHEST_ITRC__p1591s1_wb_ctac.img_.nii.gz"	)

images = lapply(files, readNIfTI, reorient = FALSE)
orig.pet = readNIfTI(files[2], reorient=FALSE)

rda = paste0("Sorted/", 
	nii.stub(files[2], bn=TRUE), 
	"_Header_Info.Rda")
load(rda)
data = dcmtables

find.col = function(data, col, col2){
  cn = colnames(data)
  if (!col %in% cn){
    stopifnot(col2 %in% cn)
    data[, col] = data[, col2]
  }
  data
}

make_suv_data = function(img, data){
	cn = colnames(data)
	cn = gsub("-", ".", cn)
	nox = !grepl("^X", cn)
	cn[nox] = paste0("X", cn[nox])
	colnames(data) = cn	
  data = find.col(data, 
                  "X0054.0016.0018.1072.RadiopharmaceuticalStartTime",
                  "X0018.1072.RadiopharmaceuticalStartTime")
	data = find.col(data, 
	                "X0054.0016.0018.1074.RadionuclideTotalDose",
	                "X0018.1074.RadionuclideTotalDose")
	data <- find.col(data, 
	                 "X0054.0016.0018.1075.RadionuclideHalfLife",
	                 "X0018.1075.RadionuclideHalfLife")
	data <- find.col(data, 
	                 "X0010.1030.PatientsWeight", 
	                 "X0010.1030.PatientWeight")
	sn = unique(data[, "X0020.0011.SeriesNumber"])
	suv1 = SUV(pixelData=img, 
		CSV = data, 
		seriesNumber = sn)
	suv1$SUVbw = niftiarr(img, suv1$SUVbw)
	suv = suv1$SUVbw
	suv[suv < 0] = 0
	suv = cal_img(suv)
	suv = datatype(suv, type_string = "FLOAT32")
	suv
}

suv = make_suv_data(images[[2]], data=dcmtables)

images[[2]] = suv
# outfiles = sapply(1:length(files), function(x){
# 	tempfile(fileext = ".nii.gz")
# })

outfiles = tempfile(fileext = ".nii.gz")

spm_reslice(files = images, outfiles = outfiles)

ct = readNIfTI(files[1], reorient=FALSE)

pet = readNIfTI(outfiles[1], reorient=FALSE)


