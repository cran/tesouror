# ============================================================================
# RREO tidy layer — handles SICONFI's drifting labels across years
# Addresses rsiconfi#4 (https://github.com/tchiluanda/rsiconfi/issues/4)
# ============================================================================

#' Strip diacritics from a character vector
#'
#' Uses [stringi::stri_trans_general()] with the `"Latin-ASCII"` transliteration
#' so it behaves identically across platforms (the macOS `iconv("ASCII//
#' TRANSLIT")` inserts apostrophes for accented vowels, which would break
#' matching).
#' @noRd
.strip_accents <- function(x) {
  stringi::stri_trans_general(x, "Latin-ASCII")
}

#' Reduce a SICONFI `conta` value to a stable matching key
#'
#' SICONFI's `conta` field carries a free-text label followed by formula
#' notation that depends on the layout, e.g. `"RESULTADO PREVIDENCIÁRIO RGPS
#' (VII) = (III - VI)"`. The Roman numerals shift across years even when the
#' underlying concept is identical. This helper drops everything from the
#' first `(` onwards, strips diacritics, lowercases, and squishes whitespace,
#' producing the key used for matching against `inst/extdata/rreo_layout.csv`.
#' @noRd
.clean_conta <- function(x) {
  x <- sub("\\s*\\(.*$", "", x)
  x <- .strip_accents(x)
  x <- tolower(x)
  stringr::str_squish(x)
}

#' Cached loader for the bundled RREO layout table
#' @noRd
.layout_env <- new.env(parent = emptyenv())
.load_rreo_layout <- function() {
  if (!is.null(.layout_env$tbl)) return(.layout_env$tbl)
  path <- system.file("extdata", "rreo_layout.csv", package = "tesouror")
  if (!nzchar(path)) {
    cli::cli_abort("Could not locate {.path inst/extdata/rreo_layout.csv}.")
  }
  tbl <- utils::read.csv(path, stringsAsFactors = FALSE,
                         encoding = "UTF-8", strip.white = TRUE)
  tbl$first_year <- as.integer(tbl$first_year)
  tbl$last_year  <- as.integer(tbl$last_year)
  .layout_env$tbl <- tibble::as_tibble(tbl)
  .layout_env$tbl
}

# -- rreo_layout --------------------------------------------------------------

#' Return the bundled RREO layout reference table
#'
#' RREO appendix names, account labels, and column suffixes drift across
#' fiscal years (e.g., `RREO-Anexo 04.3 - RGPS` for 2019-2022 vs.
#' `RREO-Anexo 04.4 - RGPS` for 2023+). The package ships a small reference
#' table in `inst/extdata/rreo_layout.csv` that maps `(topic, regime,
#' year_range)` to the correct appendix and account-matching key.
#'
#' [tidy_rreo()] uses this table to assemble layout-stable indicators across
#' years; you can also use it directly to look up which appendix to fetch
#' with [get_rreo()] for a given topic.
#'
#' @return A [tibble][tibble::tibble] with columns `topic`, `regime`,
#'   `first_year`, `last_year`, `co_esfera`, `no_anexo`, `conta_match`,
#'   `indicador`.
#' @family RREO tidy
#' @export
#' @examples
#' rreo_layout()
rreo_layout <- function() {
  .load_rreo_layout()
}

# -- rreo_normalize_columns ---------------------------------------------------

#' Normalize the `coluna` field of a RREO tibble across years
#'
#' SICONFI's RREO column labels drift over years: the same conceptual column
#' appears as `"DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2019"` in 2019,
#' `"DESPESAS LIQUIDADAS ATÉ O BIMESTRE"` (no year) in 2021-2022, and
#' `"DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023"` in 2023+. This helper adds
#' two columns:
#'
#' * `coluna_padrao`: the column label with any trailing `"/ YYYY"` or
#'   `"EM YYYY"` suffix removed (whitespace squished).
#' * `coluna_ano`: the year that appeared in the suffix (integer), or `NA`
#'   when no year was present. Useful for distinguishing the current-year
#'   column from a comparative previous-year column.
#'
#' @param data A tibble returned by [get_rreo()] or [get_rreo_for_state()].
#'   Must contain a `coluna` column.
#'
#' @return The input tibble with `coluna_padrao` and `coluna_ano` appended.
#' @family RREO tidy
#' @export
#' @examples
#' demo <- tibble::tibble(
#'   coluna = c(
#'     "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
#'     "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
#'     "INSCRITAS EM RESTOS A PAGAR NÃO PROCESSADOS EM 2023"
#'   )
#' )
#' rreo_normalize_columns(demo)
rreo_normalize_columns <- function(data) {
  if (!"coluna" %in% names(data)) {
    cli::cli_abort("Input must have a {.field coluna} column.")
  }
  year_suffix <- "(\\s*/\\s*\\d{4}|\\s+EM\\s+\\d{4})\\s*$"
  ano <- suppressWarnings(as.integer(
    stringr::str_extract(data$coluna, "\\d{4}(?=\\s*$)")
  ))
  ano[!grepl(year_suffix, data$coluna)] <- NA_integer_
  padrao <- stringr::str_squish(
    sub(year_suffix, "", data$coluna)
  )
  dplyr::mutate(data, coluna_padrao = padrao, coluna_ano = ano)
}

