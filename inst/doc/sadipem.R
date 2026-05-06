## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## -----------------------------------------------------------------------------
# library(tesouror)
# library(dplyr)
# 
# # Step 1: Search PVLs for Pernambuco
# pvl_pe <- get_debt_requests(state = "PE")
# 
# # Step 2: Pick an id_pleito VALUE from the results
# id <- pvl_pe$id_pleito[1]
# 
# # Step 3: Get details using that id_pleito
# pagamentos <- get_credit_payment_schedule(request_id = id)
# cdp <- get_debt_capacity(request_id = id)

## -----------------------------------------------------------------------------
# pvl_deferidos <- pvl_pe |> filter(status == "Deferido")
# if (nrow(pvl_deferidos) > 0) {
#   status <- get_pvl_status(request_id = pvl_deferidos$id_pleito[1])
# }

