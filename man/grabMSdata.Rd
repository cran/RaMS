% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/grabMSdataCode.R
\name{grabMSdata}
\alias{grabMSdata}
\title{Grab mass-spectrometry data from file(s)}
\usage{
grabMSdata(
  files,
  grab_what = "everything",
  verbosity = NULL,
  incl_polarity = FALSE,
  mz = NULL,
  ppm = NULL,
  rtrange = NULL,
  prefilter = -1
)
}
\arguments{
\item{files}{A character vector of filenames to read into R's memory. Both
absolute and relative paths are acceptable.}

\item{grab_what}{What data should be read from the file? Options include
"MS1" for data only from the first spectrometer, "MS2" for fragmentation
data, "BPC" for rapid access to the base peak chromatogram, "TIC" for rapid
access to the total ion chromatogram, "DAD" for DAD (UV) data, and "chroms"
for precompiled chromatogram data (especially useful for MRM but often
contains BPC/TIC in other files). Metadata can be accessed with "metadata",
which provides information about the instrument and time the file was run.
These options can be combined (i.e. `grab_data=c("MS1", "MS2", "BPC")`) or
this argument can be set to "everything" to extract all of the above.
Options "EIC" and "EIC_MS2" are useful when working with files whose total
size exceeds working memory - it first extracts all relevant MS1 and MS2
data, respectively, then discards data outside of the mass range(s)
calculated from the provided mz and ppm. The default, "everything",
includes all MS1, MS2, BPC, TIC, and metadata.}

\item{verbosity}{Three levels of processing output to the R console are
available, with increasing verbosity corresponding to higher integers. A
verbosity of zero means that no output will be produced, useful when
wrapping within larger functions. A verbosity of 1 will produce a progress
bar using base R's txtProgressBar function. A verbosity of 2 or higher will
produce timing output for each individual file read in. The default, NULL,
will select between 1 and 2 depending on the number of files being read: if
a single file, verbosity is set to 2; if multiple files, verbosity is set
to 1.}

\item{incl_polarity}{Toggle this option to TRUE for mixed-polarity files. An
additional column will be added corresponding to the polarity of the scan,
with either a 1 or a -1 corresponding to positive and negative mode,
respectively.}

\item{mz}{A vector of the mass-to-charge ratio for compounds of interest.
Only used when combined with `grab_what = "EIC"` (see above). Multiple
masses can be provided.}

\item{ppm}{A single number corresponding to the mass accuracy (in parts per
million) of the instrument on which the data was collected. Only used when
combined with `grab_what = "EIC"` (see above).}

\item{rtrange}{Only available when parsing mzML files. A vector of length 2
containing an upper and lower bound on retention times of interest.
Providing a range here can speed up load times (although not enormously, as
the entire file must still be read) and reduce the final object's size.}

\item{prefilter}{A single number corresponding to the minimum intensity of
interest in the MS1 data. Data points with intensities below this threshold
will be silently dropped, which can dramatically reduce the size of the
final object. Currently only works with MS1 data, but could be expanded
easily to handle more.}
}
\value{
A list of `data.table`s, each named after the arguments requested in
  grab_what. E.g. $MS1 contains MS1 information, $MS2 contains fragmentation
  info, etc. MS1 data has four columns: retention time (rt), mass-to-charge
  (mz), intensity (int), and filename. MS2 data has six: retention time (rt),
  precursor m/z (premz), fragment m/z (fragmz), fragment intensity (int),
  collision energy (voltage), and filename. MS3 adds an additional column to
  this (prepremz) corresponding to the initial MS1 m/z targeted. Data
  requested that does not exist in the provided files (such as MS2 data
  requested from MS1-only files) will return an empty (length zero)
  data.table. The data.tables extracted from each of the individual files are
  collected into one large table using data.table's `rbindlist`. $metadata is
  a little weirder because the metadata doesn't fit neatly into a tidy format
  but things are hopefully named helpfully. $chroms was added in v1.3 and
  contains 7 columns: chromatogram type (usually TIC, BPC or SRM info),
  chromatogram index, target mz, product mz, retention time (rt), and
  intensity (int). $DAD was also added in v1.3 and contains has three
  columns: retention time (rt), wavelength (lambda),and intensity (int). Data
  requested that does not exist in the provided files (such as MS2 data
  requested from MS1-only files) will return an empty (zero-row) data.table.
}
\description{
The main `RaMS` function. This function accepts a list of the files that will
be read into R's working memory and returns a list of `data.table`s
containing the requested information. What information is requested is
determined by the `grab_what` argument, which can include MS1, MS2, BPC, TIC,
or metadata information. This function serves as a wrapper around both
`grabMzmlData` and `grabMzxmlData` and handles multiple files, but those two
have also been exposed to the user in case super-simple handling is desired.
Retention times are reported in minutes, and will be converted automatically
if they are encoded in seconds.
}
\examples{
library(RaMS)
\dontshow{data.table::setDTthreads(2)}
# Extract MS1 data from a couple files
sample_dir <- system.file("extdata", package = "RaMS")
sample_files <- list.files(sample_dir, full.names=TRUE)
multifile_data <- grabMSdata(sample_files[c(3,5,6)], grab_what="MS1")

}
