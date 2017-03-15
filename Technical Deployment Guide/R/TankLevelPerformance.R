#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelPerformance.R

# Report the forecasting performance of the algorithms used.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Import data.
# 2. Report performance.
# 3. Export results.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Import data.
#-----------------------------------------------------------------------

# Read the forecast data.
dataDir <- "Data"
dataset <- read.csv(file.path(dataDir, "TankLevelForecast.csv"),
                    colClasses = c(Time = "POSIXct"))

#-----------------------------------------------------------------------
# 2. Report performance.
#-----------------------------------------------------------------------

pdf(file.path(dataDir, "TankLevelForecast.pdf"))
source("TankLevelPerformanceScript.R")
dev.off()

#-----------------------------------------------------------------------
# 3. Export results.
#-----------------------------------------------------------------------

write.csv(datasetOut, file.path(dataDir, "TankLevelPerformance.csv"),
          quote = FALSE, row.names = FALSE)