skip_if_no_httptest2 <- function() {
  testthat::skip_if_not_installed("httptest2")
}

# Build an ORDS-style JSON response for SICONFI/CUSTOS/SADIPEM endpoints.
mock_ords_response <- function(items = list(), has_more = FALSE,
                               offset = 0L, limit = 5000L,
                               status_code = 200L) {
  httr2::response_json(
    status_code = status_code,
    body = list(
      items   = items,
      hasMore = has_more,
      offset  = offset,
      limit   = limit,
      count   = length(items)
    )
  )
}

# Build a vanilla JSON response (Transferencias / SIORG style).
mock_json_response <- function(body = list(), status_code = 200L) {
  httr2::response_json(status_code = status_code, body = body)
}

# Build a 5xx error response.
mock_error_response <- function(status_code = 500L,
                                message = "internal error") {
  httr2::response_json(
    status_code = status_code,
    body = list(error = message)
  )
}

# Disable retry sleeps and ensure cache is clean for every test.
local_fast_retry <- function(.envir = parent.frame()) {
  testthat::local_mocked_bindings(
    .tnr_sleep = function(seconds) invisible(),
    .package = "tesouror",
    .env = .envir
  )
  withr::defer(
    suppressMessages(tesouror_clear_cache()),
    envir = .envir
  )
}
