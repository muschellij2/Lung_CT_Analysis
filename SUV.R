SUV = function (pixelData, mask = NULL, CSV = NULL, seriesNumber = NULL, 
    method = c("qiba", "user"), prior = NULL, decayedDose = NULL) 
{
    if (method[1] == "user") {
        suv <- array(NA, dim(pixelData))
        suv[mask] <- pixelData[mask]/prior$dose * prior$mass
        return(suv)
    } else {
        if (is.null(CSV)) {
            stop("CSV file from dicomTable() is required")
        }
        if (is.null(seriesNumber)) {
            stop("SeriesNumber of PET acquisition is required")
        }
        csv <- CSV[CSV[, "X0020.0011.SeriesNumber"] == seriesNumber, 
            ]
        hdr <- vector(mode = "list")
        hdr$correctedImage <- unique(csv[, "X0028.0051.CorrectedImage"])
        hdr$decayCorrection <- unique(csv[, "X0054.1102.DecayCorrection"])
        hdr$units <- unique(csv[, "X0054.1001.Units"])
        hdr$seriesDate <- as.character(unique(csv[, "X0008.0021.SeriesDate"]))
        hdr$seriesTime <- as.character(unique(csv[, "X0008.0031.SeriesTime"]))
        hdr$acquisitionDate <- as.character(unique(csv[, "X0008.0022.AcquisitionDate"]))
        hdr$acquisitionTime <- as.character(unique(csv[, "X0008.0032.AcquisitionTime"]))
        hdr$radiopharmaceuticalStartTime <- unique(csv[, "X0054.0016.0018.1072.RadiopharmaceuticalStartTime"])
        hdr$radionuclideTotalDose <- unique(csv[, "X0054.0016.0018.1074.RadionuclideTotalDose"])
        hdr$radionuclideHalfLife <- unique(csv[, "X0054.0016.0018.1075.RadionuclideHalfLife"])
        hdr$patientsWeight <- unique(csv[, "X0010.1030.PatientsWeight"])
        hdr$rescaleIntercept <- as.numeric(csv[, "X0028.1052.RescaleIntercept"])
        hdr$rescaleSlope <- as.numeric(csv[, "X0028.1053.RescaleSlope"])
        hdr$instanceNumber <- as.numeric(csv[, "X0020.0013.InstanceNumber"])
        if (length(hdr$instanceNumber) != length(unique(hdr$instanceNumber))) {
            warning("InstanceNumber is not a unique identifier")
        }
        ino <- order(hdr$instanceNumber)
        if (!is.null(prior)) {
            for (i in 1:length(prior)) {
                j <- which(names(hdr) %in% names(prior)[i])
                hdr[[j]] <- prior[[i]]
            }
        }
        if (grepl("ATTN", hdr$correctedImage) && grepl("DEC*Y", 
            hdr$correctedImage) && hdr$decayCorrection == "START") {
            
            if (oro.dicom::str2date(hdr$seriesDate) <= 
                oro.dicom::str2date(hdr$acquisitionDate) && 
              all(oro.dicom::str2time(hdr$seriesTime)$time <= 
                oro.dicom::str2time(hdr$acquisitionTime)$time)) {
              scanDate <- hdr$seriesDate
              scanTime <- hdr$seriesTime
            } else {
              stop("GE private scan Date and Time")
            }

            startTime <- hdr$radiopharmaceuticalStartTime
            decayTime <- oro.dicom::str2time(scanTime)$time - 
              oro.dicom::str2time(startTime)$time
            halfLife <- as.numeric(hdr$radionuclideHalfLife)
            injectedDose <- as.numeric(hdr$radionuclideTotalDose)
            if (is.null(decayedDose)) {
                  decayedDose <- injectedDose * 2^(-decayTime/halfLife)
                }
            weight <- as.numeric(hdr$patientsWeight)

            if (hdr$units == "CNTS") {
              findstr = "X7053.1000."
              cn = colnames(csv)
              ccn = grep(findstr, cn, fixed=TRUE, value=TRUE)
              if (length(ccn) > 1){
                newstr = paste0(findstr, "Data")
                if (!newstr %in% cn){
                    stop("not knowing where scaling is")
                } else {
                    findstr = newstr
                }
              } else {
                findstr = ccn
              }
              SUVbwScaleFactor = as.numeric(csv[, findstr])
              SUVbwScaleFactor = unique(SUVbwScaleFactor)
              stopifnot(length(SUVbwScaleFactor) == 1)
              if (is.na(SUVbwScaleFactor)){
                stop("Philips private scale factor")
              }
              stopifnot(SUVbwScaleFactor != 0)
          }
            if (hdr$units == "GML") {
                    SUVbwScaleFactor <- 1
            }
            if (hdr$units == "BQML") {
                SUVbwScaleFactor <- (weight * 1000/decayedDose)
            } 
            SUVbw <- array(0, dim(pixelData))
            nslices <- oro.nifti::nsli(pixelData)
            for (i in 1:length(hdr$rescaleSlope)) {
                z <- (i - 1)%%nslices + 1
#                 w <- (i - 1)%/%nslices + 1
                j <- ino[i]
#                 SUVbw[, , z, w] <- (pixelData[, , z, w] * hdr$rescaleSlope[j] * 
#                   SUVbwScaleFactor) + hdr$rescaleIntercept[j]
                SUVbw[, , z] <- (pixelData[, , z] * hdr$rescaleSlope[j] * 
                      SUVbwScaleFactor) + hdr$rescaleIntercept[j]
            }
            list(SUVbw = SUVbw, hdr = hdr, decayTime = decayTime, 
                decayedDose = decayedDose, SUVbwScaleFactor = SUVbwScaleFactor)
        } else {
            stop("ATTN, START, DEC*Y... failed")
        }
    }
}