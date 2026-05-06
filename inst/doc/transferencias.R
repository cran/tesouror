## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# library(tesouror)
# 
# # Transfer types — returns codigo + nome
# tipos <- get_tc_transfer_types()
# tipos
# # e.g., codigo=10 nome="FUNDEB", codigo=14 nome="AJUSTE FUNDEB"
# 
# # State codes — returns codigo + nome
# estados <- get_tc_states()
# estados
# # e.g., codigo=16 nome="Pernambuco" (NOT the IBGE code!)
# 
# # Municipality codes — filter by the state code from above
# pe_code <- estados$codigo[estados$nome == "Pernambuco"]
# mun_pe <- get_tc_municipalities(state_code = pe_code)
# mun_pe

## -----------------------------------------------------------------------------
# # Use the state code obtained from get_tc_states()
# pe_code <- estados$codigo[estados$nome == "Pernambuco"]
# 
# # All transfers for Pernambuco in 2023
# tc_pe <- get_tc_by_state(state_code = pe_code, year = 2023)
# 
# # FUNDEB + AJUSTE FUNDEB — pass a vector of transfer type codes
# tc_fundeb <- get_tc_by_state(
#   state_code = pe_code,
#   year = 2023,
#   transfer_type = c(10, 14)
# )
# 
# # Multiple states, Jan-Mar 2023 — vectors work everywhere
# ac_code <- estados$codigo[estados$nome == "Acre"]
# al_code <- estados$codigo[estados$nome == "Alagoas"]
# tc_multi <- get_tc_by_state(
#   state_code = c(ac_code, al_code),
#   year = 2023,
#   month = 1:3
# )
# 
# # Same query with detailed breakdown
# tc_det <- get_tc_by_state_detail(
#   state_code = c(ac_code, al_code),
#   year = 2023,
#   month = 1:3
# )

## -----------------------------------------------------------------------------
# # Look up municipality codes
# pe_code <- estados$codigo[estados$nome == "Pernambuco"]
# mun_pe <- get_tc_municipalities(state_code = pe_code)
# recife_code <- mun_pe$codigo[mun_pe$nome == "Recife"]
# 
# # All municipalities in Pernambuco in 2023
# tc_mun <- get_tc_by_municipality(state_code = pe_code, year = 2023)
# 
# # Specific municipality: Recife
# tc_recife <- get_tc_by_municipality_detail(
#   state_code = pe_code,
#   municipality = recife_code,
#   year = 2023
# )

