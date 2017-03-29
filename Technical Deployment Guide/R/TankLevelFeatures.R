#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelFeatures.R

# Use a sample of irregular sensor values from multiple facilities
# to generate regular features for modeling.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Import data.
# 2. Create the features.
# 3. Export results.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Import data.
#-----------------------------------------------------------------------

# Read the data.
dataDir <- "Data"
dataset <- read.csv(file.path(dataDir, "TankLevelData.csv"),
                    colClasses = c(Time = "POSIXct"))
dataset <- subset(dataset, Time < "1970/1/15")

# Define feature creation parameters.
dataset2 <- data.frame(Resolution = 1, Lag = 60)

#-----------------------------------------------------------------------
# 2. Create the features.
#-----------------------------------------------------------------------

source("TankLevelFeaturesScript.R")

#-----------------------------------------------------------------------
# 3. Export results.
#-----------------------------------------------------------------------

write.csv(datasetOut, file = file.path(dataDir, "TankLevelFeatures.csv"),
          quote = FALSE, row.names = FALSE)