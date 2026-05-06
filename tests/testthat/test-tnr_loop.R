test_that("tnr_loop binds successful results into a single tibble", {
  fake <- function(x) tibble::tibble(id = x, value = x * 2)
  params <- lapply(1:3, function(i) list(x = i))

  out <- suppressMessages(
    tesouror:::tnr_loop(
      .f = fake, .params = params, .id = "x",
      on_error = "silent", progress_label = "Fake"
    )
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 3L)
  expect_equal(out$id, 1:3)
  expect_equal(out$value, c(2, 4, 6))
  expect_null(attr(out, "failed"))
  expect_null(attr(out, "no_data"))
})

test_that("tnr_loop captures empty results in attr('no_data')", {
  fake <- function(x) {
    if (x == 2L) tibble::tibble() else tibble::tibble(id = x, value = x * 2)
  }
  params <- lapply(1:3, function(i) list(x = i))

  out <- suppressMessages(
    tesouror:::tnr_loop(
      .f = fake, .params = params, .id = "x",
      on_error = "silent", progress_label = "Fake"
    )
  )

  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c(1L, 3L))

  no_data <- attr(out, "no_data")
  expect_s3_class(no_data, "tbl_df")
  expect_equal(nrow(no_data), 1L)
  expect_equal(no_data$id, "2")
  expect_equal(no_data$iteration, 2L)

  expect_null(attr(out, "failed"))
})

test_that("tnr_loop captures partial failures in attr('failed') and continues", {
  fake <- function(x) {
    if (x == 2L) stop("boom")
    tibble::tibble(id = x, value = x * 2)
  }
  params <- lapply(1:3, function(i) list(x = i))

  out <- suppressMessages(
    tesouror:::tnr_loop(
      .f = fake, .params = params, .id = "x",
      on_error = "silent", progress_label = "Fake"
    )
  )

  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c(1L, 3L))

  failed <- attr(out, "failed")
  expect_s3_class(failed, "tbl_df")
  expect_equal(nrow(failed), 1L)
  expect_equal(failed$id, "2")
  expect_equal(failed$iteration, 2L)
  expect_match(failed$error, "boom")
})

test_that("tnr_loop returns an empty tibble with attr('failed') when all fail", {
  always_fail <- function(x) stop(paste("nope", x))
  params <- lapply(1:2, function(i) list(x = i))

  out <- suppressMessages(
    tesouror:::tnr_loop(
      .f = always_fail, .params = params, .id = "x",
      on_error = "silent"
    )
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)

  failed <- attr(out, "failed")
  expect_equal(nrow(failed), 2L)
  expect_equal(failed$id, c("1", "2"))
})

test_that("tnr_loop with on_error = 'stop' aborts on the first failure", {
  fake <- function(x) {
    if (x == 2L) stop("boom")
    tibble::tibble(id = x)
  }
  params <- lapply(1:3, function(i) list(x = i))

  expect_error(
    suppressMessages(
      tesouror:::tnr_loop(
        .f = fake, .params = params, .id = "x", on_error = "stop"
      )
    ),
    "boom"
  )
})

test_that("tnr_loop falls back to iteration index when .id is missing", {
  fake <- function(y) {
    if (y == "b") stop("kapow")
    tibble::tibble(label = y)
  }
  params <- list(list(y = "a"), list(y = "b"), list(y = "c"))

  out <- suppressMessages(
    tesouror:::tnr_loop(
      .f = fake, .params = params, .id = NULL, on_error = "silent"
    )
  )

  failed <- attr(out, "failed")
  expect_equal(failed$id, "2") # falls back to iteration index as character
})
