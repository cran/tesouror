# ============================================================================
# SICONFI API Functions
# API docs: https://apidatalake.tesouro.gov.br/docs/siconfi/
# ============================================================================

# -- get_entes / get_entities -------------------------------------------------

#' Get list of Brazilian government entities
#'
#' Retrieves the complete list of government entities (entes) registered in the
#' SICONFI system, including states, municipalities, and the Federal District.
#'
#' `get_entities()` is an English alias for `get_entes()`.
#'
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with columns:
#'   \describe{
#'     \item{cod_ibge}{IBGE code of the entity.}
#'     \item{ente}{Name of the entity.}
#'     \item{capital}{Whether the municipality is a state capital (1 = yes, 0 = no).}
#'     \item{regiao}{Geographic region (`"SU"`, `"NE"`, `"NO"`, `"SE"`, `"CO"`, `"BR"`).}
#'     \item{uf}{State abbreviation.}
#'     \item{esfera}{Government sphere: `"M"`, `"E"`, `"U"`, `"D"`.}
#'     \item{an_exercicio}{Year of the population data.}
#'     \item{populacao}{Estimated population.}
#'     \item{co_cnpj}{CNPJ of the entity.}
#'   }
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' entes <- get_entes()
#' }
get_entes <- function(use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  siconfi_fetch_all("/entes", use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_entes
#' @usage get_entities(use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_entities <- function(use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  get_entes(use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_anexos / get_annexes -------------------------------------------------

#' Get report appendix reference table
#'
#' Retrieves the reference table of report appendices (anexos) grouped by
#' government sphere. This is a support table that describes which appendices
#' are available for each report type (RREO, RGF, DCA, etc.).
#'
#' `get_annexes()` is an English alias for `get_anexos()`.
#'
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with columns:
#'   \describe{
#'     \item{esfera}{Government sphere: `"U"` (Union), `"E"` (States), `"M"` (Municipalities).}
#'     \item{demonstrativo}{Report type (e.g., `"RREO"`, `"RGF"`, `"DCA"`).}
#'     \item{anexo}{Appendix name (e.g., `"RREO-Anexo 01"`).}
#'   }
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' anexos <- get_anexos()
#' }
get_anexos <- function(use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  siconfi_fetch_all("/anexos-relatorios", use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_anexos
#' @usage get_annexes(use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_annexes <- function(use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  get_anexos(use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_dca / get_annual_accounts --------------------------------------------

#' Get annual accounts data (DCA)
#'
#' Retrieves data from the Annual Accounts Declaration (DCA) or the legacy
#' QDCC for a specific entity and fiscal year.
#'
#' `get_annual_accounts()` is an English alias for `get_dca()`.
#'
#' @param an_exercicio Integer. Fiscal year (e.g., `2022`). **Required**.
#' @param id_ente Integer. IBGE code of the entity. **Required**.
#' @param no_anexo Character. Appendix name filter (e.g., `"DCA-Anexo I-AB"`).
#'   Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with DCA/QDCC data including columns such
#'   as `exercicio`, `instituicao`, `cod_ibge`, `uf`, `anexo`, `rotulo`,
#'   `coluna`, `cod_conta`, `conta`, `valor`, and `populacao`.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' dca <- get_dca(an_exercicio = 2022, id_ente = 17)
#' }
get_dca <- function(an_exercicio, id_ente, no_anexo = NULL, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(an_exercicio, id_ente)

  params <- list(
    an_exercicio = an_exercicio,
    id_ente      = id_ente,
    no_anexo     = no_anexo
  )

  siconfi_fetch_all("/dca", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_dca
#' @param fiscal_year Integer. Fiscal year (e.g., `2022`). **Required**.
#'   Maps to `an_exercicio`.
#' @param entity_id Integer. IBGE code of the entity. **Required**.
#'   Maps to `id_ente`.
#' @param appendix Character. Appendix name filter (e.g.,
#'   `"DCA-Anexo I-AB"`). Optional. Maps to `no_anexo`.
#' @usage get_annual_accounts(fiscal_year, entity_id, appendix = NULL,
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_annual_accounts <- function(fiscal_year, entity_id, appendix = NULL,
                                use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(fiscal_year, entity_id)
  get_dca(
    an_exercicio = fiscal_year,
    id_ente      = entity_id,
    no_anexo     = appendix,
    use_cache    = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_dca_for_state / get_annual_accounts_for_state ------------------------

#' Get DCA data for all municipalities of a Brazilian state
#'
#' Fetches annual accounts (DCA) for every municipality of `state_uf`, looping
#' over [get_dca()] with fault tolerance. See [get_rreo_for_state()] for the
#' rationale and behaviour of `on_error`.
#'
#' `get_annual_accounts_for_state()` is an English-parameter alias.
#'
#' @param state_uf Character. Two-letter UF code (e.g., `"PE"`). **Required**.
#' @param an_exercicio Integer. Fiscal year. **Required**.
#' @param no_anexo Character. Appendix name filter (e.g., `"DCA-Anexo I-AB"`).
#'   Optional.
#' @param include_capital Logical. Include the state capital? Defaults to `TRUE`.
#' @param on_error Character. `"warn"` (default), `"stop"`, or `"silent"`.
#' @param use_cache Logical.
#' @param verbose Logical.
#' @param page_size Integer or `NULL`.
#' @param max_rows Numeric.
#'
#' @return A [tibble][tibble::tibble] with all successful DCA rows. If any
#'   call failed, has an attribute `"failed"`.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' dca_pe <- get_dca_for_state(state_uf = "PE", an_exercicio = 2022)
#' }
get_dca_for_state <- function(state_uf, an_exercicio, no_anexo = NULL,
                              include_capital = TRUE,
                              on_error = c("warn", "stop", "silent"),
                              use_cache = TRUE, verbose = FALSE,
                              page_size = NULL, max_rows = Inf) {
  check_required(state_uf, an_exercicio)
  on_error <- match.arg(on_error)

  munis <- resolve_state_munis(
    state_uf = state_uf, include_capital = include_capital,
    use_cache = use_cache, verbose = verbose
  )

  param_list <- lapply(munis$cod_ibge, function(id) {
    list(
      an_exercicio = an_exercicio,
      id_ente      = id,
      no_anexo     = no_anexo,
      use_cache    = use_cache,
      verbose      = verbose,
      page_size    = page_size,
      max_rows     = max_rows
    )
  })

  tnr_loop(
    .f             = get_dca,
    .params        = param_list,
    .id            = "id_ente",
    on_error       = on_error,
    progress_label = paste0("DCA ", state_uf)
  )
}

#' @rdname get_dca_for_state
#' @param fiscal_year Integer. Fiscal year. **Required**. Maps to `an_exercicio`.
#' @param appendix Character. Appendix name filter. Optional. Maps to `no_anexo`.
#' @usage get_annual_accounts_for_state(state_uf, fiscal_year, appendix = NULL,
#'   include_capital = TRUE, on_error = c("warn", "stop", "silent"),
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_annual_accounts_for_state <- function(state_uf, fiscal_year, appendix = NULL,
                                          include_capital = TRUE,
                                          on_error = c("warn", "stop", "silent"),
                                          use_cache = TRUE, verbose = FALSE,
                                          page_size = NULL, max_rows = Inf) {
  check_required(state_uf, fiscal_year)
  get_dca_for_state(
    state_uf        = state_uf,
    an_exercicio    = fiscal_year,
    no_anexo        = appendix,
    include_capital = include_capital,
    on_error        = on_error,
    use_cache       = use_cache,
    verbose         = verbose,
    page_size       = page_size,
    max_rows        = max_rows
  )
}

# -- get_extrato / get_delivery_status ----------------------------------------

#' Get delivery status extract
#'
#' Retrieves the extract of report deliveries for a given entity and reference
#' year. Useful for checking which reports have been submitted and their status
#' (approved, rectified, etc.).
#'
#' `get_delivery_status()` is an English alias for `get_extrato()`.
#'
#' @param id_ente Integer. IBGE code of the entity. **Required**.
#' @param an_referencia Integer. Reference year (e.g., `2022`). **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with delivery status data including
#'   columns such as `exercicio`, `cod_ibge`, `instituicao`, `entregavel`,
#'   `periodo`, `periodicidade`, `status_relatorio`, `data_status`,
#'   `forma_envio`, and `tipo_relatorio`.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' extrato <- get_extrato(id_ente = 17, an_referencia = 2022)
#' }
get_extrato <- function(id_ente, an_referencia, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_ente, an_referencia)

  params <- list(
    id_ente       = id_ente,
    an_referencia = an_referencia
  )

  siconfi_fetch_all("/extrato_entregas", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_extrato
#' @param entity_id Integer. IBGE code of the entity. **Required**.
#'   Maps to `id_ente`.
#' @param year Integer. Reference year (e.g., `2022`). **Required**.
#'   Maps to `an_referencia`.
#' @usage get_delivery_status(entity_id, year, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_delivery_status <- function(entity_id, year, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(entity_id, year)
  get_extrato(
    id_ente       = entity_id,
    an_referencia = year,
    use_cache     = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_rreo / get_budget_report ---------------------------------------------

#' Get Budget Execution Summary Report data (RREO)
#'
#' Retrieves data from the Budget Execution Summary Report (RREO) for specific
#' filtering criteria. The RREO is published bimonthly and contains
#' information about revenues, expenses, and other budgetary data.
#'
#' `get_budget_report()` is an English-parameter alias for this function.
#'
#' @param an_exercicio Integer. Fiscal year (e.g., `2022`). **Required**.
#' @param nr_periodo Integer. Bimester number (1-6). **Required**.
#' @param co_tipo_demonstrativo Character. Report type: `"RREO"` or
#'   `"RREO Simplificado"`. **Required**. Note: `"RREO Simplificado"` applies
#'   only to municipalities with fewer than 50,000 inhabitants that opted for
#'   simplified reporting.
#' @param no_anexo Character. Appendix name (e.g., `"RREO-Anexo 01"`).
#'   **Required**.
#' @param co_esfera Character. Government sphere: `"M"` (municipalities),
#'   `"E"` (states), or `"U"` (union). **Required**.
#' @param id_ente Integer. IBGE code of the entity. **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with RREO data including columns such as
#'   `exercicio`, `demonstrativo`, `periodo`, `periodicidade`, `instituicao`,
#'   `cod_ibge`, `uf`, `populacao`, `anexo`, `rotulo`, `coluna`, `cod_conta`,
#'   `conta`, and `valor`.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' rreo <- get_rreo(
#'   an_exercicio = 2022, nr_periodo = 6,
#'   co_tipo_demonstrativo = "RREO",
#'   no_anexo = "RREO-Anexo 01",
#'   co_esfera = "E", id_ente = 17
#' )
#' }
get_rreo <- function(an_exercicio, nr_periodo, co_tipo_demonstrativo,
                     no_anexo, co_esfera, id_ente, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    an_exercicio, nr_periodo, co_tipo_demonstrativo,
    no_anexo, co_esfera, id_ente
  )

  params <- list(
    an_exercicio          = an_exercicio,
    nr_periodo            = nr_periodo,
    co_tipo_demonstrativo = co_tipo_demonstrativo,
    no_anexo              = no_anexo,
    co_esfera             = co_esfera,
    id_ente               = id_ente
  )

  siconfi_fetch_all("/rreo", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_rreo
#' @param fiscal_year Integer. Fiscal year (e.g., `2022`). **Required**.
#'   Maps to `an_exercicio`.
#' @param period Integer. Bimester number (1-6). **Required**.
#'   Maps to `nr_periodo`.
#' @param report_type Character. Report type: `"RREO"` or
#'   `"RREO Simplificado"`. **Required**. Maps to `co_tipo_demonstrativo`.
#' @param appendix Character. Appendix name (e.g., `"RREO-Anexo 01"`).
#'   **Required**. Maps to `no_anexo`.
#' @param sphere Character. Government sphere: `"M"` (municipalities),
#'   `"E"` (states), or `"U"` (union). **Required**. Maps to `co_esfera`.
#' @param entity_id Integer. IBGE code of the entity. **Required**.
#'   Maps to `id_ente`.
#' @usage get_budget_report(fiscal_year, period, report_type, appendix,
#'   sphere, entity_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_budget_report <- function(fiscal_year, period, report_type,
                              appendix, sphere, entity_id,
                              use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(fiscal_year, period, report_type, appendix, sphere, entity_id)
  get_rreo(
    an_exercicio          = fiscal_year,
    nr_periodo            = period,
    co_tipo_demonstrativo = report_type,
    no_anexo              = appendix,
    co_esfera             = sphere,
    id_ente               = entity_id,
    use_cache             = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_rreo_for_state / get_budget_report_for_state -------------------------

#' Get RREO data for all municipalities of a Brazilian state
#'
#' Fetches RREO data for every municipality of `state_uf`, looping over
#' [get_rreo()] with fault tolerance: if an individual municipality call fails
#' after all retries, the failure is recorded and the loop continues. Failed
#' calls are returned in `attr(result, "failed")`.
#'
#' This is the recommended way to assemble a state-wide panel: it handles
#' pagination per municipality, uses the cache, and surfaces partial failures
#' instead of aborting on the first error (see SICONFI behaviour for entities
#' that have not yet homologated a given report).
#'
#' `get_budget_report_for_state()` is an English-parameter alias.
#'
#' @param state_uf Character. Two-letter UF code (e.g., `"PE"`, `"ES"`).
#'   **Required**.
#' @param an_exercicio Integer. Fiscal year. **Required**.
#' @param nr_periodo Integer. Bimester (1-6). **Required**.
#' @param co_tipo_demonstrativo Character. `"RREO"` or `"RREO Simplificado"`.
#'   **Required**.
#' @param no_anexo Character. Appendix name (e.g., `"RREO-Anexo 01"`).
#'   **Required**.
#' @param include_capital Logical. Include the state capital? Defaults to `TRUE`.
#' @param on_error Character. One of `"warn"` (default — log and continue),
#'   `"stop"` (abort on first failure), or `"silent"` (record but no message).
#' @param use_cache Logical. If `TRUE` (default), uses the in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL for each call.
#' @param page_size Integer or `NULL`. Rows per API page.
#' @param max_rows Numeric. Maximum rows per municipality call.
#'
#' @return A [tibble][tibble::tibble] with RREO rows for all successful
#'   municipalities. If any call failed, has an attribute `"failed"` (tibble
#'   with `iteration`, `id`, `error`).
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' rreo_es <- get_rreo_for_state(
#'   state_uf = "ES", an_exercicio = 2021, nr_periodo = 6,
#'   co_tipo_demonstrativo = "RREO", no_anexo = "RREO-Anexo 01"
#' )
#' attr(rreo_es, "failed")
#' }
get_rreo_for_state <- function(state_uf,
                               an_exercicio, nr_periodo, co_tipo_demonstrativo,
                               no_anexo,
                               include_capital = TRUE,
                               on_error = c("warn", "stop", "silent"),
                               use_cache = TRUE, verbose = FALSE,
                               page_size = NULL, max_rows = Inf) {
  check_required(state_uf, an_exercicio, nr_periodo, co_tipo_demonstrativo, no_anexo)
  on_error <- match.arg(on_error)

  munis <- resolve_state_munis(
    state_uf = state_uf, include_capital = include_capital,
    use_cache = use_cache, verbose = verbose
  )

  param_list <- lapply(munis$cod_ibge, function(id) {
    list(
      an_exercicio          = an_exercicio,
      nr_periodo            = nr_periodo,
      co_tipo_demonstrativo = co_tipo_demonstrativo,
      no_anexo              = no_anexo,
      co_esfera             = "M",
      id_ente               = id,
      use_cache             = use_cache,
      verbose               = verbose,
      page_size             = page_size,
      max_rows              = max_rows
    )
  })

  tnr_loop(
    .f             = get_rreo,
    .params        = param_list,
    .id            = "id_ente",
    on_error       = on_error,
    progress_label = paste0("RREO ", state_uf)
  )
}

#' @rdname get_rreo_for_state
#' @param fiscal_year Integer. Fiscal year. **Required**. Maps to
#'   `an_exercicio`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `nr_periodo`.
#' @param report_type Character. `"RREO"` or `"RREO Simplificado"`.
#'   **Required**. Maps to `co_tipo_demonstrativo`.
#' @param appendix Character. Appendix name. **Required**. Maps to `no_anexo`.
#' @usage get_budget_report_for_state(state_uf, fiscal_year, period,
#'   report_type, appendix, include_capital = TRUE,
#'   on_error = c("warn", "stop", "silent"),
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_budget_report_for_state <- function(state_uf,
                                        fiscal_year, period, report_type,
                                        appendix,
                                        include_capital = TRUE,
                                        on_error = c("warn", "stop", "silent"),
                                        use_cache = TRUE, verbose = FALSE,
                                        page_size = NULL, max_rows = Inf) {
  check_required(state_uf, fiscal_year, period, report_type, appendix)
  get_rreo_for_state(
    state_uf              = state_uf,
    an_exercicio          = fiscal_year,
    nr_periodo            = period,
    co_tipo_demonstrativo = report_type,
    no_anexo              = appendix,
    include_capital       = include_capital,
    on_error              = on_error,
    use_cache             = use_cache,
    verbose               = verbose,
    page_size             = page_size,
    max_rows              = max_rows
  )
}

# -- get_rgf / get_fiscal_report ----------------------------------------------

#' Get Fiscal Management Report data (RGF)
#'
#' Retrieves data from the Fiscal Management Report (RGF) for specific
#' filtering criteria. The RGF contains information about personnel expenses,
#' debt, credit operations, and other fiscal indicators.
#'
#' `get_fiscal_report()` is an English-parameter alias for this function.
#'
#' @param an_exercicio Integer. Fiscal year (e.g., `2022`). **Required**.
#' @param in_periodicidade Character. Periodicity: `"Q"` (four-monthly) or
#'   `"S"` (semi-annual). **Required**.
#' @param nr_periodo Integer. Period number (1-3 for four-monthly, 1-2 for
#'   semi-annual). **Required**.
#' @param co_tipo_demonstrativo Character. Report type: `"RGF"` or
#'   `"RGF Simplificado"`. **Required**.
#' @param no_anexo Character. Appendix name (e.g., `"RGF-Anexo 01"`).
#'   **Required**.
#' @param co_esfera Character. Government sphere: `"M"` (municipalities),
#'   `"E"` (states), or `"U"` (union). **Required**.
#' @param co_poder Character. Government branch: `"E"` (executive),
#'   `"L"` (legislative), `"J"` (judiciary), `"M"` (public ministry),
#'   `"D"` (public defender). **Required**.
#' @param id_ente Integer. IBGE code of the entity. **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with RGF data.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' rgf <- get_rgf(
#'   an_exercicio = 2022, in_periodicidade = "Q", nr_periodo = 3,
#'   co_tipo_demonstrativo = "RGF", no_anexo = "RGF-Anexo 01",
#'   co_esfera = "E", co_poder = "E", id_ente = 17
#' )
#' }
get_rgf <- function(an_exercicio, in_periodicidade, nr_periodo,
                    co_tipo_demonstrativo, no_anexo, co_esfera,
                    co_poder, id_ente, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    an_exercicio, in_periodicidade, nr_periodo,
    co_tipo_demonstrativo, no_anexo, co_esfera,
    co_poder, id_ente
  )

  params <- list(
    an_exercicio          = an_exercicio,
    in_periodicidade      = in_periodicidade,
    nr_periodo            = nr_periodo,
    co_tipo_demonstrativo = co_tipo_demonstrativo,
    no_anexo              = no_anexo,
    co_esfera             = co_esfera,
    co_poder              = co_poder,
    id_ente               = id_ente
  )

  siconfi_fetch_all("/rgf", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_rgf
#' @param fiscal_year Integer. Fiscal year (e.g., `2022`). **Required**.
#'   Maps to `an_exercicio`.
#' @param periodicity Character. Periodicity: `"Q"` (quadrimester) or
#'   `"S"` (semester). **Required**. Maps to `in_periodicidade`.
#' @param period Integer. Period number: `1`-`3` (quadrimester) or
#'   `1`-`2` (semester). **Required**. Maps to `nr_periodo`.
#' @param report_type Character. Report type: `"RGF"` or
#'   `"RGF Simplificado"`. **Required**. Maps to `co_tipo_demonstrativo`.
#' @param appendix Character. Appendix name (e.g., `"RGF-Anexo 01"`).
#'   **Required**. Maps to `no_anexo`.
#' @param sphere Character. Government sphere: `"M"`, `"E"`, or `"U"`.
#'   **Required**. Maps to `co_esfera`.
#' @param branch Character. Government branch: `"E"` (executive),
#'   `"L"` (legislative), `"J"` (judiciary), `"M"` (public ministry),
#'   `"D"` (public defender). **Required**. Maps to `co_poder`.
#' @param entity_id Integer. IBGE code of the entity. **Required**.
#'   Maps to `id_ente`.
#' @usage get_fiscal_report(fiscal_year, periodicity, period, report_type,
#'   appendix, sphere, branch, entity_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_fiscal_report <- function(fiscal_year, periodicity, period,
                              report_type, appendix, sphere,
                              branch, entity_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    fiscal_year, periodicity, period, report_type,
    appendix, sphere, branch, entity_id
  )
  get_rgf(
    an_exercicio          = fiscal_year,
    in_periodicidade      = periodicity,
    nr_periodo            = period,
    co_tipo_demonstrativo = report_type,
    no_anexo              = appendix,
    co_esfera             = sphere,
    co_poder              = branch,
    id_ente               = entity_id,
    use_cache             = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_rgf_for_state / get_fiscal_report_for_state --------------------------

#' Get RGF data for all municipalities of a Brazilian state
#'
#' Fetches RGF data for every municipality of `state_uf`, looping over
#' [get_rgf()] with fault tolerance. See [get_rreo_for_state()] for the
#' rationale and behaviour of `on_error`.
#'
#' `get_fiscal_report_for_state()` is an English-parameter alias.
#'
#' @param state_uf Character. Two-letter UF code (e.g., `"PE"`). **Required**.
#' @param an_exercicio Integer. Fiscal year. **Required**.
#' @param in_periodicidade Character. `"Q"` (four-monthly) or `"S"`
#'   (semi-annual). **Required**.
#' @param nr_periodo Integer. Period number. **Required**.
#' @param co_tipo_demonstrativo Character. `"RGF"` or `"RGF Simplificado"`.
#'   **Required**.
#' @param no_anexo Character. Appendix name (e.g., `"RGF-Anexo 01"`).
#'   **Required**.
#' @param co_poder Character. Government branch: `"E"`, `"L"`, `"J"`, `"M"`,
#'   `"D"`. **Required**.
#' @param include_capital Logical. Include the state capital? Defaults to `TRUE`.
#' @param on_error Character. `"warn"` (default), `"stop"`, or `"silent"`.
#' @param use_cache Logical.
#' @param verbose Logical.
#' @param page_size Integer or `NULL`.
#' @param max_rows Numeric.
#'
#' @return A [tibble][tibble::tibble] with all successful RGF rows. If any
#'   call failed, has an attribute `"failed"`.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' rgf_pe <- get_rgf_for_state(
#'   state_uf = "PE", an_exercicio = 2022,
#'   in_periodicidade = "Q", nr_periodo = 3,
#'   co_tipo_demonstrativo = "RGF", no_anexo = "RGF-Anexo 01",
#'   co_poder = "E"
#' )
#' }
get_rgf_for_state <- function(state_uf,
                              an_exercicio, in_periodicidade, nr_periodo,
                              co_tipo_demonstrativo, no_anexo, co_poder,
                              include_capital = TRUE,
                              on_error = c("warn", "stop", "silent"),
                              use_cache = TRUE, verbose = FALSE,
                              page_size = NULL, max_rows = Inf) {
  check_required(
    state_uf, an_exercicio, in_periodicidade, nr_periodo,
    co_tipo_demonstrativo, no_anexo, co_poder
  )
  on_error <- match.arg(on_error)

  munis <- resolve_state_munis(
    state_uf = state_uf, include_capital = include_capital,
    use_cache = use_cache, verbose = verbose
  )

  param_list <- lapply(munis$cod_ibge, function(id) {
    list(
      an_exercicio          = an_exercicio,
      in_periodicidade      = in_periodicidade,
      nr_periodo            = nr_periodo,
      co_tipo_demonstrativo = co_tipo_demonstrativo,
      no_anexo              = no_anexo,
      co_esfera             = "M",
      co_poder              = co_poder,
      id_ente               = id,
      use_cache             = use_cache,
      verbose               = verbose,
      page_size             = page_size,
      max_rows              = max_rows
    )
  })

  tnr_loop(
    .f             = get_rgf,
    .params        = param_list,
    .id            = "id_ente",
    on_error       = on_error,
    progress_label = paste0("RGF ", state_uf)
  )
}

#' @rdname get_rgf_for_state
#' @param fiscal_year Integer. Fiscal year. **Required**. Maps to `an_exercicio`.
#' @param periodicity Character. `"Q"` or `"S"`. **Required**.
#'   Maps to `in_periodicidade`.
#' @param period Integer. Period number. **Required**. Maps to `nr_periodo`.
#' @param report_type Character. `"RGF"` or `"RGF Simplificado"`.
#'   **Required**. Maps to `co_tipo_demonstrativo`.
#' @param appendix Character. Appendix name. **Required**. Maps to `no_anexo`.
#' @param branch Character. Government branch. **Required**. Maps to
#'   `co_poder`.
#' @usage get_fiscal_report_for_state(state_uf, fiscal_year, periodicity,
#'   period, report_type, appendix, branch,
#'   include_capital = TRUE, on_error = c("warn", "stop", "silent"),
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_fiscal_report_for_state <- function(state_uf,
                                        fiscal_year, periodicity, period,
                                        report_type, appendix, branch,
                                        include_capital = TRUE,
                                        on_error = c("warn", "stop", "silent"),
                                        use_cache = TRUE, verbose = FALSE,
                                        page_size = NULL, max_rows = Inf) {
  check_required(
    state_uf, fiscal_year, periodicity, period,
    report_type, appendix, branch
  )
  get_rgf_for_state(
    state_uf              = state_uf,
    an_exercicio          = fiscal_year,
    in_periodicidade      = periodicity,
    nr_periodo            = period,
    co_tipo_demonstrativo = report_type,
    no_anexo              = appendix,
    co_poder              = branch,
    include_capital       = include_capital,
    on_error              = on_error,
    use_cache             = use_cache,
    verbose               = verbose,
    page_size             = page_size,
    max_rows              = max_rows
  )
}

# -- get_msc_controle / get_msc_control ---------------------------------------

#' Get MSC control accounts data
#'
#' Retrieves control accounts data (classes 7 and 8) from the
#' Accounting Balances Matrix (MSC).
#'
#' `get_msc_control()` is an English alias for `get_msc_controle()`.
#'
#' @param id_ente Integer. IBGE code of the entity. **Required**.
#' @param an_referencia Integer. Reference year. **Required**.
#' @param me_referencia Integer. Reference month (1-12). **Required**.
#' @param co_tipo_matriz Character. Matrix type: `"MSCC"` (monthly aggregate)
#'   or `"MSCE"` (annual closing). **Required**.
#' @param classe_conta Integer. Account class: `7` or `8`. **Required**.
#' @param id_tv Character. Value type: `"beginning_balance"`,
#'   `"ending_balance"`, or `"period_change"`. **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#' @param page_size Integer or `NULL`. Number of rows per API page.
#'   If `NULL` (default), uses the API server default (5000 for
#'   SICONFI/SADIPEM).
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with MSC control account data.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' msc_ctrl <- get_msc_controle(
#'   id_ente = 17, an_referencia = 2022, me_referencia = 12,
#'   co_tipo_matriz = "MSCC", classe_conta = 8,
#'   id_tv = "ending_balance"
#' )
#' }
get_msc_controle <- function(id_ente, an_referencia, me_referencia,
                             co_tipo_matriz, classe_conta, id_tv,
                             use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    id_ente, an_referencia, me_referencia,
    co_tipo_matriz, classe_conta, id_tv
  )

  params <- list(
    id_ente        = id_ente,
    an_referencia  = an_referencia,
    me_referencia  = me_referencia,
    co_tipo_matriz = co_tipo_matriz,
    classe_conta   = classe_conta,
    id_tv          = id_tv
  )

  siconfi_fetch_all("/msc_controle", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_msc_controle
#' @param entity_id Integer. IBGE code of the entity. **Required**.
#'   Maps to `id_ente`.
#' @param year Integer. Reference year. **Required**. Maps to
#'   `an_referencia`.
#' @param month Integer. Reference month (1-12). **Required**. Maps to
#'   `me_referencia`.
#' @param matrix_type Character. Matrix type: `"MSCC"` (monthly
#'   aggregate) or `"MSCE"` (annual closing). **Required**. Maps to
#'   `co_tipo_matriz`.
#' @param account_class Integer. Account class: `7` or `8`. **Required**.
#'   Maps to `classe_conta`.
#' @param value_type Character. Value type: `"beginning_balance"`,
#'   `"ending_balance"`, or `"period_change"`. **Required**. Maps to
#'   `id_tv`.
#' @usage get_msc_control(entity_id, year, month, matrix_type, account_class,
#'   value_type, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_msc_control <- function(entity_id, year, month,
                            matrix_type, account_class, value_type,
                            use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(entity_id, year, month, matrix_type, account_class, value_type)
  get_msc_controle(
    id_ente        = entity_id,
    an_referencia  = year,
    me_referencia  = month,
    co_tipo_matriz = matrix_type,
    classe_conta   = account_class,
    id_tv          = value_type,
    use_cache      = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_msc_orcamentaria / get_msc_budget ------------------------------------

#' Get MSC budgetary accounts data
#'
#' Retrieves budgetary accounts data (classes 5 and 6) from the
#' Accounting Balances Matrix (MSC).
#'
#' `get_msc_budget()` is an English alias for `get_msc_orcamentaria()`.
#'
#' @inheritParams get_msc_controle
#' @param classe_conta Integer. Account class: `5` or `6`. **Required**.
#'
#'
#' @return A [tibble][tibble::tibble] with MSC budgetary account data.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' msc_orc <- get_msc_orcamentaria(
#'   id_ente = 17, an_referencia = 2022, me_referencia = 12,
#'   co_tipo_matriz = "MSCC", classe_conta = 6,
#'   id_tv = "period_change"
#' )
#' }
get_msc_orcamentaria <- function(id_ente, an_referencia, me_referencia,
                                 co_tipo_matriz, classe_conta, id_tv,
                                 use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    id_ente, an_referencia, me_referencia,
    co_tipo_matriz, classe_conta, id_tv
  )

  params <- list(
    id_ente        = id_ente,
    an_referencia  = an_referencia,
    me_referencia  = me_referencia,
    co_tipo_matriz = co_tipo_matriz,
    classe_conta   = classe_conta,
    id_tv          = id_tv
  )

  siconfi_fetch_all("/msc_orcamentaria", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_msc_orcamentaria
#' @inheritParams get_msc_control
#' @param account_class Integer. Account class: `5` or `6`. **Required**.
#'   Maps to `classe_conta`.
#' @usage get_msc_budget(entity_id, year, month, matrix_type, account_class,
#'   value_type, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_msc_budget <- function(entity_id, year, month,
                           matrix_type, account_class, value_type,
                           use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(entity_id, year, month, matrix_type, account_class, value_type)
  get_msc_orcamentaria(
    id_ente        = entity_id,
    an_referencia  = year,
    me_referencia  = month,
    co_tipo_matriz = matrix_type,
    classe_conta   = account_class,
    id_tv          = value_type,
    use_cache      = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}

# -- get_msc_patrimonial / get_msc_equity -------------------------------------

#' Get MSC equity/asset accounts data
#'
#' Retrieves equity and asset accounts data (classes 1 to 4) from the
#' Accounting Balances Matrix (MSC).
#'
#' `get_msc_equity()` is an English alias for `get_msc_patrimonial()`.
#'
#' @inheritParams get_msc_controle
#' @param classe_conta Integer. Account class: `1`, `2`, `3`, or `4`.
#'   **Required**.
#'
#'
#' @return A [tibble][tibble::tibble] with MSC equity/asset account data.
#'
#' @family SICONFI
#' @export
#' @examples
#' \dontrun{
#' msc_pat <- get_msc_patrimonial(
#'   id_ente = 17, an_referencia = 2022, me_referencia = 12,
#'   co_tipo_matriz = "MSCC", classe_conta = 1,
#'   id_tv = "ending_balance"
#' )
#' }
get_msc_patrimonial <- function(id_ente, an_referencia, me_referencia,
                                co_tipo_matriz, classe_conta, id_tv,
                                use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(
    id_ente, an_referencia, me_referencia,
    co_tipo_matriz, classe_conta, id_tv
  )

  params <- list(
    id_ente        = id_ente,
    an_referencia  = an_referencia,
    me_referencia  = me_referencia,
    co_tipo_matriz = co_tipo_matriz,
    classe_conta   = classe_conta,
    id_tv          = id_tv
  )

  siconfi_fetch_all("/msc_patrimonial", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_msc_patrimonial
#' @inheritParams get_msc_control
#' @param account_class Integer. Account class: `1`, `2`, `3`, or `4`.
#'   **Required**. Maps to `classe_conta`.
#' @usage get_msc_equity(entity_id, year, month, matrix_type, account_class,
#'   value_type, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_msc_equity <- function(entity_id, year, month,
                           matrix_type, account_class, value_type,
                           use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(entity_id, year, month, matrix_type, account_class, value_type)
  get_msc_patrimonial(
    id_ente        = entity_id,
    an_referencia  = year,
    me_referencia  = month,
    co_tipo_matriz = matrix_type,
    classe_conta   = account_class,
    id_tv          = value_type,
    use_cache      = use_cache,
    verbose      = verbose,
    page_size    = page_size,
    max_rows  = max_rows
  )
}
