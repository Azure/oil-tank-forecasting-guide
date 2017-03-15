#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelDataScript.R

# Use a data sample from an oil tank facility to generate data for
# multiple facilities.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Define functions.
# 2. Generate data.

#-----------------------------------------------------------------------
# 1. Define functions.
#-----------------------------------------------------------------------

# Jitter the values of a sensor.
JitterSensor <- function(sensorData, ...) {
    sensorData$Value <- jitter(sensorData$Value, ...)
    sensorData
}

# Jitter the values for each sensor.
Jitter <- function(dataset, ...) {
    unsplit(lapply(split(dataset, dataset$Sensor),
                   JitterSensor,
                   ...),
           dataset$Sensor)
}

# Generate data.
# dataset = source data.
# dataset2 = Facilities and NoiseFactor.
# Facilities = The number of facility for which to generate data.
# NoiseFactor = The noise factor used in generating data.
GenerateData <- function(dataset, dataset2,
                         Facilities = dataset2$Facilities,
                         NoiseFactor = dataset2$NoiseFactor) {
    # Generate the dataset.
    datasetOut <-
        do.call(rbind,
                replicate(Facilities, dataset, simplify = FALSE))
    # Set individual facility Ids.
    datasetOut$FacilityId <-
        factor(paste0("facility",
                      rep(1:Facilities, each = nrow(dataset))))
    # Jitter the values by sensor.
    datasetOut <- Jitter(datasetOut, factor = NoiseFactor)
    ## Set the time to now.
    #datasetOut$Time <-
    #Sys.time() + (datasetOut$Time - min(datasetOut$Time))
    # The generated data.
    datasetOut
}

#-----------------------------------------------------------------------
# 2. Generate data.
#-----------------------------------------------------------------------

datasetOut <- GenerateData(dataset, dataset2)