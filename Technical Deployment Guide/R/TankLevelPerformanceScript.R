#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelPerformanceScript.R

# Report the forecasting performance of the algorithms used.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packages and define functions.
# 2. Get the names of the true value and the algorithms.
# 3. Plot each forecast over the actual values.
# 4. Compute each forecast's performance.

#-----------------------------------------------------------------------
# 1. Load packages and define functions.
#-----------------------------------------------------------------------

suppressPackageStartupMessages(library("zoo", quietly = TRUE,
                                       warn.conflicts = FALSE))

## Calculate the performance metrics. 
Performance <- function(forecast, actual) {
    N <- length(actual)
    meanActual <- mean(actual)
    SStot <- sum((actual - meanActual) ^ 2)
    SSres <- sum((actual - forecast) ^ 2)
    SAtot <- sum(abs(actual - meanActual))
    SAres <- sum(abs(actual - forecast))
    SAPE <- sum(abs((actual - forecast) / actual))
    MAE <- SAres / N
    MSE <- SSres / N
    RMSE <- sqrt(MSE)
    RAE <- SAres / SAtot
    RSE <- SSres / SStot
    CoD <- 1 - RSE
    MAPE <- sum(abs((actual - forecast) / actual)) / N
    c(MAE = MAE, RMSE = RMSE, RAE = RAE, RSE = RSE, CoD = CoD,
      MAPE = MAPE)
}

ComputePerformanceAlgorithm <- function(algorithm,
                                        forecast,
                                        actual,
                                        datasetEmpty,
                                        varNames) {
    # Compute the performance.
    datasetOut <- tryCatch(data.frame(Algorithm = algorithm,
                                      as.list(Performance(forecast, actual))),
                           error = function(...) { datasetEmpty })
    names(datasetOut) <- varNames
    # The performance statistics.
    datasetOut
}

# Compute each forecast's performance.
ComputePerformance <- function(dataset, modelY, algorithms,
                               algorithmName = "Algorithm",
                               performanceNames = c("Mean Absolute Error",
                                   "Root Mean Square Error",
                                   "Relative Absolute Error",
                                   "Relative Squared Error",
                                   "Coefficient of Determination",
                                   "Mean Absolute Percentage Error")) {
    # Create an empty dataset for error return.
    algorithmCol <- setNames(list(character(0)), algorithmName)
    performanceCol <- setNames(rep(list(numeric(0)),
                                   length(performanceNames)),
                               performanceNames)
    datasetEmpty <- data.frame(algorithmCol, performanceCol)
    # Compute each forecast's performance metrics.
    datasetOut <-
        do.call(rbind,
                lapply(algorithms,
                       function(algorithm, actual, varNames) {
                           ComputePerformanceAlgorithm(algorithm,
                                                       dataset[[algorithm]],
                                                       actual,
                                                       datasetEmpty,
                                                       varNames)
                       },
                       dataset[[modelY]],
                       c(algorithmName, performanceNames)))
    # Warn if the data are empty or any of the data are missing.
    if (is.null(datasetOut)) {
        datasetOut <- datasetEmpty
    }
    if (nrow(datasetOut) == 0 || any(is.na(datasetOut[, -1]))) {
        warning("Performance computation resulted in missing performance metrics.")
    }
    # The performance metrics.
    datasetOut
}

# Plot each forecast over actual.
PlotForecasts <- function(dataset, modelY, algorithms, ...) {
    PlotForecastTimeSeries <- function() {
        # Create a time series of the data.
        datasetTs <- zoo(dataset[, c(modelY, algorithms)],
                         order.by = dataset$Time)
        # Plot each forecast and actual.
        for (forecast in algorithms) {
            plot(datasetTs[, c(modelY, forecast)],
                 plot.type = "single",
                 col = c("black", "blue"),
                 ylab = "TankLevel",
                 main = forecast,
                 ...)
        }
    }
    tryCatch(PlotForecastTimeSeries(), error = function(...) { })
}

#-----------------------------------------------------------------------
# 2. Get the names of the true value and the algorithms.
#-----------------------------------------------------------------------

# The actual values.
modelY <- "TankLevelFuture"

# The algorithms.
algorithms <- setdiff(names(dataset), c("Time", "FacilityId", modelY))

# The id of the facility for plotting.
facilityId <- "facility1"

#-----------------------------------------------------------------------
# 3. Plot each forecast over the actual values.
#-----------------------------------------------------------------------

# Plot algorithms over actual for facility 1.
PlotForecasts(subset(dataset, FacilityId == facilityId),
              modelY, algorithms)

#-----------------------------------------------------------------------
# 4. Compute each forecast's performance.
#-----------------------------------------------------------------------

datasetOut <- ComputePerformance(dataset, modelY, algorithms)