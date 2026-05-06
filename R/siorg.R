# ============================================================================
# SIORG API Functions (Organizational Structure)
# API docs: https://api.siorg.economia.gov.br/
# Base URL: https://estruturaorganizacional.dados.gov.br
#
# The SIORG API provides the organizational structure of the Brazilian
# Federal Executive Branch. SIORG codes are used as the organizacao_n1,
# organizacao_n2, and organizacao_n3 parameters in the CUSTOS API.
#
# This API returns URIs as identifiers (e.g.,
# "https://estruturaorganizacional.dados.gov.br/id/unidade-organizacional/46").
# We extract the numeric code from the URI tail for ease of use.
# ============================================================================

# -- Internal helpers ---------------------------------------------------------

#' Base URL for the SIORG API
#' @noRd
siorg_base_url <- function() {
  "https://estruturaorganizacional.dados.gov.br"
}

#' Extract numeric code from a SIORG URI
#'
#' SIORG returns identifiers as URIs like
#' `"https://.../id/unidade-organizacional/46"`.
#' This function extracts the trailing numeric or textual code.
#'
#' @param uri Character vector of URIs.
#' @return Character vector of extracted codes.
#' @noRd
extract_siorg_code <- function(uri) {
  ifelse(
    is.na(uri) | is.null(uri),
    NA_character_,
    sub(".*/", "", uri)
  )
}

#' Fetch data from the SIORG API
#'
#' @param path Character. API path (without base URL). The `.json` suffix
#'   is appended automatically.
#' @param params Named list of query parameters.
#' @param use_cache Logical.
#' @param verbose Logical.
#'
#' @return A list (parsed JSON body).
#' @noRd
siorg_fetch <- function(path, params = list(), use_cache = TRUE,
                        verbose = FALSE) {
  url <- paste0(siorg_base_url(), path, ".json")

  cli::cli_alert_info("Fetching {.field SIORG{path}}...")

  body <- tnr_request(url, params, use_cache = use_cache,
                      api_name = "SIORG", verbose = verbose)

  # Check for API-level errors
  servico <- body[["servico"]]
  if (!is.null(servico) && !is.null(servico[["codigoErro"]])) {
    if (servico[["codigoErro"]] != 0) {
      cli::cli_abort(c(
        "x" = "SIORG API returned error code {.val {servico$codigoErro}}.",
        "i" = "Message: {servico$mensagem}"
      ), call = NULL)
    }
  }

  body
}

