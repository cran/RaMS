% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/extraHelperFunctions.R
\name{qplotMS1data}
\alias{qplotMS1data}
\title{Quick plot for MS data}
\usage{
qplotMS1data(
  MS1_df,
  color_col = NULL,
  facet_col = NULL,
  facet_args = list(ncol = 1),
  force_base = FALSE
)
}
\arguments{
\item{MS1_df}{A data.table with at least three columns named rt, int, and filename}

\item{color_col}{The name of the column to color by. Must be quoted.}

\item{facet_col}{The name of the column to facet by. Must be quoted.}

\item{facet_args}{Since the call to facet_wrap is within the function, you
can provide additional facet customization arguments here as a list. Although
if you're starting to fiddle with facets you'll probably be better served by
the proper `ggplot` call.}

\item{force_base}{Boolean option to force base R graphics instead of `ggplot`
even if the `ggplot2` package is installed.}
}
\value{
If `ggplot2` is installed, a `ggplot` object that can be further
modified via additional + commands. Otherwise, NULL and the plot appears
via base graphics at the active device.
}
\description{
Syntactic sugar for a common chromatogram plot. Will use `ggplot2` if
available but has a base plot implementation for use even in ultra
lightweight situations. Accepts the default MS1 output from `grabMSdata`
of a data.table (or base data.frame) with columns for rt (retention time)
and int (intensity) as well as filename. Creates a plot of intensity vs
retention time with one trace per file. A few additional `ggplot2` arguments
are also made available for easy coloring or facetting by providing the
name of the associated column to the `color_col` and `facet_col` arguments,
respectively.
}
\examples{
\dontshow{data.table::setDTthreads(2)}
test_df <- expand.grid(rt=rep(1:100, length.out=1000))
test_df$int <- rep(dnorm(seq(-10, 10, length.out=100)), 10)*10+runif(1000)
test_df$filename <- rep(LETTERS[1:10], each=100)
qplotMS1data(test_df)

test_df$startime <- rep(gl(2, 5, labels = c("Morn", "Eve")), each=100)
qplotMS1data(test_df, color_col="startime", facet_col="startime")
qplotMS1data(test_df, color_col="startime", facet_col="startime",
            facet_args=list(ncol=2, scales="free"))

# Using data from the `grabMSdata` function:
\dontrun{
sample_dir <- system.file("extdata", package = "RaMS")
sample_files <- list.files(sample_dir, full.names=TRUE)
msdata <- grabMSdata(sample_files[c(3, 5, 6)], grab_what="MS1")
qplotMS1data(msdata$MS1[mz\%between\%pmppm(118.0865)])
}
}
