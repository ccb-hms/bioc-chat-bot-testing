library(rvest)
library(purrr)
library(dplyr)
library(stringr)

## Get a package specific artifact(s)
## Vignettes, news files, and ref manual pages
get_package_artifacts <- function(package) {

    message("Parsing Bioconductor package: ", package)

    package_url <- sprintf(
        "https://bioconductor.org/packages/release/bioc/html/%s.html",
        package
    )

    ## Add a try catch block around this
    package_landing_page <- tryCatch({
        rvest::read_html(package_url)
    },
    error = function(e) {
        NA
    })

    ## Add empty row if there is a parse error
    if (is.na(package_landing_page)) {
        t <- tibble(
            package = package,
            link_text = NA,
            url = NA,
            link = NA
        )
    }
    else { 
        ## Get all nodes in a "table" in the webpage
        urls <- package_landing_page |>
                   html_nodes("table") |>
                   html_nodes("a")

        ## Make a tibble with package, link_text, relative_path, link
        t <- tibble(
            package = package,
            link_text = html_text(urls),
            url = html_attr(urls, "href")
        ) |>
        filter(
            str_detect(url, "vignettes|news|manual")
        ) |>
        mutate(
            link = paste0(
                "https://bioconductor.org/packages/release/bioc",
                gsub("..", "", url, fixed = TRUE)
            ),
            fname = paste(
                package, basename(link),
                sep = "_"
            )
        ) |>
        filter(link_text != "R Script")
    }

    return(t)
}

## Run artifacts retreival across all packages in Bioconductor
get_all_package_artifacts <- function() {

    biocsoft <- available.packages(
        repos = BiocManager::repositories()[["BioCsoft"]]
    )

    packages <- rownames(biocsoft)

    ## Map and reduce all the dataframes into one
    res <- Reduce(
        bind_rows,
        lapply(
            packages, get_package_artifacts
        )
    )

    write_csv(res, file = "bioc_package_artifacts.csv")
    
    res
}


## WIP
# download_html_as_pdf <- function() {
    ## library(pagedown)
    
    ## Install wkhtmltopdf if not already installed
    ## You can find installation instructions online

#     url <- "https://www.example.com/your_html_page"
#     
#     ## Render the HTML using headless Chrome and save as PDF
#     chrome_print(url, file = "my_report.pdf")
# }

download_non_htmls <- function(file) {
    res <- read_csv(file)

    res <- res |> filter(link_text %in% c("PDF", "Text"))
    
    links <- res$links
    filenames <- res$filenames

    ## Download all
    purrr::map2(links, filenames,
                ~ download.file(.x, .y, mode = "wb"))
}

