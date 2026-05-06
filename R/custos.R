# ============================================================================
# CUSTOS API Functions (Federal Government Cost Data)
# API docs: https://apidatalake.tesouro.gov.br/docs/custos/
# Base URL: https://apidatalake.tesouro.gov.br/ords/custos/tt
#
# PERFORMANCE WARNING: The CUSTOS API is slow (server default = 250
# rows/page, frequent HTTP 504 timeouts). Unfiltered queries return
# hundreds of thousands of rows. Always filter by:
#   - organizacao_n1 + organizacao_n2 (narrow to a specific org)
#   - ano + mes (narrow the time range)
#   - natureza_juridica (narrow the entity type)
#   - max_rows (hard cap for testing)
#
# SIORG codes are auto-padded: pass 244 or "244", both become "000244".
# Use get_siorg_orgaos() / get_siorg_estrutura() to look up codes.
# ============================================================================

# -- Helper for shared CUSTOS parameters --------------------------------------

#' Pad a SIORG code to 6 digits with leading zeros
#'
#' The CUSTOS API expects organization codes as zero-padded 6-digit
#' strings (e.g., `"000244"`), but SIORG returns them as plain numbers
#' (e.g., `"244"` or `244`). This helper pads automatically so users
#' can pass either format.
#'
#' @param code A scalar code (character, numeric, or NULL).
#' @return A zero-padded 6-character string, or NULL.
#' @noRd
pad_siorg_code <- function(code) {
  if (is.null(code)) return(NULL)
  sprintf("%06d", as.integer(code))
}

#' Build CUSTOS params list (with auto-padding of org codes)
#' @noRd
custos_params <- function(ano = NULL, mes = NULL, natureza_juridica = NULL,
                          organizacao_n1 = NULL, organizacao_n2 = NULL,
                          organizacao_n3 = NULL) {
  list(
    ano              = ano,
    mes              = mes,
    natureza_juridica = natureza_juridica,
    organizacao_n1   = pad_siorg_code(organizacao_n1),
    organizacao_n2   = pad_siorg_code(organizacao_n2),
    organizacao_n3   = pad_siorg_code(organizacao_n3)
  )
}

# -- get_custos_pessoal_ativo / get_costs_active_staff ------------------------

