source(file.path("..", "..", "R", "functions.R"))
data_path <- file.path("..", "..", "data", "trials.csv")

test_that("SE from a 95% CI is recovered correctly", {
  # A log-HR of 0 with SE 0.1 has 95% CI exp(+/- 1.96 * 0.1)
  lo <- exp(-qnorm(0.975) * 0.1); hi <- exp(qnorm(0.975) * 0.1)
  expect_equal(se_from_ci(lo, hi, 0.95), 0.1)
})

test_that("non-95% intervals are handled (VERTIS CV reports a 95.8% CI)", {
  lo <- exp(-qnorm(1 - 0.042 / 2) * 0.2); hi <- exp(qnorm(1 - 0.042 / 2) * 0.2)
  expect_equal(se_from_ci(lo, hi, 0.958), 0.2)
})

test_that("trial data are complete and internally consistent", {
  d <- load_trials(data_path)
  expect_equal(nrow(d), 13)
  expect_false(any(duplicated(d$trial)))
  expect_true(all(d$hr > d$ci_lower & d$hr < d$ci_upper))
  expect_true(all(grepl("^10\\.1056/NEJMoa", d$doi)))   # every trial is a primary NEJM report
  expect_true(all(d$sei > 0))
  expect_setequal(levels(d$population),
                  c("Type 2 diabetes (CV outcome trials)", "Chronic kidney disease", "Heart failure"))
})

test_that("reported HR is close to the geometric midpoint of its CI", {
  d <- load_trials(data_path)
  mid <- sqrt(d$ci_lower * d$ci_upper)
  expect_true(all(abs(log(d$hr) - log(mid)) < 0.03))   # guards against transcription errors
})

test_that("fixed-effect pooling matches metafor", {
  skip_if_not_installed("metafor")
  d <- load_trials(data_path)
  mine <- pool_fixed(d$yi, d$sei)
  m <- metafor::rma(d$yi, sei = d$sei, method = "FE")
  expect_equal(unname(mine["estimate"]), as.numeric(m$b), tolerance = 1e-10)
  expect_equal(unname(mine["se"]), m$se, tolerance = 1e-10)
})
