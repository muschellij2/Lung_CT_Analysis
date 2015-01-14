rm(list=ls())
library(cttools)
library(plyr)
library(fslr)
library(dplyr)

user = Sys.info()[["user"]]
rootdir = "/dcs01/oasis/biostat/bswihart"
## need ABSOLUTE path (relative breaks code)
rootdir = path.expand(rootdir)
homedir = file.path(rootdir, "data")

ids = list.dirs(homedir, recursive=FALSE, full.names=FALSE)
ids = basename(ids)
length(ids)

iid = 9

data= NULL

for (iid in seq_along(ids)){

  id = ids[iid]
  basedir = file.path(homedir, id)
  sortdir = file.path(basedir, "Sorted")

  rdas = list.files(sortdir, pattern="Header_Info.Rda", 
  	full.names= TRUE)
  cn = "0020-000D-StudyInstanceUID"
  get.col = function(val, dcmtables){
  		cnames =colnames(dcmtables)
  	 if (val %in% cnames){
  		return(unique(dcmtables[, val]))
  	} else {
  		return(NA)
  	}  	
  }
  
  ######################################
  # Extracting relevant fields from dicomtable
  ######################################
  study.ids = sapply(rdas, function(x){
  	j = load(x)
  	sid = get.col(cn, dcmtables)
  	scat = get.col("0054-1105-ScatterCorrectionMethod", 
  		dcmtables)
  	scat = toupper(scat)
  	mod = get.col("0008-0060-Modality", 
  		dcmtables)
  	prot = get.col("0018-1030-ProtocolName", 
  		dcmtables)
  	so = get.col('0002-0016-SourceApplicationEntityTitle',
  		dcmtables)
  	ser.d = get.col('0008-103E-SeriesDescription',
  		dcmtables)
  	stud = get.col("0008-1030-StudyDescription", 
  		dcmtables)
  	com = get.col('0020-4000-ImageComments',
  		dcmtables)
  	corr = get.col("0028-0051-CorrectedImage", 
  		dcmtables)
  	cbind(rda = x, modality=mod, studyID = sid, scat = scat, 
  		nimgs = nrow(dcmtables), protocol = prot, source = so,
  		series = ser.d, study = stud, comment = com, 
  		corrected = corr)
  })

  study.ids = t(study.ids)
  rownames(study.ids) = NULL
  colnames(study.ids) = c("img", "modality", "studyID", 
  	"scatter", "nimgs", "protocol", "source", "series",
  	"study", "comment", "corrected")
	study.ids = data.frame(study.ids, stringsAsFactors=FALSE)

	study.ids$corrected[ is.na(study.ids$corrected) ] = ""
	### remove those PET not having "ATTN" for attenuated
	study.ids = ddply(study.ids, .(studyID), function(x){
		npt = sum(x$modality == "PT")
		if (npt > 1){
			x = x[ x$modality == "CT" | 
			(x$modality == "PT" & !grepl("ATTN", x$corrected) ),]
		}
		return(x)
	})
# check out ftp://medical.nema.org/medical/dicom/final/sup12_ft.pdf
#  
  study.ids$img = basename(study.ids$img)
  study.ids$img = sub("_Header_Info.Rda", ".nii.gz", study.ids$img, 
  	fixed=TRUE)
  study.ids$id = id
  data = rbind(data, study.ids)

}

	stopifnot(all(data$modality %in% c("CT", "PT")))

	######################
	# Getting number of CT and PT scans
	####################
  data = ddply(data, .(id, studyID), function(x){
  	x$nct = sum(x$modality == "CT")
  	x$npt = sum(x$modality == "PT")
  	x
  })

	######################
	# Deleting Non whole-body CT scans, for those with PET
	####################
  data$ind = seq(nrow(data))
  bad.ind = data$nct > 1 & data$npt == 1 & data$modality =="CT"

  bad = data[ bad.ind, ]
  grab = "Body-Low"
  bad = ddply(bad, .(id, studyID), function(x){
  	keep = (x$study %in% grab) | (x$comment %in% grab)
  	if (sum(keep) == 0) {
  		stop("Problem with CT bad")
  	}
  	x[!keep, ]
  })

  data = data[ !data$ind %in% bad$ind, ]

######################
# Check for dates with greater than one PET scan
####################
  data$ind = seq(nrow(data))
  bad.ind = data$npt > 1 
  stopifnot(all(!bad.ind))

## Getting date of scan
  data$date = sapply(strsplit(data$img, "_"), nth, n=2)
  data$instance = sapply(strsplit(data$img, "_"), nth, n=5)


#### Getting first scan if multiple from same modality on same day
  data$ind = NULL
  data = ddply(data, .(id, studyID, date, modality), function(x){
  	x$N = nrow(x)
  	x = x[order(x$date, x$instance), ]
  	x = x[1,]
  	x
  })
  wide = reshape(data=data, 
  	timevar = "modality", 
  	idvar = c("id", "studyID"), direction = "wide")


  if (!'img.CT' %in% colnames(wide)){
  	wide$img.CT = NA
  }
  if (!'img.PT' %in% colnames(wide)){
  	wide$img.PT = NA
  }  

  wide = wide[, c("img.CT", "img.PT", "id", "studyID")]
  # data = rbind(data, wide)
  
# }
# 
# data[ data$studyID== '1.2.840.113704.1.111.4472.1347628101.2',]