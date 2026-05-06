test_that("ords_fetch_all returns a single-page response as a tibble", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp <- mock_ords_response(
    items = list(
      list(esfera = "U", demonstrativo = "RREO", anexo = "RREO-Anexo 01"),
      list(esfera = "U", demonstrativo = "RREO", anexo = "RREO-Anexo 02")
    )
  )

  out <- httr2::with_mocked_responses(
    list(resp),
    suppressMessages(get_anexos(use_cache = FALSE))
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_setequal(out$anexo, c("RREO-Anexo 01", "RREO-Anexo 02"))
})

test_that("ords_fetch_all paginates across hasMore=TRUE -> FALSE", {
  skip_if_no_httptest2()
  local_fast_retry()

  page1 <- mock_ords_response(
    items   = list(list(anexo = "A1"), list(anexo = "A2")),
    has_more = TRUE, offset = 0L, limit = 2L
  )
  page2 <- mock_ords_response(
    items   = list(list(anexo = "A3")),
    has_more = FALSE, offset = 2L, limit = 2L
  )

  out <- httr2::with_mocked_responses(
    list(page1, page2),
    suppressMessages(get_anexos(use_cache = FALSE, page_size = 2))
  )

  expect_equal(nrow(out), 3L)
  expect_equal(out$anexo, c("A1", "A2", "A3"))
})

test_that("ords_fetch_all returns empty tibble when items is empty", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp <- mock_ords_response(items = list(), has_more = FALSE)

  out <- httr2::with_mocked_responses(
    list(resp),
    suppressMessages(get_anexos(use_cache = FALSE))
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

test_that("ords_fetch_all respects max_rows by truncating after the page", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp <- mock_ords_response(
    items = list(
      list(anexo = "A1"), list(anexo = "A2"),
      list(anexo = "A3"), list(anexo = "A4")
    )
  )

  out <- httr2::with_mocked_responses(
    list(resp),
    suppressMessages(get_anexos(use_cache = FALSE, max_rows = 2))
  )

  expect_equal(nrow(out), 2L)
  expect_equal(out$anexo, c("A1", "A2"))
})

test_that("ords_fetch_all returns partial result when a later page fails", {
  skip_if_no_httptest2()
  local_fast_retry()

  page1 <- mock_ords_response(
    items = list(list(anexo = "P1A"), list(anexo = "P1B")),
    has_more = TRUE, offset = 0L, limit = 2L
  )
  # Page 2: 5 consecutive 5xx exhausts the retry budget
  page2_500 <- mock_error_response(status_code = 500L, message = "boom")

  out <- httr2::with_mocked_responses(
    list(page1, page2_500, page2_500, page2_500, page2_500, page2_500),
    suppressMessages(get_anexos(use_cache = FALSE, page_size = 2))
  )

  expect_equal(nrow(out), 2L)               # only page 1 survived
  expect_equal(out$anexo, c("P1A", "P1B"))
  expect_true(isTRUE(attr(out, "partial")))
  expect_match(attr(out, "last_page_error"), "HTTP status")
})

test_that("ords_fetch_all caches and replays without hitting the network", {
  skip_if_no_httptest2()
  local_fast_retry()

  resp <- mock_ords_response(
    items = list(list(anexo = "Cached"))
  )

  # First call populates the cache (one mock consumed)
  first <- httr2::with_mocked_responses(
    list(resp),
    suppressMessages(get_anexos(use_cache = TRUE))
  )
  expect_equal(first$anexo, "Cached")

  # Second call hits cache; if it tried to call again the empty mock list
  # would surface an error. with_mocked_responses with an empty list rejects
  # any request, so reaching here proves cache short-circuited.
  second <- httr2::with_mocked_responses(
    list(),
    suppressMessages(get_anexos(use_cache = TRUE))
  )
  expect_equal(second$anexo, "Cached")
})
