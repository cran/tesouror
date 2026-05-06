# tesouror <img src="man/figures/logo.svg" align="right" height="139" alt="tesouror logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/StrategicProjects/tesouror/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/StrategicProjects/tesouror/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**tesouror** provides a unified R interface to the Brazilian National Treasury
(Tesouro Nacional) open data APIs. It covers five major data sources:

| API | Data | Functions |
|:---|:---|:---|
| **SICONFI** | Fiscal reports (RREO, RGF, DCA, MSC), entities | `get_rreo()`, `get_rgf()`, `get_dca()`, ... |
| **CUSTOS** | Federal government costs | `get_custos_pessoal_ativo()`, ... |
| **SADIPEM** | Public debt & credit operations (PVL) | `get_pvl()`, `get_opc_*()`, `get_res_*()` |
| **SIORG** | Federal organizational structure (dictionary for CUSTOS) | `get_siorg_orgaos()`, `get_siorg_estrutura()` |
| **Transferências** | Constitutional transfers to states/municipalities | `get_tc_*()` |
| **SIOPE** | Education spending (FNDE/MEC) | `get_siope_dados_gerais()`, `get_siope_despesas()`, ... |

All functions return tidy tibbles and have both **Portuguese** (matching API
parameter names) and **English** aliases.

<table class="important-banner"><tr><td>
&#x2755; <strong class="important-title">Disclaimer</strong><br>
This package acts as a wrapper for Brazilian public APIs provided by the
Secretaria do Tesouro Nacional (STN), which is the institution responsible for
the data. To maintain consistency with R package development standards, all
wrapper functions are available with English names and English parameter names.
However, because the source APIs are natively in Portuguese, some
<strong>parameter values</strong> must still be passed in Portuguese (e.g.,
<code>report_type = "RREO Simplificado"</code>,
<code>appendix = "RREO-Anexo 01"</code>), and <strong>response column
names</strong> are in Portuguese (e.g., <code>cod_ibge</code>,
<code>exercicio</code>, <code>valor</code>). For example: you may use
<code>get_budget_report()</code>, but you need to pass values like
<code>appendix = "RREO-Anexo 01"</code>. The original Portuguese-named
functions (e.g., <code>get_rreo(an_exercicio = 2022)</code>) are also fully
supported. You can find the original list of endpoints and their respective
parameters in the official API documentation:
<a href="https://apidatalake.tesouro.gov.br/docs/siconfi/">SICONFI</a>,
<a href="https://apidatalake.tesouro.gov.br/docs/custos/">CUSTOS</a>,
<a href="https://apidatalake.tesouro.gov.br/docs/sadipem/">SADIPEM</a>,
<a href="https://api.siorg.economia.gov.br/">SIORG</a>, and
<a href="https://apiapex.tesouro.gov.br/aria/v1/transferencias_constitucionais/docs">Transferências Constitucionais</a>, and
SIOPE (FNDE/MEC).
</td></tr></table>

## Installation

```r
# From CRAN (when available):
install.packages("tesouror")

# Development version:
# remotes::install_github("StrategicProjects/tesouror")
```

## Quick start

```r
library(tesouror)

# List government entities
entes <- get_entes()

# RREO for Tocantins
rreo <- get_budget_report(
  fiscal_year = 2022, period = 6, report_type = "RREO",
  appendix = "RREO-Anexo 01", sphere = "E", entity_id = 17
)

# Federal government active staff costs (always filter by org AND month!
# the CUSTOS backend is slow; year-wide queries often hit HTTP 504)
custos <- get_costs_active_staff(
  year = 2023, month = 6,
  org_level1 = 244, org_level2 = 249  # MEC > INEP
)
# If pagination fails mid-way the package returns a partial result;
# check `attr(custos, "partial")` and `attr(custos, "last_page_error")`.

# Constitutional transfers (codes are Treasury-internal, NOT IBGE!)
estados <- get_tc_states()
pe <- estados$codigo[estados$nome == "Pernambuco"]
tc <- get_tc_by_state(state_code = pe, year = 2023)

# Public debt requests for PE
pvl <- get_debt_requests(state = "PE")

# SIORG: look up organization codes for CUSTOS queries
orgaos <- get_siorg_organizations(power_code = 1, sphere_code = 1)
# Use orgaos$codigo_unidade as org_level1 in get_costs_active_staff()

# SIOPE: education spending data
indicadores <- get_siope_indicators(year = 2023, period = 6, state = "PE")

# Clear the cache if needed
tesouror_clear_cache()
```

## Features

- **Bilingual**: Portuguese and English function/parameter names
- **Caching**: In-memory cache avoids repeated API calls
- **Pagination**: Automatic handling of multi-page responses with progress
- **`verbose` mode**: Print full API URLs for debugging (`verbose = TRUE` or `options(tesouror.verbose = TRUE)`)
- **`page_size` control**: Tune rows per page for speed vs. stability
- **Clean output**: `janitor::clean_names()` ensures consistent snake_case columns
- **Friendly errors**: Retries with informative messages; NA validation on required params
- **Tidy output**: All results are tibbles

## Migrating from siconfir

`tesouror` is a superset of `siconfir`. All SICONFI functions work exactly
the same. The cache-clearing function is now `tesouror_clear_cache()`:

```r
tesouror_clear_cache()
```

## Documentation

See the package website at
<https://strategicprojects.github.io/tesouror/> for full documentation
and vignettes.


## Architecture

