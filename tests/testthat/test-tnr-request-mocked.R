test_that("tnr_request retries on 500 and succeeds on a later 200", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp_500 <- mock_error_response(status_code = 500L, message = "boom")
  resp_500_b <- mock_error_response(status_code = 500L, message = "boom")
  resp_200 <- mock_ords_response(items = list(list(anexo = "OK")))

  out <- httr2::with_mocked_responses(
    list(resp_500, resp_500_b, resp_200),
    suppressMessages(get_anexos(use_cache = FALSE))
  )

  expect_equal(nrow(out), 1L)
  expect_equal(out$anexo, "OK")
})

test_that("tnr_request retries on 503/504/429 (server-side codes)", {
  skip_if_no_httptest2()
  local_fast_retry()

  for (status in c(429L, 502L, 503L, 504L)) {
    suppressMessages(tesouror_clear_cache())
    out <- httr2::with_mocked_responses(
      list(
        mock_error_response(status, "transient"),
        mock_ords_response(items = list(list(anexo = sprintf("S%d", status))))
      ),
      suppressMessages(get_anexos(use_cache = FALSE))
    )
    expect_equal(nrow(out), 1L, info = paste("status", status))
    expect_equal(out$anexo, sprintf("S%d", status), info = paste("status", status))
  }
})

test_that("tnr_request aborts on 400 without retrying", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp_400 <- mock_error_response(status_code = 400L, message = "bad request")

  expect_error(
    httr2::with_mocked_responses(
      list(resp_400),
      suppressMessages(get_anexos(use_cache = FALSE))
    ),
    "HTTP status"
  )
})

test_that("tnr_request aborts on 404 without retrying", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp_404 <- mock_error_response(status_code = 404L, message = "not found")

  expect_error(
    httr2::with_mocked_responses(
      list(resp_404),
      suppressMessages(get_anexos(use_cache = FALSE))
    ),
    "HTTP status"
  )
})

test_that("tnr_request gives up after exhausting the retry budget on 5xx", {
  skip_if_no_httptest2()
  local_fast_retry()

  # 5 attempts, all 500
  many_500 <- replicate(5, mock_error_response(500L, "down"), simplify = FALSE)

  expect_error(
    httr2::with_mocked_responses(
      many_500,
      suppressMessages(get_anexos(use_cache = FALSE))
    ),
    "HTTP status"
  )
})
