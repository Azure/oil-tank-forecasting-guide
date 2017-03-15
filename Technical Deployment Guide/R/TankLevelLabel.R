#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelLabel.R

# Generate a label for modeling.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Import data.
# 2. Create the label.
# 3. Export results.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Import data.
#-----------------------------------------------------------------------

# Read the data.
dataDir <- "Data"
dataset <- read.csv(file.path(dataDir, "TankLevelFeatures.csv"),
                    colClasses = c(Time = "POSIXct"))

# Define label creation parameters.
dataset2 <- data.frame(Lead = 24)

#-----------------------------------------------------------------------
# 2. Create the label.
#-----------------------------------------------------------------------

source("TankLevelLabelScript.R")

#-----------------------------------------------------------------------
# 3. Export results.
#-----------------------------------------------------------------------

write.csv(datasetOut, file = file.path(dataDir, "TankLevelLabel.csv"),
          quote = FALSE, row.names = FALSE)