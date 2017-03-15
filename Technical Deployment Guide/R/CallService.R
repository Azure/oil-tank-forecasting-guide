#12345678901234567890123456789012345678901234567890123456789012345678901
# Copyright 2016 Microsoft Corporation
# CallService.R

# Call a classic Azure ML workspace web service with inputs, and return
# the outputs.

#-----------------------------------------------------------------------
# Contents
#-----------------------------------------------------------------------

# 1. Load packpages.
# 2. Define functions.

#-----------------------------------------------------------------------
# 1. Load packpages.
#-----------------------------------------------------------------------

suppressPackageStartupMessages(library("RCurl", quietly = TRUE,
                                       warn.conflicts = FALSE))

# Set RCurl to accept SSL certificates issued by public certificate
# authorities
options(RCurlOptions =
        list(cainfo = system.file("CurlSSL", "cacert.pem",
                                  package = "RCurl")))

suppressPackageStartupMessages(library("rjson", quietly = TRUE,
                                       warn.conflicts = FALSE))

#-----------------------------------------------------------------------
# 2. Define functions.
#-----------------------------------------------------------------------

# Format headers for printing.
HeadersForPrinting <- function(headers) {
    paste(names(headers), headers, sep = " : ", collapse = "\n")
}

# Call an Azure service.
CallService <- function(url, authorizationHeader,
                        outputCallback = basicTextGatherer(),
                        headerCallback = basicHeaderGatherer(),
                        payload = NULL, ...) {
    # Define the curl options.
    curlOptions <-
        list(url = url,
             httpheader = c("Authorization" = authorizationHeader),
             writefunction = outputCallback$update,
             headerfunction = headerCallback$update,
             ...)
    # Encode a payload as a UTF8 JSON string.
    if (!is.null(payload)) {
        if (is.list(payload)) {
            curlOptions$httpheader <-
            c("Content-Type" = "application/json",
              curlOptions$httpheader)
            curlOptions$postfields <- enc2utf8(toJSON(payload))
        } else {
            curlOptions$postfields <- payload
        }
    }
    # Reset the handlers.
    outputCallback$reset()
    headerCallback$reset()
    # Call the service.
    do.call(curlPerform, curlOptions)
    # Obtain the response.
    headers <- headerCallback$value()
    # Verify that the service call happened without error.
    if (headers["status"] >= 400) {
        stop(HeadersForPrinting(headers))
    }
    # Return the result.
    outputCallback$value()
}

lastProgressMessage <- NULL
repeatedProgressMessage <- 0
ProgressMessage <- function(verbose, ..., width = getOption("width")) {
    if (verbose) {
        if (identical(lastProgressMessage, list(...))) {
            if (repeatedProgressMessage < width) {
                message(".", appendLF = FALSE)
                repeatedProgressMessage <<- repeatedProgressMessage + 1
            } else {
                message(".")
                repeatedProgressMessage <<- 0
            }
        } else {
            message(cat("\n", ...), appendLF = FALSE)
            lastProgressMessage <<- list(...)
            repeatedProgressMessage <<-
                if (length(lastProgressMessage) == 0) {
                    0
                } else {
                    nchar(paste(..., collapse = " "))
                }
        }
    }
}

# Call a request-response service.
RequestResponse <- function(parameters, Inputs = NULL, GlobalParameters = NULL,
                            verbose = FALSE) {
    # Bundle inputs into a payload.
    payload <-
        if (!is.null(Inputs)) {
            AsInput(list(Inputs = Inputs,
                         GlobalParameters = GlobalParameters))
        } else {
            AsInput(list(GlobalParameters = GlobalParameters))
        }
    # Call the web service.
    ProgressMessage(verbose) # Initialize messaging.
    ProgressMessage(verbose, "Calling Request-Response service")
    result <- fromJSON(CallService(paste0(parameters$Url,
                                          "/execute?api-version=2.0&details=true"),
                                   paste("Bearer", parameters$"Api Key"),
                                   payload = payload))
    # Decode the JSON string, and return the results.
    ProgressMessage(verbose, "Request-Response service finished")
    AsOutput(result$Results)
}

# Submit a batch job.
SubmitJob <- function(url, ...) {
    result <- CallService(paste0(url, "/jobs?api-version=2.0"), ...)
    substring(result, 2, nchar(result) - 1) # Strip the enclosing double quotes.
}

# Start a batch job.
StartJob <- function(url, jobId, ...) {
    CallService(paste0(url, "/jobs/", jobId, "/start?api-version=2.0"), payload = "", ...)
}

# Find the status of a batch job.
PollJob <- function(url, jobId, ...,
                    statusStrings =
                        setNames(nm = c("NotStarted", "Running", "Failed", "Cancelled", "Finished"))) {
    result <- fromJSON(CallService(paste0(url, "/jobs/", jobId, "?api-version=2.0"), ...))
    result$StatusString <-
        if (is.numeric(result$StatusCode)) {
            statusStrings[result$StatusCode + 1]
        } else {
            result$StatusCode
        }
    result
}

