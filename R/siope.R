# ============================================================================
# SIOPE API Functions (Education Spending Data)
# API docs: https://www.fnde.gov.br/olinda-ide/servico/DADOS_ABERTOS_SIOPE/versao/v1/aplicacao#!/recursos
# Base URL: https://www.fnde.gov.br/olinda-ide/servico/DADOS_ABERTOS_SIOPE/versao/v1/odata
#
# SIOPE (Sistema de Informações sobre Orçamentos Públicos em Educação)
# provides education spending data from states and municipalities.
# The API is maintained by FNDE (Fundo Nacional de Desenvolvimento da
# Educação) and uses an OData-style interface.
#
# All endpoints share 3 required parameters:
#   Ano_Consulta / year  — Year (e.g., 2023)
#   Num_Peri / period    — Period: 1-6 (bimester)
#   Sig_UF / state       — State abbreviation (e.g., "PE")
#
# Exception: Remuneracao_Siope has a 4th param: Mes_Exercicio / month.
#
# PERFORMANCE: All functions support OData $filter, $orderby, and $select.
# Use filter to narrow results BEFORE download (server-side filtering):
#   filter = "NOM_MUNI eq 'Recife'"
#   filter = "COD_MUNI eq 2611606 and DS_TIPO eq 'Município'"
# This drastically reduces response size and improves speed.
# ============================================================================

# -- get_siope_dados_gerais / get_siope_general_data --------------------------

