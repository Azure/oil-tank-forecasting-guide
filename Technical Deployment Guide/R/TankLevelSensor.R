#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelSensor.R

# Use a data sample from an oil tank facility to generate data for
# multiple facilities.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packpages.
# 2. Import data.
# 3. Generate the data file.
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

# Database access parameters.
dataDir <- "Data"
dbParameters <-
    fromJSON(paste(readLines(file.path(dataDir,
                                       "TankLevelDatabase.json")),
                   collapse = ""))

#-----------------------------------------------------------------------
# 3. Generate the data file.
#-----------------------------------------------------------------------

if (!file.exists(file.path(dataDir, "TankLevelData.csv"))) {
    source("TankLevelData.R")
}

#-----------------------------------------------------------------------
# 4. Export results.
#-----------------------------------------------------------------------

# Create the bulk copy command string. This starts importing with the
# second row of the .csv to skip the header line.
command <-
    paste("bcp",
          "dbo.TankLevelSensor", # Table
          "in",
          file.path(dataDir, "TankLevelData.csv"), # Data file
          "-c", # Character-type
          "-t", ",", # Comma-separated.
          "-F", 2, # Start importing at row 2.
          "-d", dbParameters$Database,
          "-S", dbParameters$Server,
          "-U", dbParameters$Login,
          "-P", dbParameters$Password)

# Execute it.
system.time(system(command))