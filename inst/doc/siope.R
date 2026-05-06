## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# # SLOW: downloads all 185 municipalities, then filters locally
# dados_pe <- get_siope_general_data(year = 2023, period = 6, state = "PE")
# recife <- dplyr::filter(dados_pe, nom_muni == "Recife")
# 
# # FAST: server returns only Recife's data
# recife <- get_siope_general_data(
#   year = 2023, period = 6, state = "PE",
#   filter = "NOM_MUNI eq 'Recife'"
# )
# 
# # Filter by IBGE code
# recife <- get_siope_general_data(
#   year = 2023, period = 6, state = "PE",
#   filter = "COD_MUNI eq 261160"
# )

## -----------------------------------------------------------------------------
# # Only municipality name and declared value
# resumo <- get_siope_expenses(
#   year = 2023, period = 6, state = "PE",
#   select = c("NOM_MUNI", "NOM_ITEM", "VAL_DECL"),
#   filter = "NOM_MUNI eq 'Recife'"
# )

## -----------------------------------------------------------------------------
# # Sort by population descending
# dados <- get_siope_general_data(
#   year = 2023, period = 6, state = "PE",
#   orderby = "NUM_POPU desc", max_rows = 10
# )

## -----------------------------------------------------------------------------
# # Staff compensation for Agrestina, only "Efetivo" professionals
# rem <- get_siope_compensation(
#   year = 2024, period = 1, month = 1, state = "PE",
#   filter = "NOM_MUNI eq 'Agrestina' and DS_SITUACAO_PROFISSIONAL eq 'Efetivo'"
# )

## -----------------------------------------------------------------------------
# library(tesouror)
# library(dplyr)
# 
# # General data for all municipalities in Pernambuco, last bimester 2023
# dados_pe <- get_siope_general_data(year = 2023, period = 6, state = "PE")
# 
# # Education revenues for São Paulo
# receitas_sp <- get_siope_revenues(year = 2023, period = 6, state = "SP")
# 
# # Education indicators for Minas Gerais
# indicadores_mg <- get_siope_indicators(year = 2023, period = 6, state = "MG")
# 
# # Expenses by function for Rio de Janeiro
# desp_func_rj <- get_siope_expenses_by_function(
#   year = 2023, period = 6, state = "RJ"
# )
# 
# # Staff compensation for December 2023 in Bahia
# remuneracao_ba <- get_siope_compensation(
#   year = 2023, period = 6, month = 12, state = "BA"
# )

## -----------------------------------------------------------------------------
# # Grab just 10 rows to inspect the structure
# sample <- get_siope_general_data(
#   year = 2023, period = 6, state = "PE", max_rows = 10
# )
# glimpse(sample)

## -----------------------------------------------------------------------------
# # Fetch multiple states and combine
# nordeste <- c("AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE")
# 
# indicadores_ne <- purrr::map_dfr(nordeste, function(uf) {
#   get_siope_indicators(year = 2023, period = 6, state = uf)
# })

## -----------------------------------------------------------------------------
# get_siope_general_data(year = 2023, period = 6, state = "PE", verbose = TRUE)
# #> ℹ API call: https://www.fnde.gov.br/olinda-ide/servico/...

