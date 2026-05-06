## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# library(tesouror)
# library(dplyr)
# 
# # List all federal executive branch organizations
# orgaos <- get_siorg_organizations(power_code = 1, sphere_code = 1)
# 
# # Key columns:
# #   codigo_unidade     – SIORG code (use as organizacao_n1 in CUSTOS)
# #   codigo_unidade_pai – parent unit code
# #   nome               – organization name
# #   sigla              – abbreviation
# #   codigo_tipo_unidade – "orgao" or "entidade"
# #   codigo_natureza_juridica – 1=Empresa Pública, 2=Fundação, 3=Adm.Direta, 4=Autarquia
# 
# # Find the Ministry of Education
# mec <- orgaos |> filter(grepl("Educação", nome), codigo_tipo_unidade == "orgao")
# mec |> select(codigo_unidade, nome, sigla)
# # codigo_unidade = "244" → this is the org_level1 for CUSTOS

## -----------------------------------------------------------------------------
# # All organizations under MEC (direct children = N2)
# mec_children <- orgaos |>
#   filter(codigo_unidade_pai == "244") |>  # MEC's code
#   select(codigo_unidade, nome, sigla, codigo_tipo_unidade)
# mec_children
# # Examples: INEP (249), FNDE (253), CAPES (478), etc.
# 
# # For deeper structure, use get_siorg_structure()
# estrutura <- get_siorg_structure(unit_code = 244)
# estrutura |> select(codigo_unidade, codigo_unidade_pai, nome, sigla)

## -----------------------------------------------------------------------------
# # Active staff costs for MEC — "244" is auto-padded to "000244"
# custos_mec <- get_costs_active_staff(
#   year = 2023,
#   org_level1 = 244  # numeric or character, both work
# )
# 
# # Drill down to INEP
# custos_inep <- get_costs_active_staff(
#   year = 2023,
#   org_level1 = 244,
#   org_level2 = 249  # auto-padded to "000249"
# )

## -----------------------------------------------------------------------------
# # Full details for AGU (code 46)
# agu <- get_siorg_unit(unit_code = 46)
# agu |> select(codigo_unidade, nome, sigla, codigo_natureza_juridica)

