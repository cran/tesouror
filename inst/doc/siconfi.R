## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# library(tesouror)
# library(dplyr)
# 
# # All entities
# entes <- get_entes()
# 
# # Filter states only
# estados <- entes |> filter(esfera == "E")

## -----------------------------------------------------------------------------
# # RREO Anexo 01 for Tocantins, 6th bimester of 2022
# rreo <- get_budget_report(
#   fiscal_year = 2022, period = 6,
#   report_type = "RREO",
#   appendix = "RREO-Anexo 01",
#   sphere = "E", entity_id = 17
# )

## -----------------------------------------------------------------------------
# # Federal District constitutional fund (id_ente = 1), RREO-Anexo 04.2 —
# # only returns rows when co_esfera is NOT passed
# fcdf <- get_rreo(
#   an_exercicio = 2023, nr_periodo = 6,
#   co_tipo_demonstrativo = "RREO",
#   no_anexo = "RREO-Anexo 04.2",
#   id_ente = 1
# )

## -----------------------------------------------------------------------------
# # RGF Anexo 01 for the executive branch of Tocantins
# rgf <- get_fiscal_report(
#   fiscal_year = 2022, periodicity = "Q", period = 3,
#   report_type = "RGF", appendix = "RGF-Anexo 01",
#   sphere = "E", branch = "E", entity_id = 17
# )

## -----------------------------------------------------------------------------
# dca <- get_annual_accounts(fiscal_year = 2022, entity_id = 17)

## -----------------------------------------------------------------------------
# # Equity accounts (class 1) for December 2022
# msc <- get_msc_equity(
#   entity_id = 17, year = 2022, month = 12,
#   matrix_type = "MSCC", account_class = 1,
#   value_type = "ending_balance"
# )

