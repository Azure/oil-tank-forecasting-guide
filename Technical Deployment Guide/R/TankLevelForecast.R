#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelForecast.R

# Call the web service that forecasts a tank level using new data.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packpages and define functions.
# 2. Set parameters.
# 3. Forecast the tank level.

# Null statement.
invisible(NULL)

#-----------------------------------------------------------------------
# 1. Load packpages and define functions.
#-----------------------------------------------------------------------

suppressPackageStartupMessages(library("rjson", quietly = TRUE,
                                       warn.conflicts = FALSE))

suppressWarnings(source("CallService.R"))

# Call the Tank Level model forecasting service.
Forecast <- function(ws, query, ...) {
    # Create the GlobalParameters structure.
    GlobalParameters <- list("Database query" = query)
    # Obtain the outputs results.
    Batch(ws, GlobalParameters = GlobalParameters, ...)
}

#-----------------------------------------------------------------------
# 2. Set parameters.
#-----------------------------------------------------------------------

# Forecasting service access parameters.
dataDir <- "Data"
epService <-
    fromJSON(paste(readLines(file.path(dataDir,
                                       "TankLevelForecasting.json")),
                   collapse = ""))

# The SQL query for data to use in forecasting.
dataQueryFormat <-
    "SELECT *
     FROM [dbo].[TankLevelSensor]
     WHERE [Time] >= '%s' AND [Time] < '%s';"

# The dates for the data.
fromDate <- "1970/2/5"
toDate <- "1970/2/9"

#-----------------------------------------------------------------------
# 3. Forecast the tank level.
#-----------------------------------------------------------------------

# Create the data query.
dataQuery <- sprintf(dataQueryFormat, fromDate, toDate)

# Forecast using the model.
Forecast(epService, dataQuery, verbose = TRUE)