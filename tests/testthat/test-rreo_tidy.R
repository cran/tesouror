test_that("rreo_layout() loads the bundled CSV with expected columns", {
  layout <- rreo_layout()
  expect_s3_class(layout, "tbl_df")
  expect_setequal(
    names(layout),
    c("topic", "regime", "first_year", "last_year",
      "co_esfera", "no_anexo", "conta_match", "indicador")
  )
  expect_true(all(layout$first_year <= layout$last_year))
  expect_true("previdencia" %in% layout$topic)
})

test_that("rreo_normalize_columns extracts coluna_padrao and coluna_ano", {
  demo <- tibble::tibble(
    coluna = c(
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE/ 2023",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE /2023",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "INSCRITAS EM RESTOS A PAGAR NÃO PROCESSADOS EM 2023",
      "PREVISÃO INICIAL"
    )
  )
  out <- rreo_normalize_columns(demo)

  expect_equal(
    out$coluna_padrao,
    c(
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "INSCRITAS EM RESTOS A PAGAR NÃO PROCESSADOS",
      "PREVISÃO INICIAL"
    )
  )
  expect_equal(out$coluna_ano, c(2023L, 2023L, 2023L, NA_integer_, 2023L, NA_integer_))
})

test_that("rreo_normalize_columns aborts when coluna is missing", {
  expect_error(
    rreo_normalize_columns(tibble::tibble(x = 1)),
    "coluna"
  )
})

test_that("tidy_rreo matches RGPS rows across years despite label drift", {
  fixture <- tibble::tibble(
    exercicio = c(2019L, 2022L, 2023L, 2023L, 2019L),
    instituicao = "Uniao Federal",
    cod_ibge = 1,
    uf = "BR",
    conta = c(
      "Resultado Previdenciário RGPS (VII) = (III - VI)",   # 2019: matches rgps
      "Resultado Previdenciário RGPS (V) = (III - IV)",     # 2022: matches rgps (different roman)
      "Resultado Previdenciário RGPS (VII) = (III - VI)",   # 2023: matches rgps
      "RESULTADO PREVIDENCIÁRIO RPPS CIVIS (V) = (III - IV)", # 2023: matches civil
      "Resultado Previdenciário RGPS (VII) = (III - VI)"    # 2019 RGPS again
    ),
    coluna = c(
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2019",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
      "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
      "DESPESAS EMPENHADAS ATÉ O BIMESTRE/ 2018"
    ),
    valor = c(100, 200, 300, 50, 90)
  )

  rgps <- tidy_rreo(fixture, topic = "previdencia", regime = "rgps")

  expect_equal(nrow(rgps), 4L) # 3 RGPS rows + 1 RGPS row from year 2019 prev-year column
  expect_true(all(rgps$indicador == "resultado_previdenciario_rgps"))
  expect_setequal(rgps$exercicio, c(2019L, 2022L, 2023L))
  expect_true("coluna_padrao" %in% names(rgps))
  expect_setequal(
    unique(rgps$coluna_padrao),
    c("DESPESAS LIQUIDADAS ATÉ O BIMESTRE",
      "DESPESAS EMPENHADAS ATÉ O BIMESTRE")
  )

  # coluna_ano correctly tags previous-year row
  prev_year <- rgps[rgps$valor == 90, ]
  expect_equal(prev_year$coluna_ano, 2018L)
})

test_that("tidy_rreo without regime returns all matching regimes", {
  fixture <- tibble::tibble(
    exercicio = c(2023L, 2023L),
    conta = c(
      "Resultado Previdenciário RGPS (VII) = (III - VI)",
      "RESULTADO PREVIDENCIÁRIO RPPS CIVIS (V) = (III - IV)"
    ),
    coluna = "DESPESAS LIQUIDADAS ATÉ O BIMESTRE / 2023",
    valor = c(10, 20)
  )

  out <- tidy_rreo(fixture, topic = "previdencia")
  expect_setequal(out$regime, c("rgps", "civil_rpps"))
})

test_that("tidy_rreo aborts on unknown topic and warns when nothing matches", {
  fixture <- tibble::tibble(
    exercicio = 2023L,
    conta = "Resultado Previdenciário RGPS (VII)",
    coluna = "DESPESAS LIQUIDADAS",
    valor = 1
  )

  expect_error(
    tidy_rreo(fixture, topic = "inexistente"),
    "No layout entry"
  )

  fixture_no_match <- tibble::tibble(
    exercicio = 2023L, conta = "OUTRA CONTA QUALQUER",
    coluna = "DESPESAS LIQUIDADAS", valor = 1
  )
  out <- suppressMessages(
    tidy_rreo(fixture_no_match, topic = "previdencia")
  )
  expect_equal(nrow(out), 0L)
})

test_that("tidy_rreo aborts when required columns are missing", {
  expect_error(
    tidy_rreo(tibble::tibble(exercicio = 1, conta = "x"), topic = "previdencia"),
    "missing required column"
  )
})
