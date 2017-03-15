#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelFeaturesScript.R

# Use a sample of irregular sensor values from multiple oil facilities
# to generate regular features for modeling.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packages and define functions.
# 2. Create features.

#-----------------------------------------------------------------------
# 1. Load packages and define functions.
#-----------------------------------------------------------------------

# Load the needed packages.
suppressPackageStartupMessages(library("zoo", quietly = TRUE,
                                       warn.conflicts = FALSE))

# Create a regular time series for a facility.
RegularTimeSeries <- function(dataset, by) {
    # Deduplicate for time.
    dataDedupTs <-
        # Split the data by sensor.
        lapply(split(dataset, dataset$Sensor),
               function(data) {
                   # Exclude duplicate times.
                   uniqueData <- subset(data, !duplicated(Time))
                   # Make a time series.
                   with(uniqueData, zoo(Value, Time))
               })
    # Keep only time series with more than 1 value.
    dataDropTs <- dataDedupTs[sapply(dataDedupTs, NROW) > 1]
    # Merge the sensor values as time series.
    dataMergeTs <- do.call(merge, dataDropTs)
    # Use linear interpolation to create a regular
    # time series object from the data.
    dataRegularTs <-
        na.approx(dataMergeTs,
                  xout = seq(from = min(index(dataMergeTs)),
                             to = max(index(dataMergeTs)),
                             by = by))
    # Create a data frame from the regular data.
    dataOut <-
        data.frame(FacilityId = dataset$FacilityId[1],
                   Time = index(dataRegularTs),
                   dataRegularTs)
    dataOut
}

# Summarize values from multiple sensors of the same type.
Summarize <- function(dataset, name,
                      summaries =
                       c(Min = "min", Max = "max", Mean = "mean",
                         Median = "median", Sd = "sd"), ...) {
    result <-
        t(apply(dataset, 1,
                function(x) {
                    sapply(summaries, do.call, list(x, ...))
                }))
    colnames(result) <- paste0(name, colnames(result))
    result
}

# Create lagged features for a facility.
LagFeature <- function(dataset, name, Lag, tag = "Lag", m = 1) {
    # Embed name in a Lag-dimensional space.
    featureEmbed <- embed(as.matrix(dataset[, name, drop = FALSE]), Lag)
    colnames(featureEmbed) <-
        paste0(name, rep(paste0(tag, m * 1:Lag), each = length(name)))
    # Drop the lagged rows from dataset.
    data.frame(dataset[(Lag + 1):nrow(dataset),, drop = FALSE],
               featureEmbed[ - nrow(featureEmbed),, drop = FALSE])
}

# Create a feature dataset from a sensor dataset from one facility.
# Lag tank levels every Resolution minutes up to (Resolution * Lag) minutes.
CreateFeaturesFacility <- function(dataset,
                                   Lag,
                                   Resolution,
                                   # Variable name patterns.
                                   sensorPat,
                                   sensorTypePat,
                                   sensorSummaries,
                                   tankPat,
                                   datasetEmpty) {
    # Create features from the data.
    CreateDataFeatures <- function() {
        # Create regular time series.
        datasetRegular <-
            RegularTimeSeries(dataset,
                              by = as.difftime(Resolution, units = "mins"))
        # Create the mean of the tank levels, and summaries by sensor type.
        sensorIndex <- grep(sensorPat, names(datasetRegular))
        tankIndex <- grep(tankPat, names(datasetRegular))
        datasetMean <-
            data.frame(# Drop the sensor values and tank levels.
                       datasetRegular[, - c(sensorIndex, tankIndex),
                                       drop = FALSE],
                       # Add summaries by sensor type.
                       do.call(cbind,
                               lapply(sensorTypePat,
                                       function(name) {
                                           colIndex <-
                                               grep(name,
                                                    names(datasetRegular))
                                           Summarize(datasetRegular[, colIndex,
                                                                   drop = FALSE],
                                                     name,
                                                     summaries = sensorSummaries,
                                                     na.rm = TRUE)
                                       })),
                       # Add the mean of the tank levels.
                       TankLevel = rowMeans(datasetRegular[, tankIndex,
                                                           drop = FALSE]))
        # Lag the tank levels.
        datasetLag <- LagFeature(datasetMean, tankPat, Lag, "Lag", Resolution)
        # Remove rows with missing values.
        datasetLag <- na.omit(datasetLag)
        # Return the results.
        datasetLag
    }
    # Create the features.
    datasetOut <- tryCatch(CreateDataFeatures(),
                           error = function(...) { datasetEmpty })
    # The feature data.
    datasetOut
}

# Create a feature dataset from a sensor dataset.
CreateFeatures <- function(dataset, dataset2,
                           # Lag tank levels every Resolution minutes up
                           # to (Resolution * Lag) minutes.
                           Lag = dataset2$Lag,
                           Resolution = dataset2$Resolution,
                           # Variable name patterns.
                           leadingCols = 1:2,
                           sensorPat = "Sensor",
                           sensorTypes = LETTERS[1:4],
                           sensorTypePat = paste0(sensorPat, sensorTypes),
                           sensorSummaries = c(Min = "min",
                                               Max = "max",
                                               Mean = "mean",
                                               Median = "median",
                                               Sd = "sd"),
                           tankPat = "TankLevel") {
    # Create an empty dataset for error return.
    sensorNames <- unlist(sapply(sensorTypePat,
                                 paste0, names(sensorSummaries),
                                 simplify = FALSE))
    tankNames <- c(tankPat, paste0(tankPat, "Lag", Resolution * 1:Lag))
    featureNames <- c(sensorNames, tankNames)
    featureCols <- setNames(rep(list(numeric(0)), length(featureNames)),
                            featureNames)
    datasetEmpty <- data.frame(dataset[ - (1:nrow(dataset)),
                                       leadingCols, drop = FALSE],
                               featureCols)
    # Create features from each facility's data.
    datasetOut <-
        do.call(rbind,
                lapply(split(dataset, dataset$FacilityId),
                       CreateFeaturesFacility,
                       Lag, Resolution, sensorPat, sensorTypePat,
                       sensorSummaries, tankPat, datasetEmpty))
    # Warn if the feature data are empty.
    if (is.null(datasetOut)) {
        datasetOut <- datasetEmpty
    }
    if (nrow(datasetOut) == 0) {
        warning("Featurization resulted in an empty dataset.")
    }
    # The feature data.
    datasetOut
}

#-----------------------------------------------------------------------
# 2. Create features.
#-----------------------------------------------------------------------

datasetOut <- CreateFeatures(dataset, dataset2)