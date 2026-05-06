# Internal utilities for tesouror
# These functions are not exported

# -- Parameter validation ------------------------------------------------------

#' Check that required arguments were supplied via missing()
#' @noRd
check_required <- function(...) {
  args <- as.character(match.call())[-1]
  env <- parent.frame()
  missing_args <- character()
  na_args <- character()

  for (arg in args) {
    tryCatch(
      {
        val <- eval(call("missing", as.symbol(arg)), envir = env)
        if (isTRUE(val)) {
          missing_args <- c(missing_args, arg)
        } else {
          arg_val <- get(arg, envir = env)
          if (length(arg_val) == 1 && is.na(arg_val)) {
            na_args <- c(na_args, arg)
          }
        }
      },
      error = function(e) {
        missing_args <<- c(missing_args, arg)
      }
    )
  }

  if (length(missing_args) > 0) {
    cli::cli_abort(
      "Missing required argument{?s}: {.arg {missing_args}}."
    )
  }
  if (length(na_args) > 0) {
    cli::cli_abort(
      "Required argument{?s} {.arg {na_args}} cannot be NA."
    )
  }
  invisible(NULL)
}

# -- Null coalescing -----------------------------------------------------------

#' Null-coalescing operator (from rlang)
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

# -- Parameter collapsing ------------------------------------------------------

#' Collapse a vector into a colon-separated string
#' @noRd
collapse_param <- function(x) {
  if (is.null(x)) return(NULL)
  paste(x, collapse = ":")
}

# -- UF abbreviation guard -----------------------------------------------------

#' Brazilian state two-letter abbreviations (used by .check_not_uf_abbrev)
#' @noRd
.uf_abbrevs <- c(
  "AC", "AL", "AM", "AP", "BA", "BR", "CE", "DF", "ES", "GO",
  "MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ",
  "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO"
)

#' Abort early when a UF abbreviation is passed where a Treasury numeric code is expected
#'
#' Several Transferencias endpoints expect a numeric Treasury state code in
#' parameters named `p_uf` / `p_estado` / `state_code` (NOT the IBGE code and
#' NOT the two-letter abbreviation). Passing the abbreviation makes the
#' upstream API return HTTP 500 after a long retry budget; this helper short-
#' circuits that with an actionable error.
#'
#' @noRd
.check_not_uf_abbrev <- function(value, arg_name) {
  if (is.null(value)) return(invisible())
  v <- as.character(value)
  is_abbrev <- length(v) == 1L && !is.na(v) && nchar(v) == 2L &&
    toupper(v) %in% .uf_abbrevs
  if (is_abbrev) {
    cli::cli_abort(c(
      "x" = "{.arg {arg_name}} must be a Treasury state code (numeric), not the UF abbreviation {.val {v}}.",
      "i" = "Look it up with {.fun get_tc_estados}: e.g. {.code estados$codigo[estados$nome == \"Pernambuco\"]}."
    ), call = NULL)
  }
  invisible()
}

# -- Verbose helper ------------------------------------------------------------

#' Check if verbose mode is enabled
#' @noRd
is_verbose <- function(verbose) {
  isTRUE(verbose) || isTRUE(getOption("tesouror.verbose", FALSE))
}

#' Build the full URL with query params for display
#' @noRd
build_display_url <- function(url, params) {
  params <- Filter(Negate(is.null), params)
  if (length(params) == 0) return(url)
  query <- paste0(
    names(params), "=", vapply(params, as.character, character(1)),
    collapse = "&"
  )
  paste0(url, "?", query)
}

# -- Base URLs -----------------------------------------------------------------

#' @noRd
siconfi_base_url <- function() {
  "https://apidatalake.tesouro.gov.br/ords/siconfi/tt"
}

#' @noRd
custos_base_url <- function() {
  "https://apidatalake.tesouro.gov.br/ords/custos/tt"
}

#' @noRd
sadipem_base_url <- function() {
  "https://apidatalake.tesouro.gov.br/ords/sadipem/tt/"
}

#' @noRd
transferencias_base_url <- function() {
  "https://apiapex.tesouro.gov.br/aria/v1/transferencias_constitucionais/custom"
}

#' Base URL for the SIOPE API (OData)
#' @noRd
siope_base_url <- function() {
  "https://www.fnde.gov.br/olinda-ide/servico/DADOS_ABERTOS_SIOPE/versao/v1/odata"
}