#' Get active staff cost data
#'
#' Retrieves cost data for active federal government staff. All parameters
#' are optional filters.
#'
#' **Performance**: The CUSTOS API is slow and unfiltered queries return
#' hundreds of thousands of rows. Always filter by organization level
#' (`organizacao_n1` + `organizacao_n2`) and/or `mes` to get manageable
#' results. Use `max_rows` for quick tests.
#'
#' `get_costs_active_staff()` is an English alias.
#'
#' @param ano Integer. Year of the record. Optional.
#' @param mes Integer. Month of the record (1-12). Optional.
#' @param natureza_juridica Integer. Legal nature of the organization:
#'   `1` (Public Company), `2` (Public Foundation), `3` (Direct
#'   Administration), `4` (Autarchy), `6` (Mixed Economy Company). Optional.
#' @param organizacao_n1 Character or integer. SIORG code for the top-level
#'   organization (Ministry level). Use [get_siorg_orgaos()] to look up
#'   codes. You can pass plain codes (e.g., `244`) — they are
#'   automatically zero-padded to the 6-digit format the API expects
#'   (`"000244"`). Optional.
#' @param organizacao_n2 Character or integer. SIORG code for the
#'   second-level organization. Use [get_siorg_estrutura()] to browse
#'   sub-units. Automatically zero-padded. Optional.
#' @param organizacao_n3 Character or integer. SIORG code for the
#'   third-level organization. Use [get_siorg_estrutura()] to browse
#'   sub-units. Automatically zero-padded. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `FALSE`.
#' @param page_size Integer. Number of rows per API page. Defaults to
#'   `500`. The CUSTOS backend is slow on broad queries: smaller pages
#'   are more robust against HTTP 504 timeouts at the cost of a few
#'   extra round-trips. The server default of 250 is conservative;
#'   1000+ may time out. If the package returns
#'   `attr(result, "partial") = TRUE`, lower this further or add a
#'   `mes` filter.
#' @param max_rows Numeric. Maximum number of rows to return. Defaults
#'   to `Inf` (all rows). Useful for quick tests with large datasets
#'   (e.g., `max_rows = 100`).
#'
#' @return A [tibble][tibble::tibble] with active staff cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' # WARNING: unfiltered queries return hundreds of thousands of rows
#' # and are very slow. Always filter by organization level and/or
#' # natureza_juridica + mes.
#'
#' # Quick test: limit rows
#' ativos <- get_custos_pessoal_ativo(ano = 2023, mes = 6, max_rows = 100)
#'
#' # Filter by ministry (N1) + entity (N2) for manageable results
#' # Use get_siorg_orgaos() to find SIORG codes
#' ativos_inep <- get_custos_pessoal_ativo(
#'   ano = 2023,
#'   organizacao_n1 = 244,  # MEC (auto-padded to "000244")
#'   organizacao_n2 = 249   # INEP (auto-padded to "000249")
#' )
#' }
get_custos_pessoal_ativo <- function(ano = NULL, mes = NULL,
                                     natureza_juridica = NULL,
                                     organizacao_n1 = NULL,
                                     organizacao_n2 = NULL,
                                     organizacao_n3 = NULL,
                                     use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/pessoal_ativo", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_pessoal_ativo
#' @param year Integer. Year of the record. Optional. Maps to `ano`.
#' @param month Integer. Month of the record (1-12). Optional. Maps to
#'   `mes`.
#' @param legal_nature Integer. Legal nature of the organization:
#'   `1` (Public Company), `2` (Public Foundation), `3` (Direct
#'   Administration), `4` (Autarchy), `6` (Mixed Economy Company).
#'   Optional. Maps to `natureza_juridica`.
#' @param org_level1 Character or integer. SIORG code for the top-level
#'   organization (Ministry level). Use [get_siorg_organizations()] to
#'   look up codes. Plain codes (e.g., `244`) are auto-padded to
#'   `"000244"`. Optional. Maps to `organizacao_n1`.
#' @param org_level2 Character or integer. SIORG code (second level).
#'   Use [get_siorg_structure()] to browse sub-units. Auto-padded.
#'   Optional. Maps to `organizacao_n2`.
#' @param org_level3 Character or integer. SIORG code (third level).
#'   Use [get_siorg_structure()] to browse sub-units. Auto-padded.
#'   Optional. Maps to `organizacao_n3`.
#' @usage get_costs_active_staff(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_active_staff <- function(year = NULL, month = NULL,
                                   legal_nature = NULL,
                                   org_level1 = NULL, org_level2 = NULL,
                                   org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_pessoal_ativo(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}

# -- get_custos_pessoal_inativo / get_costs_retired_staff ---------------------

#' Get retired staff cost data
#'
#' Retrieves cost data for retired (inactive) federal government staff.
#' All parameters are optional filters.
#'
#' `get_costs_retired_staff()` is an English alias.
#'
#' @inheritParams get_custos_pessoal_ativo
#'
#'
#' @return A [tibble][tibble::tibble] with retired staff cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' # Always filter to avoid slow, large queries
#' inativos <- get_custos_pessoal_inativo(
#'   ano = 2023, mes = 6,
#'   organizacao_n1 = 244,  # MEC
#'   organizacao_n2 = 249   # INEP
#' )
#' }
get_custos_pessoal_inativo <- function(ano = NULL, mes = NULL,
                                       natureza_juridica = NULL,
                                       organizacao_n1 = NULL,
                                       organizacao_n2 = NULL,
                                       organizacao_n3 = NULL,
                                       use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/pessoal_inativo", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_pessoal_inativo
#' @inheritParams get_costs_active_staff
#' @usage get_costs_retired_staff(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_retired_staff <- function(year = NULL, month = NULL,
                                    legal_nature = NULL,
                                    org_level1 = NULL, org_level2 = NULL,
                                    org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_pessoal_inativo(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}

# -- get_custos_pensionistas / get_costs_pensioners ---------------------------

#' Get pensioner cost data
#'
#' Retrieves cost data for federal government pensioners.
#' All parameters are optional filters.
#'
#' `get_costs_pensioners()` is an English alias.
#'
#' @inheritParams get_custos_pessoal_ativo
#'
#'
#' @return A [tibble][tibble::tibble] with pensioner cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' pensionistas <- get_custos_pensionistas(
#'   ano = 2023, mes = 12,
#'   organizacao_n1 = 244,  # MEC
#'   organizacao_n2 = 249   # INEP
#' )
#' }
get_custos_pensionistas <- function(ano = NULL, mes = NULL,
                                    natureza_juridica = NULL,
                                    organizacao_n1 = NULL,
                                    organizacao_n2 = NULL,
                                    organizacao_n3 = NULL,
                                    use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/pensionistas", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_pensionistas
#' @inheritParams get_costs_active_staff
#' @usage get_costs_pensioners(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_pensioners <- function(year = NULL, month = NULL,
                                 legal_nature = NULL,
                                 org_level1 = NULL, org_level2 = NULL,
                                 org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_pensionistas(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}

# -- get_custos_demais / get_costs_other --------------------------------------

#' Get other cost data
#'
#' Retrieves other (non-personnel) cost data for federal government
#' organizations. All parameters are optional filters.
#'
#' `get_costs_other()` is an English alias.
#'
#' @inheritParams get_custos_pessoal_ativo
#'
#'
#' @return A [tibble][tibble::tibble] with other cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' demais <- get_custos_demais(
#'   ano = 2023, mes = 6,
#'   organizacao_n1 = 244,  # MEC
#'   organizacao_n2 = 249   # INEP
#' )
#' }
get_custos_demais <- function(ano = NULL, mes = NULL,
                               natureza_juridica = NULL,
                               organizacao_n1 = NULL,
                               organizacao_n2 = NULL,
                               organizacao_n3 = NULL,
                               use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/demais", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_demais
#' @inheritParams get_costs_active_staff
#' @usage get_costs_other(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_other <- function(year = NULL, month = NULL,
                            legal_nature = NULL,
                            org_level1 = NULL, org_level2 = NULL,
                            org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_demais(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}

# -- get_custos_depreciacao / get_costs_depreciation --------------------------

#' Get depreciation cost data
#'
#' Retrieves depreciation cost data for federal government organizations.
#' All parameters are optional filters.
#'
#' `get_costs_depreciation()` is an English alias.
#'
#' @inheritParams get_custos_pessoal_ativo
#'
#'
#' @return A [tibble][tibble::tibble] with depreciation cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' deprec <- get_custos_depreciacao(
#'   ano = 2023, mes = 6,
#'   organizacao_n1 = 244,  # MEC
#'   organizacao_n2 = 249   # INEP
#' )
#' }
get_custos_depreciacao <- function(ano = NULL, mes = NULL,
                                   natureza_juridica = NULL,
                                   organizacao_n1 = NULL,
                                   organizacao_n2 = NULL,
                                   organizacao_n3 = NULL,
                                   use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/depreciacao", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_depreciacao
#' @inheritParams get_costs_active_staff
#' @usage get_costs_depreciation(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_depreciation <- function(year = NULL, month = NULL,
                                   legal_nature = NULL,
                                   org_level1 = NULL, org_level2 = NULL,
                                   org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_depreciacao(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}

# -- get_custos_transferencias / get_costs_transfers --------------------------

#' Get transfer cost data
#'
#' Retrieves transfer cost data for federal government organizations.
#' All parameters are optional filters.
#'
#' `get_costs_transfers()` is an English alias.
#'
#' @inheritParams get_custos_pessoal_ativo
#'
#'
#' @return A [tibble][tibble::tibble] with transfer cost data.
#'
#' @family CUSTOS
#' @export
#' @examples
#' \dontrun{
#' transf <- get_custos_transferencias(
#'   ano = 2023, mes = 6,
#'   organizacao_n1 = 244,  # MEC
#'   organizacao_n2 = 249   # INEP
#' )
#' }
get_custos_transferencias <- function(ano = NULL, mes = NULL,
                                      natureza_juridica = NULL,
                                      organizacao_n1 = NULL,
                                      organizacao_n2 = NULL,
                                      organizacao_n3 = NULL,
                                      use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  params <- custos_params(ano, mes, natureza_juridica,
                          organizacao_n1, organizacao_n2, organizacao_n3)
  custos_fetch_all("/transferencias", params, use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows)
}

#' @rdname get_custos_transferencias
#' @inheritParams get_costs_active_staff
#' @usage get_costs_transfers(year = NULL, month = NULL,
#'   legal_nature = NULL, org_level1 = NULL, org_level2 = NULL,
#'   org_level3 = NULL, use_cache = TRUE, verbose = FALSE,
#'   page_size = 500, max_rows = Inf)
#' @export
get_costs_transfers <- function(year = NULL, month = NULL,
                                legal_nature = NULL,
                                org_level1 = NULL, org_level2 = NULL,
                                org_level3 = NULL, use_cache = TRUE, verbose = FALSE, page_size = 500L, max_rows = Inf) {
  get_custos_transferencias(
    ano = year, mes = month, natureza_juridica = legal_nature,
    organizacao_n1 = org_level1, organizacao_n2 = org_level2,
    organizacao_n3 = org_level3, use_cache = use_cache,
    verbose = verbose, page_size = page_size,
    max_rows  = max_rows
  )
}
