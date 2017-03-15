#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelData.R

# Use a data sample from an oil tank facility to generate data for
# multiple facilities.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packpages.
# 2. Import data.
# 3. Run the script on the data.
# 4. Export results.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Load packpages.
#-----------------------------------------------------------------------

suppressPackageStartupMessages(library("rjson", quietly = TRUE,
                                       warn.conflicts = FALSE))

#-----------------------------------------------------------------------
# 2. Import data.
#-----------------------------------------------------------------------

# Read the raw data.
dataDir <- "Data"
dataset <- read.csv(file.path(dataDir, "TankLevelGenerator.csv"),
                    colClasses = c(Time = "POSIXct"))

# Define data generation parameters.
dataset2 <- data.frame(Facilities = 50, NoiseFactor = 200)

#-----------------------------------------------------------------------
# 3. Generate the data.
#-----------------------------------------------------------------------

source("TankLevelDataScript.R")

#-----------------------------------------------------------------------
# 4. Export results.
#-----------------------------------------------------------------------

write.csv(datasetOut, file = file.path(dataDir, "TankLevelData.csv"),
          quote = FALSE, row.names = FALSE)