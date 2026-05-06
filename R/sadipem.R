# ============================================================================
# SADIPEM API Functions (Public Debt and Credit Operations)
# API docs: https://apidatalake.tesouro.gov.br/docs/sadipem/
# Base URL: https://apidatalake.tesouro.gov.br/ords/sadipem/tt/
#
# Typical workflow:
#   1. Search PVLs with get_pvl() / get_debt_requests()
#   2. Pick an id_pleito from the results
#   3. Use that id_pleito in detail functions (get_pvl_tramitacao, etc.)
# ============================================================================

# -- get_pvl / get_debt_requests ----------------------------------------------

#' Get public debt verification requests (PVL)
#'
#' Retrieves data from the Public Debt Verification Letters (PVL) system.
#' These are requests for approval of credit operations and debt by
#' subnational entities. Use the resulting `id_pleito` column to query
#' detail functions like [get_pvl_tramitacao()], [get_opc_cronograma_liberacoes()],
#' etc.
#'
#' `get_debt_requests()` is an English alias.
#'
#' @param uf Character. State abbreviation (e.g., `"PE"`). Optional.
#' @param tipo_interessado Character. Type of requesting entity (e.g.,
#'   `"Município"`, `"Estado"`). Optional.
#' @param id_ente Integer. IBGE code of the requesting entity. Optional.
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
#' @return A [tibble][tibble::tibble] with PVL data including `id_pleito`,
#'   `tipo_interessado`, `interessado`, `cod_ibge`, `uf`, `status`,
#'   `tipo_operacao`, `finalidade`, `credor`, `valor`, and more.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' # Search all PVLs for Pernambuco
#' pvl_pe <- get_pvl(uf = "PE")
#'
#' # Search by IBGE code (Recife)
#' pvl_recife <- get_pvl(id_ente = 2611606)
#'
#' # Use id_pleito from results for detail queries:
#' id <- pvl_pe$id_pleito[1]
#' pagamentos <- get_opc_cronograma_pagamentos(id_pleito = id)
#' cdp <- get_res_cdp(id_pleito = id)
#'
#' # For PVL processing status, filter approved PVLs first:
#' deferidos <- pvl_pe[pvl_pe$status == "Deferido", ]
#' if (nrow(deferidos) > 0) {
#'   status <- get_pvl_tramitacao(id_pleito = deferidos$id_pleito[1])
#' }
#' }
get_pvl <- function(uf = NULL, tipo_interessado = NULL, id_ente = NULL,
                    use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  params <- list(
    uf               = uf,
    tipo_interessado = tipo_interessado,
    id_ente          = id_ente
  )
  sadipem_fetch_all("/pvl", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_pvl
#' @param state Character. State abbreviation (e.g., `"PE"`). Optional.
#'   Maps to `uf`.
#' @param entity_type Character. Type of requesting entity (e.g.,
#'   `"Município"`, `"Estado"`). Optional. Maps to `tipo_interessado`.
#' @param entity_id Integer. IBGE code of the requesting entity. Optional.
#'   Maps to `id_ente`.
#' @usage get_debt_requests(state = NULL, entity_type = NULL,
#'   entity_id = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_debt_requests <- function(state = NULL, entity_type = NULL,
                              entity_id = NULL, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  get_pvl(uf = state, tipo_interessado = entity_type, id_ente = entity_id,
          use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_pvl_tramitacao / get_pvl_status --------------------------------------

#' Get PVL processing status (approved non-credit operations)
#'
#' Retrieves processing status for PVL requests that were **approved
#' (deferred)** and involve **non-credit operations**. This endpoint only
#' returns data for PVLs with status `"Deferido"`. For most PVLs (e.g.,
#' archived, in progress, or credit operations), this will return an
#' empty tibble.
#'
#' To find PVLs that have data in this endpoint, filter by
#' `status == "Deferido"` in the results of [get_pvl()].
#'
#' `get_pvl_status()` is an English alias.
#'
#' @param id_pleito Integer. Database ID of a **deferred** PVL request
#'   (from the `id_pleito` column of [get_pvl()]). **Required**.
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
#' @return A [tibble][tibble::tibble] with PVL processing status data.
#'   Returns an empty tibble if the PVL is not an approved non-credit
#'   operation.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' # Step 1: search PVLs and filter for approved ones
#' pvl_pe <- get_pvl(uf = "PE")
#' pvl_deferidos <- pvl_pe[pvl_pe$status == "Deferido", ]
#'
#' # Step 2: pick an id_pleito from the APPROVED requests
#' id <- pvl_deferidos$id_pleito[1]
#'
#' # Step 3: get processing status (only works for deferred PVLs)
#' status <- get_pvl_tramitacao(id_pleito = id)
#' }
get_pvl_tramitacao <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/opnc-pvl-tramitacao-deferido", params,
                    use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_pvl_tramitacao
#' @param request_id Integer. Database ID of a **deferred** PVL request.
#'   Obtain from the `id_pleito` column of [get_pvl()] results, filtered
#'   by `status == "Deferido"`. **Required**. Maps to `id_pleito`.
#' @usage get_pvl_status(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_pvl_status <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_pvl_tramitacao(id_pleito = request_id, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_opc_cronograma_liberacoes / get_credit_release_schedule --------------

#' Get credit operation release schedule
#'
#' Retrieves the release schedule for credit operations linked to a PVL
#' request. The `id_pleito` can be obtained from [get_pvl()].
#'
#' `get_credit_release_schedule()` is an English alias.
#'
#' @param id_pleito Integer. Database ID from [get_pvl()]. **Required**.
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
#' @return A [tibble][tibble::tibble] with release schedule data.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' pvl_pe <- get_pvl(uf = "PE")
#' sched <- get_opc_cronograma_liberacoes(id_pleito = pvl_pe$id_pleito[1])
#' }
get_opc_cronograma_liberacoes <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/opc-cronograma-liberacoes", params,
                    use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_opc_cronograma_liberacoes
#' @param request_id Integer. Database ID of the PVL request. Obtain
#'   from the `id_pleito` column of [get_pvl()] results. **Required**.
#'   Maps to `id_pleito`.
#' @usage get_credit_release_schedule(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_credit_release_schedule <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_opc_cronograma_liberacoes(id_pleito = request_id,
                                use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_opc_cronograma_pagamentos / get_credit_payment_schedule -----

#' Get credit operation payment schedule
#'
#' Retrieves the payment schedule for credit operations linked to a PVL
#' request. The `id_pleito` can be obtained from [get_pvl()].
#'
#' `get_credit_payment_schedule()` is an English alias.
#'
#' @param id_pleito Integer. Database ID from [get_pvl()]. **Required**.
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
#' @return A [tibble][tibble::tibble] with payment schedule data.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' pvl_pe <- get_pvl(uf = "PE")
#' pgto <- get_opc_cronograma_pagamentos(id_pleito = pvl_pe$id_pleito[1])
#' }
get_opc_cronograma_pagamentos <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/opc-cronograma-pagamentos", params,
                    use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_opc_cronograma_pagamentos
#' @param request_id Integer. Database ID of the PVL request. Obtain
#'   from the `id_pleito` column of [get_pvl()] results. **Required**.
#'   Maps to `id_pleito`.
#' @usage get_credit_payment_schedule(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_credit_payment_schedule <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_opc_cronograma_pagamentos(id_pleito = request_id,
                                use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_opc_taxa_cambio / get_credit_exchange_rate ---------------------------

#' Get credit operation exchange rate data
#'
#' Retrieves exchange rate data for credit operations linked to a PVL
#' request. The `id_pleito` can be obtained from [get_pvl()].
#'
#' `get_credit_exchange_rate()` is an English alias.
#'
#' @param id_pleito Integer. Database ID from [get_pvl()]. **Required**.
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
#' @return A [tibble][tibble::tibble] with exchange rate data.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' cambio <- get_opc_taxa_cambio(id_pleito = 40353)
#' }
get_opc_taxa_cambio <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/opc-taxa-cambio", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_opc_taxa_cambio
#' @param request_id Integer. Database ID of the PVL request. Obtain
#'   from the `id_pleito` column of [get_pvl()] results. **Required**.
#'   Maps to `id_pleito`.
#' @usage get_credit_exchange_rate(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_credit_exchange_rate <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_opc_taxa_cambio(id_pleito = request_id, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_res_cdp / get_debt_capacity ------------------------------------------

#' Get debt capacity result (CDP)
#'
#' Retrieves the Debt Capacity Result (Resultado da Capacidade de
#' Pagamento) linked to a PVL request. The `id_pleito` can be obtained
#' from [get_pvl()].
#'
#' `get_debt_capacity()` is an English alias.
#'
#' @param id_pleito Integer. Database ID from [get_pvl()]. **Required**.
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
#' @return A [tibble][tibble::tibble] with CDP result data.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' cdp <- get_res_cdp(id_pleito = 40353)
#' }
get_res_cdp <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/res-cdp", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_res_cdp
#' @param request_id Integer. Database ID of the PVL request. Obtain
#'   from the `id_pleito` column of [get_pvl()] results. **Required**.
#'   Maps to `id_pleito`.
#' @usage get_debt_capacity(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_debt_capacity <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_res_cdp(id_pleito = request_id, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

# -- get_res_cronograma_pagamentos / get_debt_payment_schedule ----------------

#' Get debt payment schedule result
#'
#' Retrieves the payment schedule result linked to a PVL request. The
#' `id_pleito` can be obtained from [get_pvl()].
#'
#' `get_debt_payment_schedule()` is an English alias.
#'
#' @param id_pleito Integer. Database ID from [get_pvl()]. **Required**.
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
#' @return A [tibble][tibble::tibble] with payment schedule result data.
#'
#' @family SADIPEM
#' @export
#' @examples
#' \dontrun{
#' pgto_res <- get_res_cronograma_pagamentos(id_pleito = 40353)
#' }
get_res_cronograma_pagamentos <- function(id_pleito, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(id_pleito)
  params <- list(id_pleito = id_pleito)
  sadipem_fetch_all("/res-cronograma-pagamentos", params,
                    use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_res_cronograma_pagamentos
#' @param request_id Integer. Database ID of the PVL request. Obtain
#'   from the `id_pleito` column of [get_pvl()] results. **Required**.
#'   Maps to `id_pleito`.
#' @usage get_debt_payment_schedule(request_id, use_cache = TRUE, verbose = FALSE,
#'   page_size = NULL, max_rows = Inf)
#' @export
get_debt_payment_schedule <- function(request_id, use_cache = TRUE, verbose = FALSE, page_size = NULL, max_rows = Inf) {
  check_required(request_id)
  get_res_cronograma_pagamentos(id_pleito = request_id,
                                use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}
