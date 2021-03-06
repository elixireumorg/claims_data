% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper_functions.R
\name{helper}
\alias{helper}
\alias{list_var}
\alias{sqlbatch_f}
\alias{suppress_f}
\title{Broad use helper functions}
\usage{
list_var(...)

sqlbatch_f(server, sqlbatch)

suppress_f(df, suppress_var, lower = 1, upper = 10, col_wise = TRUE)
}
\arguments{
\item{...}{Variables that will be passed as a list to another function}

\item{server}{SQL server connection created using \code{odbc} package}

\item{sqlbatch}{Any number of SQL queries in list format}

\item{df}{Data frame on which to perform small number suppression}

\item{suppress_var}{Specifies which variables to base suppression on}

\item{lower}{Lower cell count for suppression (inclusive), defaults to 1}

\item{upper}{Upper cell count for suppression (inclusive), defaults to 10}
}
\description{
Various functions used to support processing and analysis
of Medicaid claims data.

\code{list_var} accepts a list of unquoted variable names and returns a list of quosures
for passing to any function.

\code{sqlbatch_f} prepares and sends batched SQL statements to SQL Server with the final statement
returning a result set.
}