#' Get SIOPE general data
#'
#' Retrieves general data from SIOPE including demographics, GDP, revenues,
#' expenses, and declaration metadata for municipalities and states.
#'
#' **Performance tip**: use the `filter` parameter to narrow results on
#' the server before downloading. For example, filtering by municipality
#' name or IBGE code returns only the rows you need instead of all
#' municipalities in the state.
#'
#' `get_siope_general_data()` is an English alias.
#'
#' @param ano Integer. Year of the data (e.g., `2023`). **Required**.
#' @param periodo Integer. Bimester period (1-6). **Required**.
#' @param uf Character. State abbreviation (e.g., `"PE"`). **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL. Defaults to
#'   `FALSE`. Set globally with `options(tesouror.verbose = TRUE)`.
#' @param page_size Integer. Rows per page for OData pagination. Defaults
#'   to `1000`.
#' @param max_rows Numeric. Maximum rows to return. Defaults to `Inf`.
#' @param filter Character. OData `$filter` expression to narrow results
#'   **on the server** (much faster than downloading everything). Uses
#'   OData syntax (e.g., `"NOM_MUNI eq 'Recife'"`,
#'   `"COD_MUNI eq 2611606"`). Combine with `and`/`or`. Column names
#'   must use the **original API names** (uppercase), not the snake_case
#'   cleaned names. To discover valid names, run a `max_rows = 1` query
#'   and use `toupper(names(result))`. Optional.
#' @param orderby Character. OData `$orderby` expression to sort results
#'   (e.g., `"NOM_MUNI asc"`, `"NUM_POPU desc"`). Uses original API
#'   column names (uppercase). Optional.
#' @param select Character vector. Column names to return (reduces payload
#'   size). Uses original API column names (e.g.,
#'   `c("NOM_MUNI", "VAL_DECL")`). If a column name is invalid the API
#'   returns HTTP 400. Optional.
#'
#' @return A [tibble][tibble::tibble] with 52 columns including `tipo`,
#'   `num_ano`, `sig_uf`, `cod_muni`, `nom_muni`, `num_popu`, revenue and
#'   expense values, PIB data, and declaration metadata.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' # General data for all municipalities in Pernambuco
#' dados <- get_siope_dados_gerais(ano = 2023, periodo = 6, uf = "PE")
#'
#' # FAST: Filter to a single municipality (server-side)
#' recife <- get_siope_dados_gerais(
#'   ano = 2023, periodo = 6, uf = "PE",
#'   filter = "NOM_MUNI eq 'Recife'"
#' )
#'
#' # Filter + select specific columns (use original API names!)
#' resumo <- get_siope_dados_gerais(
#'   ano = 2023, periodo = 6, uf = "PE",
#'   filter = "COD_MUNI eq 2611606",
#'   select = c("NOM_MUNI", "VAL_RECE_REAL", "VAL_DESP_PAGA")
#' )
#' }
get_siope_dados_gerais <- function(ano, periodo, uf,
                                   use_cache = TRUE, verbose = FALSE,
                                   page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Dados_Gerais_Siope", params, use_cache = use_cache,
              verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_dados_gerais
#' @param year Integer. Year (e.g., `2023`). **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation (e.g., `"PE"`). **Required**.
#'   Maps to `uf`.
#' @usage get_siope_general_data(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_general_data <- function(year, period, state,
                                   use_cache = TRUE, verbose = FALSE,
                                   page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_dados_gerais(ano = year, periodo = period, uf = state,
                         use_cache = use_cache, verbose = verbose,
                         page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_responsaveis / get_siope_officials -----------------------------

#' Get SIOPE officials/responsible persons data
#'
#' Retrieves data about the officials responsible for education spending
#' declarations, including mayors, secretaries, and accountants.
#'
#' `get_siope_officials()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 35 columns including official
#'   names, CPFs, roles, and contact information.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' resp <- get_siope_responsaveis(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_responsaveis <- function(ano, periodo, uf,
                                   use_cache = TRUE, verbose = FALSE,
                                   page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Dados_Gerais_Siope_Dados_Responsaveis", params,
              use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_responsaveis
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_officials(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_officials <- function(year, period, state,
                                use_cache = TRUE, verbose = FALSE,
                                page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_responsaveis(ano = year, periodo = period, uf = state,
                         use_cache = use_cache, verbose = verbose,
                         page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_despesas / get_siope_expenses ----------------------------------

#' Get SIOPE education expenses data
#'
#' Retrieves education spending data broken down by expense categories
#' for municipalities and states.
#'
#' `get_siope_expenses()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 21 columns including expense
#'   categories and values.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' desp <- get_siope_despesas(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_despesas <- function(ano, periodo, uf,
                               use_cache = TRUE, verbose = FALSE,
                               page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Despesas_Siope", params, use_cache = use_cache,
              verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_despesas
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_expenses(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_expenses <- function(year, period, state,
                               use_cache = TRUE, verbose = FALSE,
                               page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_despesas(ano = year, periodo = period, uf = state,
                     use_cache = use_cache, verbose = verbose,
                     page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_despesas_funcao / get_siope_expenses_by_function ---------------

#' Get SIOPE expenses by education function
#'
#' Retrieves education expenses broken down by government function
#' (e.g., basic education, higher education).
#'
#' `get_siope_expenses_by_function()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 12 columns including function
#'   codes and expense values.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' desp_func <- get_siope_despesas_funcao(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_despesas_funcao <- function(ano, periodo, uf,
                                      use_cache = TRUE, verbose = FALSE,
                                      page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Despesas_Funcao_Educacao_Siope", params,
              use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_despesas_funcao
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_expenses_by_function(year, period, state,
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_expenses_by_function <- function(year, period, state,
                                           use_cache = TRUE, verbose = FALSE,
                                           page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_despesas_funcao(ano = year, periodo = period, uf = state,
                            use_cache = use_cache, verbose = verbose,
                            page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_indicadores / get_siope_indicators -----------------------------

#' Get SIOPE education indicators
#'
#' Retrieves education spending indicators such as percentage of revenue
#' applied to education, FUNDEB compliance, etc.
#'
#' `get_siope_indicators()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 13 columns including indicator
#'   codes and values.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' ind <- get_siope_indicadores(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_indicadores <- function(ano, periodo, uf,
                                  use_cache = TRUE, verbose = FALSE,
                                  page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Indicadores_Siope", params, use_cache = use_cache,
              verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_indicadores
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_indicators(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_indicators <- function(year, period, state,
                                 use_cache = TRUE, verbose = FALSE,
                                 page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_indicadores(ano = year, periodo = period, uf = state,
                        use_cache = use_cache, verbose = verbose,
                        page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_info_complementares / get_siope_supplementary ------------------

#' Get SIOPE supplementary information
#'
#' Retrieves supplementary information from SIOPE declarations.
#'
#' `get_siope_supplementary()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 10 columns.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' info <- get_siope_info_complementares(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_info_complementares <- function(ano, periodo, uf,
                                          use_cache = TRUE, verbose = FALSE,
                                          page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Informacoes_Complementares_Siope", params,
              use_cache = use_cache, verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_info_complementares
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_supplementary(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_supplementary <- function(year, period, state,
                                    use_cache = TRUE, verbose = FALSE,
                                    page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_info_complementares(ano = year, periodo = period, uf = state,
                                use_cache = use_cache, verbose = verbose,
                                page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_receitas / get_siope_revenues ----------------------------------

#' Get SIOPE education revenue data
#'
#' Retrieves education revenue data including tax revenues, transfers,
#' and FUNDEB contributions.
#'
#' `get_siope_revenues()` is an English alias.
#'
#' @inheritParams get_siope_dados_gerais
#'
#' @return A [tibble][tibble::tibble] with 14 columns including revenue
#'   categories and values.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' rec <- get_siope_receitas(ano = 2023, periodo = 6, uf = "PE")
#' }
get_siope_receitas <- function(ano, periodo, uf,
                               use_cache = TRUE, verbose = FALSE,
                               page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, uf)
  params <- list(Ano_Consulta = ano, Num_Peri = periodo, Sig_UF = uf)
  siope_fetch("Receita_Siope", params, use_cache = use_cache,
              verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_receitas
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_revenues(year, period, state, use_cache = TRUE,
#'   verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_revenues <- function(year, period, state,
                               use_cache = TRUE, verbose = FALSE,
                               page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, state)
  get_siope_receitas(ano = year, periodo = period, uf = state,
                     use_cache = use_cache, verbose = verbose,
                     page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

# -- get_siope_remuneracao / get_siope_compensation ---------------------------

#' Get SIOPE staff compensation data
#'
#' Retrieves compensation data for education professionals. This endpoint
#' has an additional required parameter: `mes` / `month` for the specific
#' month within the year.
#'
#' `get_siope_compensation()` is an English alias.
#'
#' @param ano Integer. Year of the data (e.g., `2023`). **Required**.
#' @param periodo Integer. Bimester period (1-6). **Required**.
#' @param mes Integer. Month of the fiscal year (1-12). **Required**.
#' @param uf Character. State abbreviation (e.g., `"PE"`). **Required**.
#' @param use_cache Logical. If `TRUE` (default), uses an in-memory cache.
#' @param verbose Logical. If `TRUE`, prints the full API URL.
#' @param page_size Integer. Rows per page for OData pagination. Defaults
#'   to `1000`.
#' @param max_rows Numeric. Maximum rows to return. Defaults to `Inf`.
#' @param filter Character. OData `$filter` expression to narrow results
#'   **on the server** (much faster than downloading everything). Uses
#'   OData syntax (e.g., `"NOM_MUNI eq 'Recife'"`,
#'   `"COD_MUNI eq 2611606"`). Combine with `and`/`or`. Column names
#'   must use the **original API names** (uppercase), not the snake_case
#'   cleaned names. To discover valid names, run a `max_rows = 1` query
#'   and use `toupper(names(result))`. Optional.
#' @param orderby Character. OData `$orderby` expression to sort results
#'   (e.g., `"NOM_MUNI asc"`, `"NUM_POPU desc"`). Uses original API
#'   column names (uppercase). Optional.
#' @param select Character vector. Column names to return (reduces payload
#'   size). Uses original API column names (e.g.,
#'   `c("NOM_MUNI", "VAL_DECL")`). If a column name is invalid the API
#'   returns HTTP 400. Optional.
#'
#' @return A [tibble][tibble::tibble] with 19 columns including
#'   compensation categories and values for education professionals.
#'
#' @family SIOPE
#' @export
#' @examples
#' \dontrun{
#' rem <- get_siope_remuneracao(ano = 2023, periodo = 6, mes = 12, uf = "PE")
#' }
get_siope_remuneracao <- function(ano, periodo, mes, uf,
                                  use_cache = TRUE, verbose = FALSE,
                                  page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(ano, periodo, mes, uf)
  params <- list(
    Ano_Declaracao = ano, Num_Peri = periodo,
    Mes_Exercicio = mes, Sig_UF = uf
  )
  siope_fetch("Remuneracao_Siope", params, use_cache = use_cache,
              verbose = verbose, page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}

#' @rdname get_siope_remuneracao
#' @param year Integer. Year. **Required**. Maps to `ano`.
#' @param period Integer. Bimester (1-6). **Required**. Maps to `periodo`.
#' @param month Integer. Month (1-12). **Required**. Maps to `mes`.
#' @param state Character. State abbreviation. **Required**. Maps to `uf`.
#' @usage get_siope_compensation(year, period, month, state,
#'   use_cache = TRUE, verbose = FALSE,
#'   page_size = 1000, max_rows = Inf,
#'   filter = NULL, orderby = NULL, select = NULL)
#' @export
get_siope_compensation <- function(year, period, month, state,
                                   use_cache = TRUE, verbose = FALSE,
                                   page_size = 1000L, max_rows = Inf,
                                   filter = NULL, orderby = NULL, select = NULL) {
  check_required(year, period, month, state)
  get_siope_remuneracao(ano = year, periodo = period, mes = month, uf = state,
                        use_cache = use_cache, verbose = verbose,
                        page_size = page_size, max_rows = max_rows,
              filter = filter, orderby = orderby, select = select)
}
