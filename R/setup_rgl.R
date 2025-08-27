# R/setup-rgl.R

# load rgl and tweak its defaults
library(rgl)
r3dDefaults <- rgl::r3dDefaults
# orientation matrix
m <- structure(c(
  0.921, -0.146,  0.362, 0,
  0.386,  0.482, -0.787, 0,
  -0.06,   0.864,  0.5,   0,
  0,      0,      0,     1), .Dim = c(4L,4L))
r3dDefaults$FOV        <- 50
r3dDefaults$userMatrix <- m
r3dDefaults$zoom       <- 0.85

# set knitr chunk defaults
knitr::opts_chunk$set(
  comment   = "#>",
  collapse  = TRUE,
  fig.align = "center"
)

# ensure rgl prints to your quarto docs
rgl::setupKnitr(autoprint = TRUE)

# keep lidR from printing progress bars
options(lidR.progress = FALSE)
