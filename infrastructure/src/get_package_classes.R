## Get classes of packages in Bioconductor

get_package_classes_and_write_csv <- function(package_names,
                                              output_file = "package_classes.csv") {
    ## Create a data frame to store results
    results <- data.frame(Package = character(),
                          Classes = character(),
                          Total = integer(),
                          stringsAsFactors = FALSE)
    
    for (pkg in package_names) {
        tryCatch({
            ## Load the package
            library(pkg, character.only = TRUE)
            
            ## Get all classes defined in the package
            classes <- methods::getClasses(where = paste0("package:", pkg))
            
            ## Add to results data frame
            results <- rbind(results,
                             data.frame(
                                 Package = pkg,
                                 Classes = paste(classes, collapse = ", "),
                                 Total = length(classes),
                                 stringsAsFactors = FALSE
                             ))
        }, error = function(e) {
            warning(paste("Error processing package:", pkg, "-", e$message))
        })
    }
    
    ## Write results to CSV
    write.csv(results, file = output_file, row.names = FALSE)
    
    cat("Results written to", output_file, "\n")
}


## Get Bioconductor packagse
pkgs <- available.packages(repos = BiocManager::repositories()[1])

## Example usage
installed <- rownames(installed.packages())
biocsoft <- available.packages(
    repos = BiocManager::repositories()[["BioCsoft"]]
)


## Get number of classes per package
get_package_classes_and_write_csv(installed)

## get_top_500_names

names <- dir("data/bioc_3_18_top_500")

names <- unique(sapply(strsplit(names, split = "_"), `[[`, 1))

get_package_classes_and_write_csv(names)
