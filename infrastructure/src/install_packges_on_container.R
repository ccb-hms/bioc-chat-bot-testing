library(tictoc)

## Get installed packages
installed <- rownames(installed.packages())

biocsoft <- available.packages(
    repos = BiocManager::repositories()[["BioCsoft"]]
)

to_install <- rownames(biocsoft)[!rownames(biocsoft) %in% installed]

## install all
tic()
BiocManager::install(to_install, Ncpus=10)
toc()
