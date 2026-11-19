# Helper functions for the SGLT2 inhibitor meta-analysis (unit-tested in tests/testthat).

#' Load the trial-level data and derive log hazard ratios and standard errors.
#'
#' The standard error is recovered from the reported confidence interval:
#'   SE = (log(upper) - log(lower)) / (2 * z),  z = qnorm(1 - (1 - level) / 2)
#' which correctly handles trials that report non-95% intervals (e.g. VERTIS CV, 95.8%).
load_trials <- function(path = "data/trials.csv") {
  d <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("trial", "drug", "population", "hr", "ci_lower", "ci_upper", "ci_level",
                "strict_definition")
  missing <- setdiff(required, names(d))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))
  stopifnot(all(d$ci_lower < d$hr & d$hr < d$ci_upper), all(d$ci_level > 0 & d$ci_level < 1))
  d$yi  <- log(d$hr)
  d$sei <- se_from_ci(d$ci_lower, d$ci_upper, d$ci_level)
  d$strict_definition <- as.logical(d$strict_definition)
  d$population <- factor(d$population,
                         levels = c("Type 2 diabetes (CV outcome trials)", "Chronic kidney disease", "Heart failure"))
  d
}

#' Standard error of a log hazard ratio from its confidence interval.
se_from_ci <- function(lower, upper, level = 0.95) {
  z <- qnorm(1 - (1 - level) / 2)
  (log(upper) - log(lower)) / (2 * z)
}

#' Fixed-effect inverse-variance pooled log HR (used to cross-check metafor).
pool_fixed <- function(yi, sei) {
  w <- 1 / sei^2
  est <- sum(w * yi) / sum(w)
  se <- sqrt(1 / sum(w))
  c(estimate = est, se = se)
}

#' Format a hazard ratio with CI from a metafor model on the log scale.
fmt_model <- function(m, digits = 2) {
  sprintf(paste0("%.", digits, "f (%.", digits, "f–%.", digits, "f)"),
          exp(m$b[1]), exp(m$ci.lb), exp(m$ci.ub))
}

fmt_p <- function(p) ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
