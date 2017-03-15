#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# TankLevelLabelScript.R

# Generate a label for modeling.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Define functions.
# 2. Create the label.

#-----------------------------------------------------------------------
# 1. Define functions.
#-----------------------------------------------------------------------

# Create leading features.
LeadFeature <- function(dataset, name, Lead, tag = "Lead") {
    # Drop the lead rows from dataset.
    result <-
        data.frame(dataset[1:(nrow(dataset) - Lead),, drop = FALSE],
                   dataset[(Lead + 1):nrow(dataset), name, drop = FALSE])
    colnames(result)[ncol(dataset) + 1:length(name)] <-
        paste0(name, tag)
    result
}

# Create a labeled dataset from one facility's feature data.
CreateLabelFacility <- function(dataset, Lead, tankPat, datasetEmpty) {
    # Create the labeled dataset.
    CreateDataLabel <- function() {
        # Add the label.
        datasetLabeled <- LeadFeature(dataset, tankPat, Lead, "Future")
        # Remove rows with missing values.
        datasetLabeled <- na.omit(datasetLabeled)
        # The labeled data.
        datasetLabeled
    }
    # Create the labels.
    datasetOut <- tryCatch(CreateDataLabel(),
                           error = function(...) { datasetEmpty })
    # The labeled data.
    datasetOut
}

# Lead tank levels by (Resolution * Lead) minutes.
# Note: Resolution was applied at feature creation time.
CreateLabel <- function(dataset, dataset2,
                        # The number of time chunks the label leads
                        # the data.
                        Lead = dataset2$Lead,
                        # Variable name patterns.
                        tankPat = "TankLevel") {
    # Create an empty dataset for error return.
    labelName <- paste0(tankPat, "Future")
    labelCol <- setNames(list(numeric(0)), labelName)
    datasetEmpty <- data.frame(dataset[ - (1:nrow(dataset)),, drop = FALSE],
                               labelCol)
    # Create the labels for each facility's data.
    datasetOut <-
        do.call(rbind,
                # For each facility's data.
                lapply(split(dataset, dataset$FacilityId),
                        CreateLabelFacility, Lead, tankPat,
                        datasetEmpty))
    # Warn if the labeled data are empty.
    if (is.null(datasetOut)) {
        datasetOut <- datasetEmpty
    }
    if (nrow(datasetOut) == 0) {
        warning("Labeling resulted in an empty dataset.")
    }
    # The labeled data.
    datasetOut
}

#-----------------------------------------------------------------------
# 2. Create the label.
#-----------------------------------------------------------------------

datasetOut <- CreateLabel(dataset, dataset2)