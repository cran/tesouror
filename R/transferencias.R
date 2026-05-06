# ============================================================================
# Transferencias Constitucionais API Functions
# Docs: https://apiapex.tesouro.gov.br/aria/v1/transferencias_constitucionais/docs
# Base URL: https://apiapex.tesouro.gov.br/aria/v1/transferencias_constitucionais/custom
#
# IMPORTANT: All filter parameters in this API use NUMERIC CODES from the
# Treasury's internal systems. These are NOT IBGE codes. Use the dictionary
# functions to look up codes:
#   - get_tc_transferencias() -> transfer type codes
#   - get_tc_estados()        -> state codes
#   - get_tc_municipios()     -> municipality codes
#
# Multi-value parameters accept either a colon-separated string ("1:2:3")
# or an R vector (c(1, 2, 3)).
# ============================================================================

# -- get_tc_transferencias / get_tc_transfer_types ----------------------------

#' Get transfer type dictionary
#'
#' Retrieves the dictionary of constitutional transfer types and their
#' numeric codes. Use these codes in the `p_transferencia` /
#' `transfer_type` parameter of other functions.
#'
#' These are **internal Treasury codes**, not IBGE codes.
#'
#' `get_tc_transfer_types()` is an English alias.
#'
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with columns `codigo` (code) and
#'   `nome` (name) of each transfer type.
#'
#' @family Transferencias
#' @family Transferencias dictionaries
#' @export
#' @examples
#' \dontrun{
#' tipos <- get_tc_transferencias()
#' # Use tipos$codigo as values for p_transferencia in other functions
#' }
get_tc_transferencias <- function(use_cache = TRUE, verbose = FALSE) {
  transferencias_fetch("/transferencias", use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_transferencias
#' @usage get_tc_transfer_types(use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_transfer_types <- function(use_cache = TRUE, verbose = FALSE) {
  get_tc_transferencias(use_cache = use_cache, verbose = verbose)
}

# -- get_tc_estados / get_tc_states -------------------------------------------

#' Get state dictionary
#'
#' Retrieves the dictionary of states and their numeric codes. Use these
#' codes in the `p_estado` / `state_code` parameter of other functions.
#'
#' These are **internal Treasury codes**, not IBGE codes.
#'
#' `get_tc_states()` is an English alias.
#'
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with columns `codigo` (numeric code)
#'   and `nome` (name) of each state.
#'
#' @family Transferencias
#' @family Transferencias dictionaries
#' @export
#' @examples
#' \dontrun{
#' estados <- get_tc_estados()
#' # Use estados$codigo as values for p_estado in other functions
#' }
get_tc_estados <- function(use_cache = TRUE, verbose = FALSE) {
  transferencias_fetch("/estados", use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_estados
#' @usage get_tc_states(use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_states <- function(use_cache = TRUE, verbose = FALSE) {
  get_tc_estados(use_cache = use_cache, verbose = verbose)
}

# -- get_tc_municipios / get_tc_municipalities --------------------------------

#' Get municipality dictionary
#'
#' Retrieves the dictionary of municipalities and their numeric codes.
#' Use these codes in the `p_municipio` / `municipality` parameter of
#' other functions.
#'
#' These are **internal Treasury codes**, not IBGE codes.
#' Filter by state using the numeric code from [get_tc_estados()].
#'
#' `get_tc_municipalities()` is an English alias.
#'
#' @param p_nome Character. Partial municipality name for searching (e.g.,
#'   `"Recife"`). Optional.
#' @param p_uf Numeric or character. State code from [get_tc_estados()].
#'   **Not** a state abbreviation or IBGE code. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with municipality data including
#'   `codigo`, `codigo_uf`, and `nome`.
#'
#' @family Transferencias
#' @family Transferencias dictionaries
#' @export
#' @examples
#' \dontrun{
#' # Step 1: find the state code (Treasury code, NOT IBGE)
#' estados <- get_tc_estados()
#' pe_code <- estados$codigo[estados$nome == "Pernambuco"]
#'
#' # Step 2: list municipalities for that state
#' municipios <- get_tc_municipios(p_uf = pe_code)
#'
#' # Or search by partial name
#' recife <- get_tc_municipios(p_nome = "Recife")
#' }
get_tc_municipios <- function(p_nome = NULL, p_uf = NULL, use_cache = TRUE, verbose = FALSE) {
  .check_not_uf_abbrev(p_uf, "p_uf")
  params <- list(p_nome = p_nome, p_uf = p_uf)
  transferencias_fetch("/municipios", params, use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_municipios
#' @param name Character. Partial municipality name for searching (e.g.,
#'   `"Recife"`). Optional. Maps to `p_nome`.
#' @param state_code Numeric or character. State code from
#'   [get_tc_estados()]. **Not** a state abbreviation or IBGE code.
#'   Optional. Maps to `p_uf`.
#' @usage get_tc_municipalities(name = NULL, state_code = NULL,
#'   use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_municipalities <- function(name = NULL, state_code = NULL,
                                  use_cache = TRUE, verbose = FALSE) {
  get_tc_municipios(p_nome = name, p_uf = state_code, use_cache = use_cache, verbose = verbose)
}

# -- get_tc_por_estados / get_tc_by_state ------------------------------------

#' Get constitutional transfers by state
#'
#' Retrieves constitutional transfer data aggregated by state.
#'
#' All codes are **internal Treasury codes** (not IBGE). Use the dictionary
#' functions to look them up: [get_tc_estados()] for state codes and
#' [get_tc_transferencias()] for transfer type codes.
#'
#' Multi-value parameters accept either a colon-separated string
#' (`"1:2:3"`) or an R vector (`c(1, 2, 3)`).
#'
#' `get_tc_by_state()` is an English alias.
#'
#' @param p_estado State code(s) from [get_tc_estados()]. Accepts a vector
#'   or a colon-separated string. Optional.
#' @param p_ano Year(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_mes Month(s) (1-12). Accepts a vector or colon-separated
#'   string. Optional.
#' @param p_transferencia Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_sn_detalhar Character. Set to any value to include detailed
#'   breakdown. Omit for summary. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with transfer data by state.
#'
#' @family Transferencias
#' @export
#' @examples
#' \dontrun{
#' # Step 1: look up codes (Treasury codes, NOT IBGE)
#' estados <- get_tc_estados()
#' tipos   <- get_tc_transferencias()
#'
#' pe_code <- estados$codigo[estados$nome == "Pernambuco"]
#'
#' # Step 2: query (pass a vector or colon-separated string)
#' tc_pe <- get_tc_por_estados(p_estado = pe_code, p_ano = 2023)
#' tc_multi <- get_tc_por_estados(
#'   p_estado = c(1, 2), p_ano = 2023, p_mes = c(1, 2)
#' )
#' }
get_tc_por_estados <- function(p_estado = NULL, p_ano = NULL, p_mes = NULL,
                               p_transferencia = NULL,
                               p_sn_detalhar = NULL,
                               use_cache = TRUE, verbose = FALSE) {
  .check_not_uf_abbrev(p_estado, "p_estado")
  params <- list(
    p_estado        = collapse_param(p_estado),
    p_ano           = collapse_param(p_ano),
    p_mes           = collapse_param(p_mes),
    p_transferencia = collapse_param(p_transferencia),
    p_sn_detalhar   = p_sn_detalhar
  )
  transferencias_fetch("/por_estados", params, use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_por_estados
#' @param state_code State code(s) from [get_tc_estados()]. Accepts a
#'   vector (e.g., `c(1, 2)`) or colon-separated string (`"1:2"`).
#'   These are **Treasury codes**, not IBGE codes. Optional. Maps to
#'   `p_estado`.
#' @param year Year(s). Accepts a vector or colon-separated string.
#'   Optional. Maps to `p_ano`.
#' @param month Month(s) (1-12). Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_mes`.
#' @param transfer_type Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_transferencia`.
#' @param detailed Character. Set to any value to include a detailed
#'   breakdown. Omit for summary. Optional. Maps to `p_sn_detalhar`.
#' @usage get_tc_by_state(state_code = NULL, year = NULL, month = NULL,
#'   transfer_type = NULL, detailed = NULL, use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_by_state <- function(state_code = NULL, year = NULL, month = NULL,
                            transfer_type = NULL, detailed = NULL,
                            use_cache = TRUE, verbose = FALSE) {
  get_tc_por_estados(
    p_estado = state_code, p_ano = year, p_mes = month,
    p_transferencia = transfer_type, p_sn_detalhar = detailed,
    use_cache = use_cache,
    verbose = verbose
  )
}

# -- get_tc_por_estados_detalhe / get_tc_by_state_detail ---------------------

#' Get detailed constitutional transfers by state
#'
#' Retrieves detailed constitutional transfer data by state, with full
#' breakdown of each transfer.
#'
#' All codes are **internal Treasury codes** (not IBGE). See
#' [get_tc_estados()] and [get_tc_transferencias()] for dictionaries.
#'
#' `get_tc_by_state_detail()` is an English alias.
#'
#' @param p_estado State code(s) from [get_tc_estados()]. Accepts a vector
#'   or colon-separated string. Optional.
#' @param p_ano Year(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_mes Month(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_transferencia Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated string.
#'   Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with detailed transfer data by state.
#'
#' @family Transferencias
#' @export
#' @examples
#' \dontrun{
#' estados <- get_tc_estados()
#' pe_code <- estados$codigo[estados$nome == "Pernambuco"]
#' detalhe <- get_tc_por_estados_detalhe(p_estado = pe_code, p_ano = 2023)
#' }
get_tc_por_estados_detalhe <- function(p_estado = NULL, p_ano = NULL,
                                       p_mes = NULL,
                                       p_transferencia = NULL,
                                       use_cache = TRUE, verbose = FALSE) {
  .check_not_uf_abbrev(p_estado, "p_estado")
  params <- list(
    p_estado        = collapse_param(p_estado),
    p_ano           = collapse_param(p_ano),
    p_mes           = collapse_param(p_mes),
    p_transferencia = collapse_param(p_transferencia)
  )
  transferencias_fetch("/por_estados_detalhe", params,
                       use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_por_estados_detalhe
#' @param state_code State code(s) from [get_tc_estados()]. Accepts a
#'   vector or colon-separated string. **Treasury codes**, not IBGE.
#'   Optional. Maps to `p_estado`.
#' @param year Year(s). Accepts a vector or colon-separated string.
#'   Optional. Maps to `p_ano`.
#' @param month Month(s) (1-12). Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_mes`.
#' @param transfer_type Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_transferencia`.
#' @usage get_tc_by_state_detail(state_code = NULL, year = NULL,
#'   month = NULL, transfer_type = NULL, use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_by_state_detail <- function(state_code = NULL, year = NULL,
                                   month = NULL, transfer_type = NULL,
                                   use_cache = TRUE, verbose = FALSE) {
  get_tc_por_estados_detalhe(
    p_estado = state_code, p_ano = year, p_mes = month,
    p_transferencia = transfer_type, use_cache = use_cache,
    verbose = verbose
  )
}

# -- get_tc_por_municipio / get_tc_by_municipality ---------------------------

#' Get constitutional transfers by municipality
#'
#' Retrieves constitutional transfer data for municipalities within states.
#'
#' All codes are **internal Treasury codes** (not IBGE). Use the dictionary
#' functions to look them up: [get_tc_estados()] for state codes,
#' [get_tc_municipios()] for municipality codes, and
#' [get_tc_transferencias()] for transfer type codes.
#'
#' Multi-value parameters accept either a colon-separated string
#' (`"1:2:3"`) or an R vector (`c(1, 2, 3)`).
#'
#' `get_tc_by_municipality()` is an English alias.
#'
#' @param p_estado State code(s) from [get_tc_estados()]. Accepts a vector
#'   or colon-separated string. Optional.
#' @param p_municipio Municipality code(s) from [get_tc_municipios()].
#'   Accepts a vector or colon-separated string. Optional.
#' @param p_ano Year(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_mes Month(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_transferencia Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_sn_detalhar Character. Set to any value to include detailed
#'   breakdown. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with transfer data by municipality.
#'
#' @family Transferencias
#' @export
#' @examples
#' \dontrun{
#' # Step 1: look up codes (Treasury codes, NOT IBGE)
#' estados <- get_tc_estados()
#' pe_code <- estados$codigo[estados$nome == "Pernambuco"]
#' municipios <- get_tc_municipios(p_uf = pe_code)
#' recife_code <- municipios$codigo[municipios$nome == "Recife"]
#'
#' # Step 2: query (pass vector or string)
#' tc <- get_tc_por_municipio(
#'   p_estado = pe_code,
#'   p_municipio = recife_code,
#'   p_ano = 2023
#' )
#' }
get_tc_por_municipio <- function(p_estado = NULL, p_municipio = NULL,
                                 p_ano = NULL, p_mes = NULL,
                                 p_transferencia = NULL,
                                 p_sn_detalhar = NULL,
                                 use_cache = TRUE, verbose = FALSE) {
  .check_not_uf_abbrev(p_estado, "p_estado")
  params <- list(
    P_ESTADO        = collapse_param(p_estado),
    P_MUNICIPIOS    = collapse_param(p_municipio),
    P_ANO           = collapse_param(p_ano),
    P_MES           = collapse_param(p_mes),
    P_TRANSFERENCIA = collapse_param(p_transferencia),
    P_SN_DETALHAR   = p_sn_detalhar
  )
  transferencias_fetch("/por_estado_municipio", params,
                       use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_por_municipio
#' @param state_code State code(s) from [get_tc_estados()]. Accepts a
#'   vector or colon-separated string. **Treasury codes**, not IBGE.
#'   Optional. Maps to `p_estado`.
#' @param municipality Municipality code(s) from [get_tc_municipios()].
#'   Accepts a vector or colon-separated string. **Treasury codes**.
#'   Optional. Maps to `p_municipio`.
#' @param year Year(s). Accepts a vector or colon-separated string.
#'   Optional. Maps to `p_ano`.
#' @param month Month(s) (1-12). Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_mes`.
#' @param transfer_type Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_transferencia`.
#' @param detailed Character. Set to any value to include detail.
#'   Optional. Maps to `p_sn_detalhar`.
#' @usage get_tc_by_municipality(state_code = NULL, municipality = NULL,
#'   year = NULL, month = NULL, transfer_type = NULL, detailed = NULL,
#'   use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_by_municipality <- function(state_code = NULL, municipality = NULL,
                                   year = NULL, month = NULL,
                                   transfer_type = NULL,
                                   detailed = NULL, use_cache = TRUE, verbose = FALSE) {
  get_tc_por_municipio(
    p_estado = state_code, p_municipio = municipality,
    p_ano = year, p_mes = month,
    p_transferencia = transfer_type, p_sn_detalhar = detailed,
    use_cache = use_cache,
    verbose = verbose
  )
}

# -- get_tc_por_municipio_detalhe / get_tc_by_municipality_detail ------------

#' Get detailed constitutional transfers by municipality
#'
#' Retrieves detailed constitutional transfer data by municipality.
#'
#' All codes are **internal Treasury codes** (not IBGE). See
#' [get_tc_estados()], [get_tc_municipios()], and
#' [get_tc_transferencias()] for dictionaries.
#'
#' `get_tc_by_municipality_detail()` is an English alias.
#'
#' @param p_estado State code(s) from [get_tc_estados()]. Accepts a vector
#'   or colon-separated string. Optional.
#' @param p_municipio Municipality code(s) from [get_tc_municipios()].
#'   Accepts a vector or colon-separated string. Optional.
#' @param p_ano Year(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_mes Month(s). Accepts a vector or colon-separated string.
#'   Optional.
#' @param p_transferencia Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated string.
#'   Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#'
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Useful for debugging or testing in a browser. Defaults to
#'   `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with detailed municipality transfer
#'   data.
#'
#' @family Transferencias
#' @export
#' @examples
#' \dontrun{
#' estados <- get_tc_estados()
#' pe_code <- estados$codigo[estados$nome == "Pernambuco"]
#' det <- get_tc_por_municipio_detalhe(p_estado = pe_code, p_ano = 2023)
#' }
get_tc_por_municipio_detalhe <- function(p_estado = NULL,
                                         p_municipio = NULL,
                                         p_ano = NULL, p_mes = NULL,
                                         p_transferencia = NULL,
                                         use_cache = TRUE, verbose = FALSE) {
  .check_not_uf_abbrev(p_estado, "p_estado")
  params <- list(
    P_ESTADO        = collapse_param(p_estado),
    P_MUNICIPIOS    = collapse_param(p_municipio),
    P_ANO           = collapse_param(p_ano),
    P_MES           = collapse_param(p_mes),
    P_TRANSFERENCIA = collapse_param(p_transferencia)
  )
  transferencias_fetch("/por_estado_municipio_detalhe", params,
                       use_cache = use_cache, verbose = verbose)
}

#' @rdname get_tc_por_municipio_detalhe
#' @param state_code State code(s) from [get_tc_estados()]. Accepts a
#'   vector or colon-separated string. **Treasury codes**, not IBGE.
#'   Optional. Maps to `p_estado`.
#' @param municipality Municipality code(s) from [get_tc_municipios()].
#'   Accepts a vector or colon-separated string. **Treasury codes**.
#'   Optional. Maps to `p_municipio`.
#' @param year Year(s). Accepts a vector or colon-separated string.
#'   Optional. Maps to `p_ano`.
#' @param month Month(s) (1-12). Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_mes`.
#' @param transfer_type Transfer type code(s) from
#'   [get_tc_transferencias()]. Accepts a vector or colon-separated
#'   string. Optional. Maps to `p_transferencia`.
#' @usage get_tc_by_municipality_detail(state_code = NULL,
#'   municipality = NULL, year = NULL, month = NULL,
#'   transfer_type = NULL, use_cache = TRUE, verbose = FALSE)
#' @export
get_tc_by_municipality_detail <- function(state_code = NULL,
                                          municipality = NULL,
                                          year = NULL, month = NULL,
                                          transfer_type = NULL,
                                          use_cache = TRUE, verbose = FALSE) {
  get_tc_por_municipio_detalhe(
    p_estado = state_code, p_municipio = municipality,
    p_ano = year, p_mes = month,
    p_transferencia = transfer_type, use_cache = use_cache,
    verbose = verbose
  )
}
