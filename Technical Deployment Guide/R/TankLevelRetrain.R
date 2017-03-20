#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelRetrain.R

# Call the web service that retrains the model using new data.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packages and define functions.
# 2. Set parameters.
# 3. Retrain the model.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Load packages and define functions.
#-----------------------------------------------------------------------

suppressPackageStartupMessages(library("rjson", quietly = TRUE,
                                       warn.conflicts = FALSE))

suppressWarnings(source("CallService.R"))

# Call the Tank Level model retraining service.
RetrainModel <- function(ws, query, iLearner, performance, ...) {
    # Create the Outputs structure.
    Outputs <- list("output1" = iLearner, "output2" = performance)
    # Create the GlobalParameters structure.
    GlobalParameters <- list("Database query" = query)
    # Obtain the outputs results.
    Batch(ws, Outputs = Outputs, GlobalParameters = GlobalParameters, ...)
}

#-----------------------------------------------------------------------
# 2. Set parameters.
#-----------------------------------------------------------------------

# Retraining service access parameters.
dataDir <- "Data"
exRetraining <-
    fromJSON(paste(readLines(file.path(dataDir,
                                       "TankLevelRetraining.json")),
             collapse = ""))

# Workspace storage access parameters.
wsStorage <-
    fromJSON(paste(readLines(file.path(dataDir,
                                       "TankLevelStorage.json")),
             collapse = ""))

# Prediction endpoint update access parameters.
epUpdate <-
    fromJSON(paste(readLines(file.path(dataDir,
                                       "TankLevelUpdating.json")),
             collapse = ""))

# The SQL query for data to use in retraining.
dataQueryFormat <-
    "SELECT *
     FROM [dbo].[TankLevelSensor]
     WHERE [Time] >= '%s' AND [Time] < '%s';"

# The dates for the data.
fromDate <- "1970/1/8"
toDate <- "1970/1/15"

# The storage account connection string.
connectionString <-
    paste(names(wsStorage), unlist(wsStorage), sep = "=",
         collapse = ";")

# The storage location for the trained learner.
iLearner <-
    list("ConnectionString" = connectionString,
         "RelativeLocation" = "/retraining/retrainedmodel.iLearner")

# The storage location for the learner's performance.
performance <-
    list("ConnectionString" = connectionString,
         "RelativeLocation" = "/retraining/retrainedperformance.csv")

#-----------------------------------------------------------------------
# 3. Retrain the model.
#-----------------------------------------------------------------------

# Create the data query.
dataQuery <- sprintf(dataQueryFormat, fromDate, toDate)

# Retrain the model.
retrainedModel <-
    RetrainModel(exRetraining, dataQuery, iLearner, performance,
                 verbose = TRUE)

#-----------------------------------------------------------------------
# 4. Update the forecasting endpoint with the retrained model.
#-----------------------------------------------------------------------

UpdateEndpoint(epUpdate, retrainedModel$output1[-1], verbose = TRUE)