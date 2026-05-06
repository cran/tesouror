## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# # From CRAN (when available):
# install.packages("tesouror")
# 
# # Development version from GitHub:
# # remotes::install_github("StrategicProjects/tesouror")

## -----------------------------------------------------------------------------
# library(tesouror)
# 
# # List all government entities
# entes <- get_entes()
# 
# # Get RREO data for Tocantins (IBGE code 17)
# rreo <- get_rreo(
#   an_exercicio = 2022, nr_periodo = 6,
#   co_tipo_demonstrativo = "RREO",
#   no_anexo = "RREO-Anexo 01",
#   co_esfera = "E", id_ente = 17
# )
# 
# # Same query using English aliases
# rreo <- get_budget_report(
#   fiscal_year = 2022, period = 6,
#   report_type = "RREO",
#   appendix = "RREO-Anexo 01",
#   sphere = "E", entity_id = 17
# )
# 
# # Federal government costs (always filter by org to avoid slow queries!)
# custos <- get_custos_pessoal_ativo(
#   ano = 2023, mes = 6,
#   organizacao_n1 = 244,  # MEC (auto-padded)
#   organizacao_n2 = 249   # INEP
# )
# 
# # Constitutional transfers (codes are Treasury-internal, NOT IBGE!)
# estados <- get_tc_estados()
# pe_code <- estados$codigo[estados$nome == "Pernambuco"]
# tc <- get_tc_por_estados(p_estado = pe_code, p_ano = 2023)
# 
# # Education spending data from SIOPE
# indicadores <- get_siope_indicators(year = 2023, period = 6, state = "PE")

## -----------------------------------------------------------------------------
# tesouror_clear_cache()

## -----------------------------------------------------------------------------
# # Portuguese (API-native)
# get_dca(an_exercicio = 2022, id_ente = 17)
# 
# # English
# get_annual_accounts(fiscal_year = 2022, entity_id = 17)

## -----------------------------------------------------------------------------
# # Per call:
# get_costs_active_staff(year = 2023, month = 6, org_level1 = 244, verbose = TRUE)
# #> ℹ API call: https://apidatalake.tesouro.gov.br/ords/custos/tt/pessoal_ativo?ano=2023&mes=6&organizacao_n1=000244&limit=1000
# 
# # Or globally for the session:
# options(tesouror.verbose = TRUE)
# get_entes()  # will print the URL
# options(tesouror.verbose = FALSE)  # turn off

## -----------------------------------------------------------------------------
# # CUSTOS defaults to 1000 rows/page (server default is only 250)
# custos <- get_costs_active_staff(
#   year = 2023, org_level1 = 244, org_level2 = 249
# )
# 
# # Lower for quick tests:
# custos_sample <- get_costs_active_staff(
#   year = 2023, org_level1 = 244, org_level2 = 249,
#   page_size = 100, max_rows = 200
# )
# 
# # SICONFI/SADIPEM default to server's 5000 rows/page (fast)
# entes <- get_entes()

