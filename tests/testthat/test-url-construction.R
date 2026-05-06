# URL-construction tests: each public fetcher hits a specific endpoint with a
# specific set of query params. We capture the request URL via a mocked
# response that records the inbound request and assert against it.
#
# Why a custom recorder rather than httptest2::expect_GET? The latter
# requires `without_internet()` and has order-sensitive query matching that
# can be brittle across httr2 versions. A mock function is simpler and gives
# us substring matching on the URL.

capture_url <- function(response_fn = function() mock_ords_response(items = list())) {
  rec <- new.env(parent = emptyenv())
  rec$urls <- character()
  list(
    mock = function(req) {
      rec$urls <- c(rec$urls, req$url)
      response_fn()
    },
    urls = function() rec$urls
  )
}

test_that("get_rreo builds the SICONFI rreo URL with all required params", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url()

  out <- httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_rreo(
      an_exercicio = 2022, nr_periodo = 6,
      co_tipo_demonstrativo = "RREO", no_anexo = "RREO-Anexo 01",
      co_esfera = "E", id_ente = 17, use_cache = FALSE
    ))
  )

  url <- rec$urls()[1]
  expect_match(url, "apidatalake\\.tesouro\\.gov\\.br/ords/siconfi/tt/rreo")
  expect_match(url, "an_exercicio=2022")
  expect_match(url, "nr_periodo=6")
  expect_match(url, "co_tipo_demonstrativo=RREO")
  expect_match(url, "no_anexo=RREO")
  expect_match(url, "co_esfera=E")
  expect_match(url, "id_ente=17")
})

test_that("get_dca uses the SICONFI /dca endpoint", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url()

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_dca(an_exercicio = 2022, id_ente = 17, use_cache = FALSE))
  )

  url <- rec$urls()[1]
  expect_match(url, "/ords/siconfi/tt/dca\\?")
  expect_match(url, "an_exercicio=2022")
  expect_match(url, "id_ente=17")
})

test_that("get_custos_pessoal_ativo pads SIORG codes to 6 digits", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url()

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_custos_pessoal_ativo(
      ano = 2023, organizacao_n1 = 244, organizacao_n2 = 249,
      use_cache = FALSE
    ))
  )

  url <- rec$urls()[1]
  expect_match(url, "/ords/custos/tt/pessoal_ativo")
  expect_match(url, "organizacao_n1=000244")  # padded
  expect_match(url, "organizacao_n2=000249")  # padded
  expect_match(url, "ano=2023")
})

test_that("get_pvl hits SADIPEM /pvl with the right query", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url()

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_pvl(uf = "PE", use_cache = FALSE))
  )

  url <- rec$urls()[1]
  expect_match(url, "/ords/sadipem/tt/+/pvl")
  expect_match(url, "uf=PE")
})

test_that("get_siorg_orgaos hits the SIORG host and the resumida endpoint", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url(function() mock_json_response(body = list(unidades = list())))

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_siorg_orgaos(codigo_poder = 1, codigo_esfera = 1,
                                       use_cache = FALSE))
  )

  url <- rec$urls()[1]
  expect_match(url, "estruturaorganizacional\\.dados\\.gov\\.br")
  expect_match(url, "/doc/orgao-entidade/resumida")
  expect_match(url, "codigoPoder=1")
  expect_match(url, "codigoEsfera=1")
})

test_that("get_siope_dados_gerais builds an OData URL with @ aliases and $format=json", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url(function() httr2::response_json(body = list(value = list())))

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_siope_dados_gerais(ano = 2023, periodo = 6, uf = "PE",
                                             use_cache = FALSE, max_rows = 5))
  )

  url <- rec$urls()[1]
  expect_match(url, "fnde\\.gov\\.br/olinda-ide/servico/DADOS_ABERTOS_SIOPE")
  expect_match(url, "Dados_Gerais_Siope(\\(|%28)")
  expect_match(url, "%40Ano_Consulta=2023|@Ano_Consulta=2023")
  expect_match(url, "%40Sig_UF=%27PE%27|@Sig_UF=%27PE%27|@Sig_UF='PE'")
  expect_match(url, "%24format=json|\\$format=json")
})

test_that("get_tc_estados hits the apiapex Transferencias host", {
  skip_if_no_httptest2()
  local_fast_retry()
  rec <- capture_url(function() mock_json_response(body = list(registros = list())))

  httr2::with_mocked_responses(
    rec$mock,
    suppressMessages(get_tc_estados(use_cache = FALSE))
  )

  url <- rec$urls()[1]
  expect_match(url, "apiapex\\.tesouro\\.gov\\.br")
  expect_match(url, "/transferencias_constitucionais/custom/estados")
})
