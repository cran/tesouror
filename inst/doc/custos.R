## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# library(tesouror)
# library(dplyr)
# 
# # Step 1: Look up SIORG codes for the organization you want
# orgaos <- get_siorg_organizations(power_code = 1, sphere_code = 1)
# mec <- orgaos |> filter(sigla == "MEC")          # code 244
# inep <- orgaos |> filter(sigla == "INEP")         # code 249
# 
# # Step 2: Query CUSTOS with org AND month filters (year-only is unsafe!)
# # Active staff costs for INEP, June 2023
# ativos_inep <- get_costs_active_staff(
#   year = 2023, month = 6,
#   org_level1 = 244,     # MEC — auto-padded to "000244"
#   org_level2 = 249      # INEP — auto-padded to "000249"
# )
# 
# # Always check whether pagination completed; on 504 mid-stream the
# # package returns a partial tibble rather than dropping the data.
# if (isTRUE(attr(ativos_inep, "partial"))) {
#   message("Partial result — last page failed: ",
#           attr(ativos_inep, "last_page_error"))
# }
# 
# # Pensioner costs for INEP, June 2023 only
# pensionistas_inep <- get_costs_pensioners(
#   year = 2023, month = 6,
#   org_level1 = 244,
#   org_level2 = 249
# )
# 
# # Quick test: just grab the first 100 rows
# sample <- get_costs_active_staff(
#   year = 2023, month = 6,
#   legal_nature = 3,
#   max_rows = 100
# )