<img src="man/figures/architecture.svg" alt="tesouror package architecture — 6 APIs, 80 functions" width="100%"/>

## API Reference

### SICONFI — Fiscal Reports

```
https://apidatalake.tesouro.gov.br/ords/siconfi/tt/
```

Provides fiscal reports (RREO, RGF, DCA), accounting matrices (MSC), and
a government entity registry. Maintained by STN (Secretaria do Tesouro
Nacional).

| Detail | Value |
|:---|:---|
| Pagination | ORDS (`hasMore`/`offset`), automatic |
| Default page size | Server default (5,000 rows) |
| Retries | 5 attempts, progressive backoff (3s, 6s, 9s...) |
| `max_rows` | Supported |
| Functions | 18 (9 PT + 9 EN) |

### CUSTOS — Federal Government Costs

```
https://apidatalake.tesouro.gov.br/ords/custos/tt/
```

Cost data for active/retired staff, pensioners, depreciation, transfers,
and other costs. Broken down by organization hierarchy (SIORG codes) and
demographics.

| Detail | Value |
|:---|:---|
| Pagination | ORDS (`hasMore`/`offset`), automatic |
| Default page size | **500 rows** (lowered from 1000 in 0.2.1: the backend timed out on broad queries) |
| Retries | 5 attempts, progressive backoff (3s, 6s, 9s...) |
| `max_rows` | Supported |
| Partial results | When pagination fails mid-way, the package returns what was fetched with `attr(result, "partial") = TRUE` |
| SIORG code padding | Automatic (`244` → `"000244"`) |
| Functions | 12 (6 PT + 6 EN) |

> **Warning**: The CUSTOS API is slow. Always filter by `organizacao_n1`
> + `organizacao_n2` (or `org_level1` + `org_level2`) **and** by `mes` /
> `month` to avoid HTTP 504 timeouts. Use `max_rows` for quick tests.
> Year-wide queries with no month filter routinely time out the
> upstream load balancer.

### SADIPEM — Public Debt

```
https://apidatalake.tesouro.gov.br/ords/sadipem/tt/
```

Public debt verification letters (PVL), credit operations, payment
schedules, exchange rates, and debt capacity results.

| Detail | Value |
|:---|:---|
| Pagination | ORDS (`hasMore`/`offset`), automatic |
| Default page size | Server default (5,000 rows) |
| Retries | 5 attempts, progressive backoff |
| `max_rows` | Supported |
| Functions | 14 (7 PT + 7 EN) |

### Transferências Constitucionais

```
https://apiapex.tesouro.gov.br/aria/v1/transferencias_constitucionais/custom/
```

Constitutional transfers (FPE, FPM, FUNDEB, etc.) to states and
municipalities. Uses Treasury-internal codes (**not** IBGE codes) — use
the dictionary functions to look them up.

| Detail | Value |
|:---|:---|
| Pagination | None (single response) |
| Retries | 5 attempts, progressive backoff |
| Multi-value params | Accepts vectors (`c(1,2)`) or colon-separated strings (`"1:2"`) |
| Functions | 14 (7 PT + 7 EN) |

### SIORG — Organizational Structure

```
https://estruturaorganizacional.dados.gov.br/
```

Federal organizational structure: ministries, autarchies, foundations,
and their internal hierarchy. Used as a dictionary to look up SIORG codes
for CUSTOS API queries.

| Detail | Value |
|:---|:---|
| Pagination | None (single response, JSON-based) |
| Retries | 5 attempts, progressive backoff |
| Functions | 6 (3 PT + 3 EN) |

### SIOPE — Education Spending

```
https://www.fnde.gov.br/olinda-ide/servico/DADOS_ABERTOS_SIOPE/versao/v1/odata/
```

Education spending data from FNDE/MEC: revenues, expenses, indicators,
staff compensation, and declaration officials. Uses an OData-style API.

| Detail | Value |
|:---|:---|
| Pagination | OData (`$top`/`$skip`), automatic |
| Default page size | **1,000 rows** |
| Retries | 5 attempts, progressive backoff |
| `max_rows` | Supported |
| `filter` | OData `$filter` for server-side filtering (e.g., `"NOM_MUNI eq 'Recife'"`) |
| `orderby` | OData `$orderby` for server-side sorting |
| `select` | OData `$select` to choose specific columns |
| Functions | 16 (8 PT + 8 EN) |

> **Tip**: Use `filter` to narrow results on the server before downloading.
> Column names in `filter`/`select`/`orderby` must use the **original API
> names** (uppercase). Run a `max_rows = 1` query and `toupper(names(result))`
> to discover valid column names.

### Common features (all APIs)

| Feature | Details |
|:---|:---|
| **Caching** | In-memory per session. Clear with `tesouror_clear_cache()`. |
| **Retries** | 5 attempts with progressive backoff (3s, 6s, 9s, 12s, 15s) on HTTP 500/502/503/504/429 and connection failures. HTTP 400/404 are **not** retried. |
| **`verbose` mode** | Per-call (`verbose = TRUE`) or global (`options(tesouror.verbose = TRUE)`). Prints full API URL for every request. |
| **Column cleaning** | `janitor::clean_names()` applied to all responses (consistent snake_case). |
| **Bilingual** | Every function has Portuguese (API-native) and English-named aliases. |
| **Output** | Tidy tibbles with whitespace trimming. |
| **Error messages** | Friendly, actionable messages with URL and hints. HTTP 400 errors suggest checking column names. |

## License

MIT