# -- In-memory cache -----------------------------------------------------------

the_cache <- new.env(parent = emptyenv())

cache_key <- function(url, params) {
  parts <- c(url, sort(paste0(names(params), "=", params)))
  paste(parts, collapse = "|")
}

cache_get <- function(key) {
  if (exists(key, envir = the_cache)) {
    return(get(key, envir = the_cache))
  }
  NULL
}

cache_set <- function(key, value) {
  assign(key, value, envir = the_cache)
  invisible(value)
}

#' Clear the tesouror in-memory cache
#'
#' Removes **all** cached API responses stored during the current R session.
#' This applies to every API covered by the package: SICONFI, CUSTOS, SADIPEM,
#' and Transferencias Constitucionais. All cached responses share the same
#' in-memory store and are cleared together.
#'
#' @return Invisible `NULL`.
#' @export
#' @examples
#' tesouror_clear_cache()
tesouror_clear_cache <- function() {
  rm(list = ls(envir = the_cache), envir = the_cache)
  cli::cli_alert_info("Cache cleared (all APIs).")
  invisible(NULL)
}

# -- Request builder -----------------------------------------------------------

max_retries <- 5L
retry_wait <- 3L

#' Wait between retries
#'
#' Thin wrapper around [base::Sys.sleep()]; exists so tests can mock retry
#' delays via `testthat::local_mocked_bindings(.tnr_sleep = ...)` instead of
#' actually pausing for the full backoff budget.
#' @noRd
.tnr_sleep <- function(seconds) {
  Sys.sleep(seconds)
}