# -- tidy_rreo ----------------------------------------------------------------

#' Tidy a RREO tibble by topic, reconciling layout drift across years
#'
#' Filters a long RREO tibble (typically produced by [get_rreo()]) down to the
#' rows that match a known indicator for `topic` (and optionally `regime`),
#' using the rules in [rreo_layout()]. Account labels are matched on a
#' year-stable, accent-folded key (Roman numerals and formula text are
#' stripped before comparison), so the same call returns a coherent series
#' across years even when SICONFI relabelled the appendix or account.
#'
#' Currently supported topics:
#'
#' * `"previdencia"` — federal previdência (RGPS, RPPS civis, FCDF, militares
#'   inativos) for the União sphere. Anexos 04.1 / 04.2 / 04.3 / 04.4 of the
#'   RREO; the layout knows that the RGPS appendix moved from 04.3 (up to 2022) to
#'   04.4 (2023+) and that civis/FCDF moved from 04.1 (up to 2022) to 04.2 (2023+).
#'
#' Pull requests adding new topics to `inst/extdata/rreo_layout.csv` are
#' welcome.
#'
#' @param data A tibble returned by [get_rreo()] or [get_rreo_for_state()],
#'   with at least the columns `exercicio`, `conta`, `coluna`, `valor`.
#' @param topic Character. Topic name (e.g., `"previdencia"`). See
#'   [rreo_layout()] for the supported set.
#' @param regime Optional character. Filter to a subset of regimes within
#'   `topic` (e.g., `"rgps"`, `"rpps"`). When `NULL` (default) all regimes
#'   are kept.
#'
#' @return A [tibble][tibble::tibble] with the matched rows, plus extra
#'   columns:
#'   * `indicador`: stable indicator name (e.g.,
#'     `"resultado_previdenciario_rgps"`).
#'   * `regime`: matched regime.
#'   * `coluna_padrao`, `coluna_ano`: see [rreo_normalize_columns()].
#'
#' @family RREO tidy
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#' rreo <- purrr::map_dfr(2019:2023, \(yr) {
#'   get_rreo(an_exercicio = yr, nr_periodo = 6,
#'            co_tipo_demonstrativo = "RREO",
#'            no_anexo = rreo_layout()$no_anexo[
#'              rreo_layout()$topic == "previdencia" &
#'              rreo_layout()$regime == "rgps" &
#'              yr >= rreo_layout()$first_year &
#'              yr <= rreo_layout()$last_year
#'            ][1],
#'            co_esfera = "U", id_ente = 1)
#' })
#' tidy_rreo(rreo, topic = "previdencia", regime = "rgps") |>
#'   filter(coluna_padrao == "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
#'          is.na(coluna_ano) | coluna_ano == exercicio) |>
#'   select(exercicio, indicador, valor)
#' }
tidy_rreo <- function(data, topic, regime = NULL) {
  required_cols <- c("exercicio", "conta", "coluna", "valor")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "x" = "Input is missing required column{?s}: {.field {missing_cols}}.",
      "i" = "Did you pass the raw output of {.fun get_rreo}?"
    ))
  }

  layout <- rreo_layout()
  layout <- layout[layout$topic == topic, , drop = FALSE]
  if (!is.null(regime)) {
    layout <- layout[layout$regime %in% regime, , drop = FALSE]
  }
  if (nrow(layout) == 0L) {
    cli::cli_abort(c(
      "x" = "No layout entry for topic={.val {topic}}{if (!is.null(regime)) paste0(', regime=', paste(regime, collapse = '/'))}.",
      "i" = "Run {.fun rreo_layout} to inspect supported topics/regimes."
    ))
  }

  data <- rreo_normalize_columns(data)
  data$.match_key <- .clean_conta(data$conta)
  data$.exercicio <- suppressWarnings(as.integer(data$exercicio))

  matched <- vector("list", nrow(layout))
  for (i in seq_len(nrow(layout))) {
    rule <- layout[i, ]
    pick <- !is.na(data$.exercicio) &
      data$.exercicio >= rule$first_year &
      data$.exercicio <= rule$last_year &
      data$.match_key == rule$conta_match
    if (any(pick)) {
      rows <- data[pick, , drop = FALSE]
      rows$indicador <- rule$indicador
      rows$regime    <- rule$regime
      matched[[i]]   <- rows
    }
  }

  result <- dplyr::bind_rows(matched)
  result$.match_key <- NULL
  result$.exercicio <- NULL

  if (nrow(result) == 0L) {
    cli::cli_alert_warning(
      "No rows matched topic={.val {topic}} in the supplied data."
    )
    return(tibble::tibble())
  }

  dplyr::select(
    result,
    "indicador", "regime",
    dplyr::any_of("exercicio"),
    dplyr::any_of(c("instituicao", "cod_ibge", "uf")),
    dplyr::everything()
  )
}
