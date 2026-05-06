## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# library(tesouror)
# 
# rreo_layout()

## -----------------------------------------------------------------------------
# layout <- rreo_layout()
# fetch_year <- function(year) {
#   rule <- layout[layout$topic == "previdencia" &
#                  layout$regime == "rgps" &
#                  year >= layout$first_year &
#                  year <= layout$last_year, ]
#   get_rreo(
#     an_exercicio = year, nr_periodo = 6,
#     co_tipo_demonstrativo = "RREO", no_anexo = rule$no_anexo[1],
#     co_esfera = "U", id_ente = 1
#   )
# }

## -----------------------------------------------------------------------------
# demo <- tibble::tibble(
#   coluna = c(
#     "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
#     "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
#     "DESPESAS LIQUIDADAS ATÉ O BIMESTRE/ 2018",
#     "INSCRITAS EM RESTOS A PAGAR NÃO PROCESSADOS EM 2023"
#   )
# )
# rreo_normalize_columns(demo)

## -----------------------------------------------------------------------------
# library(dplyr)
# 
# # Pull the federal RGPS series for five years using the layout
# rgps_raw <- purrr::map_dfr(2019:2023, fetch_year)
# 
# rgps_tidy <- rgps_raw |>
#   tidy_rreo(topic = "previdencia", regime = "rgps")
# 
# panel <- rgps_tidy |>
#   filter(coluna_padrao == "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
#          is.na(coluna_ano) | coluna_ano == exercicio) |>
#   select(exercicio, indicador, regime, valor)
# 
# panel

## -----------------------------------------------------------------------------
# all_topics <- rreo_layout()
# fetch_topic <- function(year, regime) {
#   rules <- all_topics[all_topics$topic == "previdencia" &
#                       all_topics$regime == regime &
#                       year >= all_topics$first_year &
#                       year <= all_topics$last_year, ]
#   if (nrow(rules) == 0L) return(NULL)
#   purrr::map_dfr(unique(rules$no_anexo), \(an) {
#     get_rreo(
#       an_exercicio = year, nr_periodo = 6,
#       co_tipo_demonstrativo = "RREO", no_anexo = an,
#       co_esfera = "U", id_ente = 1
#     )
#   })
# }
# 
# regimes <- unique(all_topics$regime[all_topics$topic == "previdencia"])
# raw_22_23 <- purrr::map_dfr(2022:2023, \(yr) {
#   purrr::map_dfr(regimes, \(rg) fetch_topic(yr, rg))
# })
# 
# raw_22_23 |>
#   tidy_rreo(topic = "previdencia") |>
#   filter(coluna_padrao == "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
#          is.na(coluna_ano) | coluna_ano == exercicio) |>
#   select(exercicio, indicador, regime, valor) |>
#   distinct()