#' Build and perform a single request to a Treasury API
#' @noRd
tnr_request <- function(url, params = list(), use_cache = TRUE,
                        api_name = "Treasury",
                        accept = "application/json",
                        verbose = FALSE) {
  params <- Filter(Negate(is.null), params)

  # Verbose: show full URL
  if (is_verbose(verbose)) {
    full_url <- build_display_url(url, params)
    cli::cli_alert_info("API call: {.url {full_url}}")
  }

  # Check cache
  if (use_cache) {
    key <- cache_key(url, params)
    cached <- cache_get(key)
    if (!is.null(cached)) return(cached)
  }

  req <- httr2::request(url) |>
    httr2::req_url_query(!!!params) |>
    httr2::req_headers(Accept = accept) |>
    httr2::req_error(is_error = function(resp) FALSE)

  # Retry loop — covers both connection failures AND retryable HTTP errors
  # (5xx server errors, 429 rate limiting)
  resp <- NULL
  last_error <- NULL
  last_status <- NULL

  for (attempt in seq_len(max_retries)) {
    last_error <- NULL
    last_status <- NULL

    resp <- tryCatch(
      httr2::req_perform(req),
      error = function(e) { last_error <<- e; NULL }
    )

    if (!is.null(resp)) {
      last_status <- httr2::resp_status(resp)
      # Success — break out
      if (last_status == 200L) break
      # Retryable server errors (504 timeout, 502 bad gateway, 503 unavailable, 429 rate limit)
      if (last_status %in% c(429L, 500L, 502L, 503L, 504L)) {
        if (attempt < max_retries) {
          wait <- retry_wait * attempt
          cli::cli_alert_warning(
            "HTTP {last_status} on attempt {attempt}/{max_retries}. Retrying in {wait}s..."
          )
          .tnr_sleep(wait)
          resp <- NULL  # reset so we retry
          next
        }
        # Last attempt also failed with retryable status — fall through to error below
      } else {
        # Non-retryable HTTP error (400, 404, etc.) — break and report
        break
      }
    } else {
      # Connection failure
      if (attempt < max_retries) {
        wait <- retry_wait * attempt
        cli::cli_alert_warning(
          "Connection failed (attempt {attempt}/{max_retries}). Retrying in {wait}s..."
        )
        .tnr_sleep(wait)
      }
    }
  }

  # All retries exhausted — connection failure
  if (is.null(resp)) {
    err_msg <- if (!is.null(last_error)) conditionMessage(last_error) else "Unknown error"
    hint <- if (grepl("HTTP/2|stream|PROTOCOL_ERROR", err_msg)) {
      "The server closed the connection unexpectedly (HTTP/2 protocol error)."
    } else if (grepl("resolve|DNS|getaddrinfo", err_msg, ignore.case = TRUE)) {
      "Could not resolve the API hostname. Check your internet connection."
    } else if (grepl("timed? ?out|timeout", err_msg, ignore.case = TRUE)) {
      "The request timed out. The API may be temporarily unavailable."
    } else if (grepl("connection refused|connrefused", err_msg, ignore.case = TRUE)) {
      "Connection refused by the server."
    } else if (grepl("SSL|certificate|TLS", err_msg, ignore.case = TRUE)) {
      "SSL/TLS error. There may be a network or certificate issue."
    } else {
      NULL
    }
    bullets <- c(
      "x" = "Failed to connect to the {api_name} API after {max_retries} attempts.",
      "i" = "URL: {.url {url}}",
      if (!is.null(hint)) c("!" = hint),
      "i" = "Original error: {err_msg}",
      "i" = "Try again later or check your internet connection."
    )
    cli::cli_abort(bullets, call = NULL)
  }

  # Check HTTP status (for non-retryable errors, or retryable ones that exhausted retries)
  status <- httr2::resp_status(resp)
  if (status != 200L) {
    # Try to extract error details from response body
    error_detail <- tryCatch({
      err_body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
      msg <- err_body[["error"]][["message"]] %||%
             err_body[["message"]] %||%
             err_body[["error"]] %||% NULL
      if (is.character(msg)) msg else NULL
    }, error = function(e) NULL)

    retry_note <- if (attempt > 1L) {
      " (after {attempt} attempts)"
    } else {
      ""
    }

    hint <- if (status == 400L) {
      paste0(
        "Bad request. ",
        if (!is.null(error_detail)) {
          paste0("Server message: ", error_detail)
        } else {
          paste0(
            "If using filter, select, or orderby: check that column ",
            "names match the original API names (uppercase). ",
            "Use verbose = TRUE with max_rows = 1 to inspect valid column names."
          )
        }
      )
    } else if (status == 404L) {
      "The endpoint or entity was not found. Check your parameters."
    } else if (status %in% c(502L, 503L, 504L)) {
      if (api_name == "CUSTOS") {
        paste0(
          "Server timeout. The CUSTOS backend is slow on broad queries. ",
          "Try (a) adding a `mes` filter (e.g. `mes = 6`) and/or ",
          "(b) reducing `page_size` (e.g. 250). ",
          "If pagination fails mid-way, the package now returns a partial ",
          "result with attr(result, 'partial') = TRUE."
        )
      } else {
        "Server timeout. Try a smaller page_size or retry later."
      }
    } else if (status >= 500L) {
      "Server error. The API may be temporarily unavailable."
    } else if (status == 429L) {
      "Rate limited. Wait a moment before retrying."
    } else {
      "Check your parameters and try again."
    }

    cli::cli_abort(c(
      "x" = paste0("{api_name} API returned HTTP status {.val {status}}", retry_note, "."),
      "i" = "URL: {.url {build_display_url(url, params)}}",
      "i" = hint
    ), call = NULL)
  }

  # Parse JSON
  body <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = TRUE),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to parse the API response as JSON.",
        "i" = "URL: {.url {url}}",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  if (use_cache) cache_set(key, body)
  body
}

# -- Pagination (ORDS-style) --------------------------------------------------