# Delete a batch job.
DeleteJob <- function(url, jobId, ...) {
    CallService(paste0(url, "/jobs/", jobId), ..., customrequest = "DELETE")
}

BatchStart <- function(parameters, Inputs = NULL, Outputs = NULL, GlobalParameters = NULL,
                  verbose = FALSE) {
    # Bundle inputs, outputs, and global parameters into a payload.
    if (all(is.null(Inputs), is.null(Outputs), is.null(GlobalParameters))) {
        payload <- NULL
    } else {
        payload <- list()
        if (!is.null(Inputs)) payload$Inputs <- Inputs
        if (!is.null(Outputs)) payload$Outputs <- Outputs
        if (!is.null(GlobalParameters)) payload$GlobalParameters <- GlobalParameters
        payload <- AsInput(payload)
    }
    # The service Url.
    url <- parameters$Url
    # The authorization header.
    authorizationHeader <- paste("Bearer", parameters$"Api Key")
    # The output handler closures.
    outputCallback <- basicTextGatherer()
    headerCallback <- basicHeaderGatherer()
    # Submit the batch job.
    ProgressMessage(verbose) # Initialize messaging.
    ProgressMessage(verbose, "Submitting job")
    jobId <- SubmitJob(url, authorizationHeader, outputCallback, headerCallback, payload)
    # Start the batch job.
    ProgressMessage(verbose, "Starting job", jobId)
    StartJob(url, jobId, authorizationHeader, outputCallback, headerCallback)
    # Return the job Id.
    jobId
}

BatchWait <- function(parameters, jobId, verbose = FALSE) {
    # The service Url.
    url <- parameters$Url
    # The authorization header.
    authorizationHeader <- paste("Bearer", parameters$"Api Key")
    # The output handler closures.
    outputCallback <- basicTextGatherer()
    headerCallback <- basicHeaderGatherer()
    # Wait until the job is complete.
    while (TRUE) {
        result <- PollJob(url, jobId, authorizationHeader, outputCallback, headerCallback)
        ProgressMessage(verbose, "Job", jobId, result$StatusString)
        switch(result$StatusString,
                NotStarted = ,
                Running = {
                    Sys.sleep(1) # Wait one second.
                },
                Failed = {
                    stop(paste("Error details:", result$Details))
                },
                Cancelled = ,
                Finished = {
                    break
                })
    }
    ProgressMessage(verbose)
    # Return the results with the job Id.
    Results <- AsOutput(result$Results)
    Results$JobId <- jobId
    Results
}

# Call a batch service.
Batch <- function(parameters, ..., verbose = FALSE) {
    jobId <- BatchStart(parameters, ..., verbose = verbose)
    BatchWait(parameters, jobId = jobId, verbose = verbose)
}

# Update an endpoint.
UpdateEndpoint <- function(parameters, Location, ..., verbose = FALSE) {
    # Bundle inputs into a payload.
    payload <-
        AsInput(list(Resources = list(list(Name = parameters$Name,
                                           Location = Location))))
    # Call the web service.
    ProgressMessage(verbose) # Initialize messaging.
    ProgressMessage(verbose, "Patching endpoint\n")
    CallService(parameters$Url,
                paste("Bearer", parameters$"Api Key"),
                payload = payload, customrequest = "PATCH",  ...)
}

# Convert an R input to a JSON input.
AsInput <- function(...) {
    UseMethod("AsInput")
}
AsInput.NULL <- function(input) {
    setNames(list(), character())
}
AsInput.character <- function(input) {
    input
}
AsInput.list <- function(input) {
    lapply(input, AsInput)
}
AsInput.data.frame <- function(input) {
    list("ColumnNames" = as.list(names(input)),
         "Values" = unname(lapply(input,
                                  function(x) {
                                      list(x[[1]], x[[1]])
                                  })))
}

# Convert a JSON output to an R output.
AsOutput <- function(...) {
    UseMethod("AsOutput")
}
AsOutput.default <- function(output, ...) {
    output
}
AsOutput.list <- function(output, ...) {
    lapply(output, AsOutputType, ...)
}

AsOutputType <- function(output, type = output$type, ...) {
    if (is.null(type)) {
        output
    } else {
        switch(type,
               matrix = AsOutputMatrix(output$value, ...),
               table = AsOutputTable(output$value, ...),
               output)
    }
}

AsOutputMatrix <- function(value, names = value$ColumnNames) {
    result <- do.call(rbind, lapply(value$Values, unlist))
    colnames(result) <- value$ColumnNames
    result
}

AsOutputTable <- function(value, names = value$ColumnNames, types = value$ColumnType, ...) {
    result <- as.data.frame(AsOutputMatrix(value, names), ...)
    for (j in seq_along(types)) {
        result[[names[j]]] <-
            switch(types[j],
                   Double = as.numeric(as.character(result[[names[j]]])),
                   DateTime = as.POSIXct(result[[names[j]]], format = "%m/%d/%Y %I:%M:%S %p"),
                   result[[names[j]]])
    }
    result
}