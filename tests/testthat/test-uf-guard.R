test_that(".check_not_uf_abbrev aborts on common UF abbreviations", {
  for (uf in c("PE", "pe", "SP", "RR", "BR")) {
    expect_error(
      tesouror:::.check_not_uf_abbrev(uf, "p_uf"),
      "Treasury state code",
      info = paste("UF:", uf)
    )
  }
})

test_that(".check_not_uf_abbrev passes through numeric codes and NULL", {
  expect_invisible(tesouror:::.check_not_uf_abbrev(NULL, "p_uf"))
  expect_invisible(tesouror:::.check_not_uf_abbrev(16, "p_uf"))
  expect_invisible(tesouror:::.check_not_uf_abbrev("16", "p_uf"))
  expect_invisible(tesouror:::.check_not_uf_abbrev(c(1, 2), "p_uf"))
})

test_that(".check_not_uf_abbrev ignores 2-char strings that aren't UFs", {
  expect_invisible(tesouror:::.check_not_uf_abbrev("XX", "p_uf"))
  expect_invisible(tesouror:::.check_not_uf_abbrev("ab", "p_uf"))
})

test_that("get_tc_municipios aborts early when p_uf is an UF abbreviation", {
  expect_error(
    get_tc_municipios(p_uf = "PE"),
    "Treasury state code"
  )
})

test_that("get_tc_por_estados aborts early when p_estado is an UF abbreviation", {
  expect_error(
    get_tc_por_estados(p_estado = "PE", p_ano = 2023),
    "Treasury state code"
  )
})