#' @noRd
ords_fetch_all <- function(base_url, endpoint, params = list(),
                           use_cache = TRUE, api_name = "Treasury",
                           verbose = FALSE, page_size = NULL,
                           max_rows = Inf) {
  all_items <- list()
  page <- 1L
  total_rows <- 0L
  url <- paste0(base_url, endpoint)

  # Always send limit to control page size.
  # Each API wrapper sets a safe default; user can override.
  if (!is.null(page_size)) {
    params[["limit"]] <- as.integer(page_size)
  }

  # If max_rows is smaller than limit, no point fetching more per page
  if (is.finite(max_rows) && !is.null(params[["limit"]])) {
    params[["limit"]] <- min(params[["limit"]], as.integer(max_rows))
  } else if (is.finite(max_rows) && is.null(params[["limit"]])) {
    params[["limit"]] <- as.integer(max_rows)
  }

  # -- First page --------------------------------------------------------------
  cli::cli_alert("Fetching {.field {api_name}{endpoint}} page {.val {1L}}...")
  body <- tnr_request(url, params, use_cache = use_cache,
                      api_name = api_name, verbose = verbose)
  items <- body[["items"]]

  if (is.null(items) || length(items) == 0) {
    cli::cli_alert_warning(
      "No data returned for {.field {api_name}{endpoint}}."
    )
    return(tibble::tibble())
  }

  all_items[[page]] <- items
  total_rows <- total_rows + NROW(items)
  has_more <- isTRUE(body[["hasMore"]])

  cli::cli_alert_success(
    "{.field {api_name}{endpoint}} | page {.val {page}} | {.val {total_rows}} rows"
  )

  # -- Subsequent pages --------------------------------------------------------
  partial_error <- NULL  # populated if a page fails after retries
  while (has_more && total_rows < max_rows) {
    page <- page + 1L

    offset <- body[["offset"]]
    limit  <- body[["limit"]]
    if (is.null(offset) || is.null(limit)) break

    next_offset <- offset + limit
    next_params <- c(params, list(offset = next_offset))

    cli::cli_alert("Fetching {.field {api_name}{endpoint}} page {.val {page}}...")
    body <- tryCatch(
      tnr_request(url, next_params, use_cache = use_cache,
                  api_name = api_name, verbose = verbose),
      error = function(e) e
    )

    # Mid-pagination failure: keep what we already have and signal partial.
    if (inherits(body, "error")) {
      partial_error <- conditionMessage(body)
      cli::cli_alert_warning(
        "Page {.val {page}} failed; returning partial result of {.val {total_rows}} rows from {.val {page - 1L}} page{?s}."
      )
      cli::cli_alert_info(
        "Inspect with {.code attr(result, 'partial')} and {.code attr(result, 'last_page_error')}."
      )
      page <- page - 1L  # last successful page
      break
    }

    items <- body[["items"]]
    if (is.null(items) || length(items) == 0) break

    all_items[[page]] <- items
    total_rows <- total_rows + NROW(items)
    has_more <- isTRUE(body[["hasMore"]])

    cli::cli_alert_success(
      "{.field {api_name}{endpoint}} | page {.val {page}} | {.val {total_rows}} rows"
    )
  }

  # -- Assemble result ---------------------------------------------------------
  result <- tryCatch(
    dplyr::bind_rows(lapply(all_items, tibble::as_tibble)),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to parse the {api_name} API response into a tibble.",
        "i" = "Endpoint: {.field {endpoint}}",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  result <- tryCatch(
    dplyr::mutate(result, dplyr::across(dplyr::where(is.character), stringr::str_squish)),
    error = function(e) result
  )

  result <- janitor::clean_names(result)

  # Truncate to max_rows if needed
  if (is.finite(max_rows) && nrow(result) > max_rows) {
    result <- result[seq_len(max_rows), ]
    cli::cli_alert_success(
      "Done: {.val {nrow(result)}} rows (truncated to max_rows)."
    )
  } else if (!is.null(partial_error)) {
    cli::cli_alert_warning(
      "Done (PARTIAL): {.val {nrow(result)}} rows from {.val {page}} page{?s}."
    )
  } else {
    cli::cli_alert_success(
      "Done: {.val {nrow(result)}} rows total ({.val {page}} page{?s})."
    )
  }

  if (!is.null(partial_error)) {
    attr(result, "partial") <- TRUE
    attr(result, "last_page_error") <- partial_error
  }

  result
}

# -- Looped fetch with fault tolerance ----------------------------------------

#' Apply a fetcher across many parameter sets, tolerating per-iteration failures
#'
#' Internal helper used by `get_*_for_state()` family. Iterates over a list of
#' parameter sets, calls `.f` on each, captures errors per iteration, and
#' returns a single bound tibble plus an attribute `"failed"` listing failures.
#'
#' @param .f Function to call per iteration.
#' @param .params List of named lists, one per iteration, of arguments to `.f`.
#' @param .id Character. Name of the argument inside each entry of `.params`
#'   used as iteration label in messages (e.g., `"id_ente"`). Optional.
#' @param on_error One of `"warn"` (default), `"stop"`, `"silent"`.
#' @param progress_label Character. Short label used in progress messages.
#'
#' @return A tibble with all successful, non-empty results bound together.
#'   Iterations that raised an error are recorded in `attr(result, "failed")`
#'   (tibble with `iteration`, `id`, `error`); iterations that succeeded but
#'   returned zero rows (e.g., a SICONFI entity that never homologated the
#'   report) are recorded in `attr(result, "no_data")` (tibble with
#'   `iteration`, `id`).
#' @noRd
tnr_loop <- function(.f, .params, .id = NULL,
                     on_error = c("warn", "stop", "silent"),
                     progress_label = "Iteration") {
  on_error <- match.arg(on_error)
  n <- length(.params)
  results <- vector("list", n)
  failures <- vector("list", 0L)
  empties  <- vector("list", 0L)

  iter_label_of <- function(i) {
    args <- .params[[i]]
    if (!is.null(.id) && !is.null(args[[.id]])) {
      as.character(args[[.id]])
    } else {
      as.character(i)
    }
  }

  cli::cli_alert_info(
    "{progress_label}: looping over {n} call{?s}..."
  )

  for (i in seq_len(n)) {
    args <- .params[[i]]
    iter_label <- iter_label_of(i)

    res <- tryCatch(
      do.call(.f, args),
      error = function(e) {
        failures[[length(failures) + 1L]] <<- tibble::tibble(
          iteration = i,
          id        = iter_label,
          error     = conditionMessage(e)
        )
        if (on_error == "stop") stop(e)
        if (on_error == "warn") {
          cli::cli_alert_warning(
            "[{i}/{n}] {progress_label} {.val {iter_label}} failed: {conditionMessage(e)}"
          )
        }
        NULL
      }
    )

    if (!is.null(res) && is.data.frame(res) && nrow(res) == 0L) {
      empties[[length(empties) + 1L]] <- tibble::tibble(
        iteration = i, id = iter_label
      )
      results[[i]] <- NULL
    } else {
      results[[i]] <- res
    }
  }

  ok <- !vapply(results, is.null, logical(1))
  combined <- if (any(ok)) {
    dplyr::bind_rows(results[ok])
  } else {
    tibble::tibble()
  }

  n_failed <- length(failures)
  n_empty  <- length(empties)
  n_ok     <- n - n_failed - n_empty

  if (n_failed > 0L) {
    attr(combined, "failed") <- dplyr::bind_rows(failures)
    if (on_error != "silent") {
      cli::cli_alert_warning(
        "{n_failed} of {n} call{?s} failed. Inspect with {.code attr(result, 'failed')}."
      )
    }
  }

  if (n_empty > 0L) {
    attr(combined, "no_data") <- dplyr::bind_rows(empties)
    if (on_error != "silent") {
      cli::cli_alert_info(
        "{n_empty} of {n} call{?s} returned no data (e.g., entity never homologated this report). Inspect with {.code attr(result, 'no_data')}."
      )
    }
  }

  if (n_failed == 0L && n_empty == 0L) {
    cli::cli_alert_success("All {n} call{?s} succeeded.")
  } else if (n_failed == 0L) {
    cli::cli_alert_success("{n_ok} of {n} call{?s} returned data.")
  }

  combined
}

#' Resolve municipalities of a Brazilian state for SICONFI loops
#'
#' Internal helper used by `get_*_for_state()` functions. Calls `get_entes()`
#' (cached), filters to municipalities of `state_uf`, optionally drops the
#' state capital, and returns the resulting tibble. Aborts if no municipalities
#' are found.
#'
#' @noRd
resolve_state_munis <- function(state_uf, include_capital = TRUE,
                                use_cache = TRUE, verbose = FALSE) {
  entes <- get_entes(use_cache = use_cache, verbose = verbose)
  munis <- entes[entes$uf == state_uf & entes$esfera == "M", , drop = FALSE]
  if (!isTRUE(include_capital) && "capital" %in% names(munis)) {
    munis <- munis[munis$capital != 1, , drop = FALSE]
  }
  if (nrow(munis) == 0L) {
    cli::cli_abort(c(
      "x" = "No municipalities found for {.val {state_uf}}.",
      "i" = "Check the UF code or run {.fun get_entes} to inspect available states."
    ))
  }
  munis
}

# -- Convenience wrappers per API ----------------------------------------------
# Each wrapper sets a safe default page_size for its API.
# SICONFI/SADIPEM: NULL (server default = 5000, fast).
# CUSTOS: 1000 (server default = 250 is too slow; 5000 causes HTTP 504).

#' @noRd
siconfi_fetch_all <- function(endpoint, params = list(), use_cache = TRUE,
                              verbose = FALSE, page_size = NULL,
                              max_rows = Inf) {
  ords_fetch_all(siconfi_base_url(), endpoint, params,
                 use_cache = use_cache, api_name = "SICONFI",
                 verbose = verbose, page_size = page_size,
                 max_rows = max_rows)
}

#' @noRd
custos_fetch_all <- function(endpoint, params = list(), use_cache = TRUE,
                             verbose = FALSE, page_size = 500L,
                             max_rows = Inf) {
  ords_fetch_all(custos_base_url(), endpoint, params,
                 use_cache = use_cache, api_name = "CUSTOS",
                 verbose = verbose, page_size = page_size,
                 max_rows = max_rows)
}

#' @noRd
sadipem_fetch_all <- function(endpoint, params = list(), use_cache = TRUE,
                              verbose = FALSE, page_size = NULL,
                              max_rows = Inf) {
  ords_fetch_all(sadipem_base_url(), endpoint, params,
                 use_cache = use_cache, api_name = "SADIPEM",
                 verbose = verbose, page_size = page_size,
                 max_rows = max_rows)
}

# -- Transferencias fetch ------------------------------------------------------

#' @noRd
transferencias_fetch <- function(endpoint, params = list(),
                                 use_cache = TRUE, verbose = FALSE) {
  url <- paste0(transferencias_base_url(), endpoint)

  cli::cli_alert_info("Fetching {.field Transferencias{endpoint}}...")

  body <- tnr_request(url, params, use_cache = use_cache,
                      api_name = "Transferencias", accept = "*/*",
                      verbose = verbose)

  items <- if (is.data.frame(body)) {
    body
  } else if (!is.null(body[["registros"]])) {
    body[["registros"]]
  } else if (!is.null(body[["items"]])) {
    body[["items"]]
  } else {
    body
  }

  if (is.null(items) || length(items) == 0) {
    cli::cli_alert_warning(
      "No data returned for {.field Transferencias{endpoint}}."
    )
    return(tibble::tibble())
  }

  result <- tryCatch(
    tibble::as_tibble(items),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to parse the Transferencias API response into a tibble.",
        "i" = "Endpoint: {.field {endpoint}}",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  result <- tryCatch(
    dplyr::mutate(result, dplyr::across(dplyr::where(is.character), stringr::str_squish)),
    error = function(e) result
  )

  result <- janitor::clean_names(result)

  cli::cli_alert_success("Done: {.val {nrow(result)}} rows.")

  result
}

# -- SIOPE fetch (OData-style) ------------------------------------------------

#' Build an OData URL for the SIOPE API
#'
#' The SIOPE API uses an OData-style URL pattern:
#' `Resource(Param1=@Param1,Param2=@Param2)?@Param1=value&$format=json`
#'
#' @param resource Character. Resource name (e.g., "Dados_Gerais_Siope").
#' @param params Named list of query parameters.
#' @return Character. Full URL.
#' @noRd
siope_build_url <- function(resource, params) {
  # Build the segment: Resource(P1=@P1,P2=@P2)
  aliases <- paste0(names(params), "=@", names(params), collapse = ",")
  segment <- paste0(resource, "(", aliases, ")")

  # Build query string with @ prefixed aliases
  query_params <- stats::setNames(
    lapply(params, function(v) {
      if (is.character(v)) paste0("'", v, "'") else v
    }),
    paste0("@", names(params))
  )
  query_params[["$format"]] <- "json"

  url <- paste0(siope_base_url(), "/", segment)
  list(url = url, query = query_params)
}

#' Fetch data from the SIOPE API (FNDE/Olinda OData)
#'
#' @param resource Character. OData resource name.
#' @param params Named list of required parameters.
#' @param use_cache Logical.
#' @param verbose Logical.
#' @param max_rows Numeric.
#'
#' @return A tibble.
#' @noRd
siope_fetch <- function(resource, params = list(), use_cache = TRUE,
                        verbose = FALSE, page_size = 1000L,
                        max_rows = Inf, filter = NULL,
                        orderby = NULL, select = NULL) {
  built <- siope_build_url(resource, params)
  url <- built$url
  query <- built$query

  # OData query options
  if (!is.null(filter))  query[["$filter"]]  <- filter
  if (!is.null(orderby)) query[["$orderby"]] <- orderby
  if (!is.null(select))  query[["$select"]]  <- paste(select, collapse = ",")

  all_items <- list()
  page <- 1L
  total_rows <- 0L
  effective_top <- as.integer(page_size)

  # Cap page size at max_rows if smaller

  if (is.finite(max_rows) && max_rows < effective_top) {
    effective_top <- as.integer(max_rows)
  }

  query[["$top"]] <- effective_top

  # Helper: show URL in verbose mode
  show_url <- function() {
    if (is_verbose(verbose)) {
      display_q <- paste0(names(query), "=", query, collapse = "&")
      cli::cli_alert_info("API call: {.url {paste0(url, '?', display_q)}}")
    }
  }

  # -- First page --------------------------------------------------------------
  cli::cli_alert("Fetching {.field SIOPE/{resource}} page {.val {page}}...")
  show_url()

  body <- tnr_request(url, query, use_cache = use_cache,
                      api_name = "SIOPE")

  items <- body[["value"]]

  if (is.null(items) || length(items) == 0) {
    cli::cli_alert_warning("No data returned for {.field SIOPE/{resource}}.")
    return(tibble::tibble())
  }

  page_tbl <- siope_items_to_tibble(items, resource)
  all_items[[page]] <- page_tbl
  total_rows <- total_rows + nrow(page_tbl)

  cli::cli_alert_success(
    "{.field SIOPE/{resource}} | page {.val {page}} | {.val {total_rows}} rows"
  )

  # -- Subsequent pages --------------------------------------------------------
  # OData: if we got exactly $top rows, there might be more
  while (nrow(page_tbl) >= effective_top && total_rows < max_rows) {
    page <- page + 1L
    query[["$skip"]] <- total_rows

    # Adjust $top for last page
    if (is.finite(max_rows)) {
      remaining <- as.integer(max_rows - total_rows)
      query[["$top"]] <- min(effective_top, remaining)
    }

    cli::cli_alert("Fetching {.field SIOPE/{resource}} page {.val {page}}...")
    show_url()

    body <- tnr_request(url, query, use_cache = use_cache,
                        api_name = "SIOPE")
    items <- body[["value"]]

    if (is.null(items) || length(items) == 0) break

    page_tbl <- siope_items_to_tibble(items, resource)
    all_items[[page]] <- page_tbl
    total_rows <- total_rows + nrow(page_tbl)

    cli::cli_alert_success(
      "{.field SIOPE/{resource}} | page {.val {page}} | {.val {total_rows}} rows"
    )
  }

  # -- Assemble result ---------------------------------------------------------
  result <- tryCatch(
    dplyr::bind_rows(all_items),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to assemble SIOPE pages into a tibble.",
        "i" = "Resource: {.field {resource}}",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  result <- tryCatch(
    dplyr::mutate(result, dplyr::across(dplyr::where(is.character), stringr::str_squish)),
    error = function(e) result
  )

  result <- janitor::clean_names(result)

  # Final truncation
  if (is.finite(max_rows) && nrow(result) > max_rows) {
    result <- result[seq_len(max_rows), ]
    cli::cli_alert_success(
      "Done: {.val {nrow(result)}} rows (truncated to max_rows)."
    )
  } else {
    cli::cli_alert_success(
      "Done: {.val {nrow(result)}} rows total ({.val {page}} page{?s})."
    )
  }

  result
}

#' Parse OData items into a tibble with safe type handling
#'
#' OData responses often have mixed types across rows (NULL vs integer vs
#' character for the same field). This helper coerces everything to character
#' first, then converts numeric-looking columns back to numeric.
#'
#' @param items List or data.frame from OData `value`.
#' @param resource Character. Resource name (for error messages).
#' @return A tibble.
#' @noRd
siope_items_to_tibble <- function(items, resource) {
  tbl <- tryCatch({
    if (is.data.frame(items)) {
      tibble::as_tibble(items)
    } else {
      rows <- lapply(items, function(row) {
        lapply(row, function(v) if (is.null(v)) NA_character_ else as.character(v))
      })
      dplyr::bind_rows(lapply(rows, tibble::as_tibble))
    }
  }, error = function(e) {
    cli::cli_abort(c(
      "x" = "Failed to parse SIOPE response into a tibble.",
      "i" = "Resource: {.field {resource}}",
      "i" = "Original error: {conditionMessage(e)}"
    ), call = NULL)
  })

  # Convert numeric-looking character columns back to numeric
  tryCatch(
    dplyr::mutate(tbl, dplyr::across(
      dplyr::where(function(x) {
        is.character(x) && all(grepl("^-?[0-9]+(\\.[0-9]+)?$", x) | is.na(x))
      }),
      as.numeric
    )),
    error = function(e) tbl
  )
}