#' Convert SIORG unidades response to a tidy tibble
#'
#' The API returns `unidades` as a list that `simplifyVector` turns into
#' a data.frame with URI columns. This function:
#' 1. Converts to tibble
#' 2. Extracts numeric codes from URI columns
#' 3. Cleans names to snake_case
#' 4. Selects useful columns only
#'
#' @param body Parsed JSON body from the API.
#' @return A tibble.
#' @noRd
parse_siorg_unidades <- function(body) {
  unidades <- body[["unidades"]]

  if (is.null(unidades) || length(unidades) == 0) {
    return(tibble::tibble())
  }

  result <- tryCatch(
    tibble::as_tibble(unidades),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to parse SIORG response into a tibble.",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  # Extract numeric codes from URI columns
  uri_cols <- c("codigoUnidade", "codigoUnidadePai", "codigoOrgaoEntidade",
                "codigoTipoUnidade", "codigoEsfera", "codigoPoder",
                "codigoNaturezaJuridica", "codigoSubNaturezaJuridica",
                "codigoCategoriaUnidade")

  for (col in uri_cols) {
    if (col %in% names(result)) {
      result[[col]] <- extract_siorg_code(result[[col]])
    }
  }

  # Clean column names to snake_case
  result <- janitor::clean_names(result)

  # Trim whitespace
  result <- tryCatch(
    dplyr::mutate(
      result,
      dplyr::across(dplyr::where(is.character), stringr::str_squish)
    ),
    error = function(e) result
  )

  result
}

# -- get_siorg_orgaos / get_siorg_organizations --------------------------------

#' Get federal organizations from SIORG
#'
#' Retrieves the list of federal government organizations (organs and
#' entities) from the SIORG system. Use the returned SIORG codes as
#' `organizacao_n1` / `org_level1` in CUSTOS API functions like
#' [get_custos_pessoal_ativo()].
#'
#' `get_siorg_organizations()` is an English alias.
#'
#' @param codigo_poder Integer. Power branch code: `1` = Executive,
#'   `2` = Legislative, `3` = Judiciary. Optional (default returns all).
#' @param codigo_esfera Integer. Government sphere: `1` = Federal,
#'   `2` = State/District, `3` = Municipal. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL being
#'   called. Defaults to `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with columns including
#'   `codigo_unidade` (SIORG code — use as `organizacao_n1` in CUSTOS),
#'   `codigo_unidade_pai` (parent code — for navigating hierarchy),
#'   `nome`, `sigla`, `codigo_tipo_unidade` (`"orgao"` or `"entidade"`),
#'   `codigo_natureza_juridica`, `codigo_esfera`, `codigo_poder`.
#'
#' @family SIORG
#' @family SIORG dictionaries
#' @export
#' @examples
#' \dontrun{
#' # List all federal executive branch organizations
#' orgaos <- get_siorg_orgaos(codigo_poder = 1, codigo_esfera = 1)
#'
#' # Find a specific ministry by name
#' mec <- orgaos[grepl("Educação", orgaos$nome), ]
#' mec_code <- mec$codigo_unidade[mec$sigla == "MEC"]
#'
#' # Use that code in CUSTOS queries (auto-padded to "000244")
#' custos <- get_custos_pessoal_ativo(
#'   ano = 2023, organizacao_n1 = mec_code
#' )
#'
#' # Browse children: units whose parent is MEC
#' mec_filhos <- orgaos[orgaos$codigo_unidade_pai == mec_code, ]
#' }
get_siorg_orgaos <- function(codigo_poder = NULL, codigo_esfera = NULL,
                             use_cache = TRUE,
                             verbose = FALSE) {
  params <- list(
    codigoPoder  = codigo_poder,
    codigoEsfera = codigo_esfera
  )

  body <- siorg_fetch("/doc/orgao-entidade/resumida", params,
                      use_cache = use_cache, verbose = verbose)

  result <- parse_siorg_unidades(body)

  if (nrow(result) == 0) {
    cli::cli_alert_warning("No organizations returned from SIORG.")
    return(tibble::tibble())
  }

  cli::cli_alert_success("Done: {.val {nrow(result)}} organizations.")
  result
}

#' @rdname get_siorg_orgaos
#' @param power_code Integer. Power branch: `1` = Executive, `2` = Legislative,
#'   `3` = Judiciary. Maps to `codigo_poder`.
#' @param sphere_code Integer. Sphere: `1` = Federal. Maps to `codigo_esfera`.
#' @usage get_siorg_organizations(power_code = NULL, sphere_code = NULL,
#'   use_cache = TRUE, verbose = FALSE)
#' @export
get_siorg_organizations <- function(power_code = NULL, sphere_code = NULL,
                                    use_cache = TRUE,
                                    verbose = FALSE) {
  get_siorg_orgaos(codigo_poder = power_code, codigo_esfera = sphere_code,
                   use_cache = use_cache, verbose = verbose)
}

# -- get_siorg_estrutura / get_siorg_structure --------------------------------

#' Get organizational structure from SIORG
#'
#' Retrieves the organizational structure tree for a specific SIORG unit,
#' returning all sub-units (departments, secretariats, etc.) as a flat
#' tibble.
#'
#' Use the returned codes as `organizacao_n2` / `org_level2` and
#' `organizacao_n3` / `org_level3` in CUSTOS API functions.
#'
#' `get_siorg_structure()` is an English alias.
#'
#' @param codigo_unidade Integer or character. SIORG code of the unit.
#'   **Required**. Use [get_siorg_orgaos()] to find codes.
#' @param vinculados Character. Return linked organs/entities?
#'   `"SIM"` or `"NAO"`. Optional.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL.
#'   Defaults to `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] with columns including
#'   `codigo_unidade`, `codigo_unidade_pai`, `nome`, `sigla`,
#'   `codigo_tipo_unidade`. Use `codigo_unidade_pai` to navigate
#'   the parent-child hierarchy.
#'
#' @family SIORG
#' @export
#' @examples
#' \dontrun{
#' # Get structure of AGU (code 46)
#' estrutura <- get_siorg_estrutura(codigo_unidade = 46)
#' }
get_siorg_estrutura <- function(codigo_unidade,
                                vinculados = NULL,
                                use_cache = TRUE,
                                verbose = FALSE) {
  check_required(codigo_unidade)

  params <- list(
    codigoUnidade = codigo_unidade,
    retornarOrgaoEntidadeVinculados = vinculados
  )

  body <- siorg_fetch("/doc/estrutura-organizacional/resumida", params,
                      use_cache = use_cache, verbose = verbose)

  result <- parse_siorg_unidades(body)

  if (nrow(result) == 0) {
    cli::cli_alert_warning(
      "No structure returned for unit {.val {codigo_unidade}}."
    )
    return(tibble::tibble())
  }

  cli::cli_alert_success("Done: {.val {nrow(result)}} units in structure.")
  result
}

#' @rdname get_siorg_estrutura
#' @param unit_code Integer or character. SIORG code. Maps to `codigo_unidade`.
#' @param include_linked Character. `"SIM"` or `"NAO"`. Maps to `vinculados`.
#' @usage get_siorg_structure(unit_code, include_linked = NULL,
#'   use_cache = TRUE, verbose = FALSE)
#' @export
get_siorg_structure <- function(unit_code, include_linked = NULL,
                                use_cache = TRUE,
                                verbose = FALSE) {
  check_required(unit_code)
  get_siorg_estrutura(codigo_unidade = unit_code, vinculados = include_linked,
                      use_cache = use_cache, verbose = verbose)
}

# -- get_siorg_unidade / get_siorg_unit ----------------------------------------

#' Get details of a single SIORG unit
#'
#' Retrieves summary data for a single organizational unit by its
#' SIORG code. Returns a single-row tibble with the unit's details.
#'
#' `get_siorg_unit()` is an English alias.
#'
#' @param codigo_unidade Integer or character. SIORG code. **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL.
#'   Defaults to `getOption("tesouror.verbose", FALSE)`.
#'
#' @return A [tibble][tibble::tibble] (single row) with unit details
#'   including `codigo_unidade`, `nome`, `sigla`, `codigo_tipo_unidade`,
#'   `codigo_unidade_pai`, `codigo_natureza_juridica`, and more.
#'
#' @family SIORG
#' @export
#' @examples
#' \dontrun{
#' # Get details for AGU (code 46)
#' agu <- get_siorg_unidade(codigo_unidade = 46)
#' }
get_siorg_unidade <- function(codigo_unidade, use_cache = TRUE,
                              verbose = FALSE) {
  check_required(codigo_unidade)

  path <- paste0("/doc/unidade-organizacional/", codigo_unidade, "/resumida")

  body <- siorg_fetch(path, use_cache = use_cache, verbose = verbose)

  # Single unit: body has "unidade" (singular), not "unidades"
  unidade <- body[["unidade"]]

  if (is.null(unidade) || length(unidade) == 0) {
    cli::cli_alert_warning(
      "No data returned for unit {.val {codigo_unidade}}."
    )
    return(tibble::tibble())
  }

  # Convert single unit list to 1-row tibble
  # Remove NULL values first
  unidade <- Filter(Negate(is.null), unidade)

  result <- tryCatch(
    tibble::as_tibble(lapply(unidade, function(x) {
      if (is.null(x)) NA_character_ else as.character(x)
    })),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to parse SIORG unit response.",
        "i" = "Original error: {conditionMessage(e)}"
      ), call = NULL)
    }
  )

  # Extract numeric codes from URI columns
  uri_cols <- c("codigoUnidade", "codigoUnidadePai", "codigoOrgaoEntidade",
                "codigoTipoUnidade", "codigoEsfera", "codigoPoder",
                "codigoNaturezaJuridica", "codigoSubNaturezaJuridica")

  for (col in uri_cols) {
    if (col %in% names(result)) {
      result[[col]] <- extract_siorg_code(result[[col]])
    }
  }

  result <- janitor::clean_names(result)

  cli::cli_alert_success("Done: retrieved unit {.val {codigo_unidade}}.")
  result
}

#' @rdname get_siorg_unidade
#' @param unit_code Integer or character. SIORG code. Maps to `codigo_unidade`.
#' @usage get_siorg_unit(unit_code, use_cache = TRUE, verbose = FALSE)
#' @export
get_siorg_unit <- function(unit_code, use_cache = TRUE,
                           verbose = FALSE) {
  check_required(unit_code)
  get_siorg_unidade(codigo_unidade = unit_code, use_cache = use_cache,
                    verbose = verbose)
}
