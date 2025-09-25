## Materials

[This repository](https://github.com/liamirwin/SL25_lidRtutorial) contains the material for an 180 minute `lidR` and `LAStools` tutorial workshop.

This workshop was created for the [`2025 Silvilaser Conference`](https://www.silvilaser2025.com/), held in Quebec City, Canada in September/October, 2025

This workshop was presented by `Liam A.K. Irwin`, `Brent A. Murray` and `Sadie J.S. Russell` members of the [University of British Columbia Integrated Remote Sensing Studio lab](https://irsslab.forestry.ubc.ca/).

The workshop intends to:

-   Introduce users to the `LAStools` software and the `lidR` package
-   Present an overview of what can be done with `lidR`
-   Demonstrate key workflows for deriving forest inventory products from airborne laser scanning data
-   Exercises will be done depending on available time - users are encouraged to work on these after the workshop!

Find the code, exercises, and solutions used in the `.\R` directory.

## Requirements

### R version and Rstudio

-   We reccomend installing a recent version of `R` i.e. `R 4.5.x`
-   We will work with [Rstudio](https://www.rstudio.com/). This IDE is not mandatory to follow the workshop but is highly recommended.

### R Packages

You need to install the `lidR` package in its latest version (v \>= 4.2.1).

``` r
install.packages("lidR")
```

To run all code in the tutorial yourself, you will need to install the following packages. You can use `lidR` without them, however.

``` r
libs <- c("geometry","viridis","future","sf","gstat","terra","mapview","mapedit","concaveman","microbenchmark")

install.packages(libs)
```

## Estimated schedule

-   Introduction to Lidar, LAStools, and lidR (09:00)
-   Preprocessing with LAStools (9:20)
-   Reading LAS and LAZ files (09:30)
-   Point Classification and filtering (9:35)
-   Digital Terrain Models and Height Normalization (9:40)
-   Canopy Height Models (9:50)
-   Lidar Summary Metrics (9:55)
-   Break (10:15-10:45)
-   File Collection Processing Engine (10:45)
-   Regions of Interest (11:0)
-   Area Based Approach (11:10)
-   Individual Tree Detection and Segmentation (11:30)
-   Questions (11:50)


## Resources

We strongly recommend having the following resources available to you:

-   The [`lidR` official documentation](https://cran.r-project.org/web/packages/lidR/lidR.pdf)
-   The [lidRbook](https://r-lidar.github.io/lidRbook/) of tutorials

When working on exercises:

-   [Stack Exchange with the `lidR` tag](https://gis.stackexchange.com/questions/tagged/lidr)

## Additional Resources

-   [Silvilaser 2023 lidR tutorial](https://tgoodbody.github.io/lidRtutorial/)

## `lidR`

`lidR` is an R package to work with lidar data developed at Laval University (Québec). It was developed & continues to be maintained by [Jean-Romain Roussel](https://github.com/Jean-Romain) and was made possible between:

-   2015 and 2018 thanks to the financial support of the AWARE project NSERC CRDPJ 462973-14; grantee Prof. Nicholas C. Coops.

-   2018 and 2021 thanks to the financial support of the Ministère des Forêts, de la Faune et des Parcs (Québec).

-   2021 and 2024 thanks to the financial support of Laval University.

The current release version of `lidR` can be found on [CRAN](https://cran.r-project.org/web/packages/lidR/) and source code is hosted on [GitHub](https://github.com/r-lidar/lidR).

> [!NOTE] Since 2024, the `lidR` package is no longer supported by Laval University, but the software will remain free and open-source. `r-lidar` has transitioned into a company to ensure sustainability and now offers independent services for training courses, consulting, and development. Please feel free to visit their [website](https://www.r-lidar.com/) for more information.

## `LAStools`

[`LAStools`](https://rapidlasso.de/product-overview/) is a collection of highly efficient, batch-scriptable, multicore command line tools for processing LiDAR data. It was originally developed by Martin Isenburg and is continually developed and improved by a team at rapidlasso.

`LAStools` is not open-source software, but many of its powerful tools are freely avaliable to use, including those we will use in this workshop.

Other tools require a license for commercial or educational use that can be purchased from rapidlasso.

Please visit the [LAStools website](https://rapidlasso.de/downloads/) for more information on how to download and install the software.

The inital processing steps we will use in this workshop can be completed with the free version of `LAStools`, or you can make use of the pre-processed data provided in the workshop materials package.




