# В этом файле собраны функции для генерации запроса, отправки, и парсинга результата
## Генерация запроса
## apl_make_request - основная функция для генерации запросов
### is_error - функция определяет был ли ответ от API ошибкой
### error_body - Достаёт сообщение об ошибке
### next_req_post, next_req_get - Функции для реализации пагинации, next_req_get - реализует пагинацию через payload в post запросах, а next_req_get через параметры в get запросах
### make_selector - функция создаёт payload для POST запросов
## Парсинг запросов
### Функции apl_parse_*() предназначены для парсинга результата

# main request build function ---------------------------------------------
#' Make API request
#'
#' @param endpoint API endpoint
#' @param parser Parser function
#' @param org_id Organization ID
#' @param selector [Selector](https://developer.apple.com/documentation/apple_ads/selector) objects define what data the API returns when fetching resources.
#'
#' @returns API parsed response
apl_make_request <- function(
    endpoint,
    parser,
    org_id   = NULL,
    selector = NULL
) {

  # request
  req <- request("https://api.searchads.apple.com/api/") %>%
    req_url_path_append(getOption('apl.api_version')) %>%
    req_url_path_append(endpoint) %>%
    req_headers(
      Authorization  = paste("Bearer", apl_auth()),
      `X-AP-Context` = if (is.null(org_id)) NULL else paste0("orgId=", org_id)
    ) %>%
    req_url_query(
      limit  = 1000,
      offset = 0
    ) %>%
    req_throttle(capacity = 10, fill_time_s = 5) %>%
    req_error(
      is_error = is_error,
      body     = error_body
    )

  # payload
  if (!is.null(selector)) {
    req <- req_body_json(req, selector)
    ## pagination - offset in query params
    next_req <- next_req_post
  } else {
    ## pagination - offset in POST body payload
    next_req <- next_req_get
  }

  # pagination
  retry::retry(
    resps <- req_perform_iterative(
      req,
      next_req = next_req,
      max_reqs = Inf,
      progress = FALSE
    ),
    when      = "Could not evaluate cli|invalid format",
    max_tries = 10,
    interval  = 3
  )

  # parsing
  res <- resps_data(resps, parser)

  return(res)

}


# make_request helpers ----------------------------------------------------
make_selector <- function(
    start_date  = Sys.Date() - 8,
    end_date    = Sys.Date() - 1,
    granularity = c('DAILY', 'HOURLY', 'WEEKLY', 'MONTHLY'),
    sort_field  = "startTime",
    time_zone   = 'UTC',
    part        = NULL
  ) {

  granularity <- match.arg(granularity, several.ok =  FALSE)

  selector <- list(
    startTime   = start_date,
    endTime     = end_date,
    granularity = granularity,
    returnRecordsWithNoMetrics = FALSE,
    timeZone    = time_zone,
    selector = list(
      fields  = NULL,
      orderBy = list(
        list(
          field     = sort_field,
          sortOrder = "ASCENDING"
        )),
      pagination = list(
        offset = 0,
        limit  = 1000
      )
    )
  )

  if (!is.null(part)) {
    selector <- selector[[part]]
  }

  selector

}

# error helpers -----------------------------------------------------------
is_error <- function(resp) {
  !is.null(resp_body_json(resp)$error)
}

error_body <- function(resp) {
  resp_body_json(resp)$error$errors[[1]]$message
}

# pagination helpers ------------------------------------------------------
is_complete <- function(resp) {
  (resp_body_json(resp)$pagination$itemsPerPage + resp_body_json(resp)$pagination$startIndex) >= resp_body_json(resp)$pagination$totalResults || is.null(resp_body_json(resp)$pagination) || resp_body_json(resp)$pagination$totalResults == 0
}

## offset in query params
next_req_get <- iterate_with_offset(
  param_name    = "offset",
  start         = 0,
  offset        = 1000,
  resp_complete = is_complete,
  resp_pages    = function(resp) {
    total <- resp_body_json(resp)$pagination$totalResults
    if (is.null(total) || total == 0) return(1)
    return(total)
  }
)

## offset in POST body payload
next_req_post <- function(resp, req) {
  pag <- resp_body_json(resp)$pagination

  if ((pag$itemsPerPage + pag$startIndex) >= pag$totalResults || is.null(pag) || pag$totalResults == 0) return(NULL)

  offset <- pag$startIndex
  total  <- pag$totalResults

  if (offset + pag$itemsPerPage >= total) return(NULL)

  new_offset <- offset + pag$itemsPerPage

  req_body_json_modify(
    req,
    selector = list(
      pagination = list(
        offset = new_offset,
        limit  = pag$itemsPerPage
      )
    )
  )
}

## pagination page counter
resp_pages_num <- function(resp) {
  pag <- resp_body_json(resp)$pagination
  total <- pag$totalResults %||% 0
  per   <- pag$itemsPerPage %||% 1
  # если пусто — хотя бы одну итерацию
  pages <- max(1L, ceiling(total / per))
  return(pages)
}

# Parsers -----------------------------------------------------------------
apl_simple_parser <- function(resp) {

  content <- resp_body_json(resp)

  content$data

}

apl_user_acl_parser <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider('data') %>%
    rename_with(.fn = to_snake_case)

}

apl_parse_campaigns <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider('data') %>%
    unnest_wider('budgetAmount', names_sep = '_') %>%
    unnest_wider('dailyBudgetAmount', names_sep = '_') %>%
    rename_with(.fn = to_snake_case)

}

apl_parse_ad_groups <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider('data') %>%
    unnest_wider('defaultBidAmount', names_sep = '_') %>%
    rename_with(.fn = to_snake_case)

}

apl_parse_ads <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider('data')

}

apl_parse_creatives <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
     unnest_wider('data')

}

apl_parse_campaign_report <- function(resp) {

  content <- resp_body_json(resp)

  if (length(content$data$reportingDataResponse$row) == 0) return(tibble())

  res <- tibble(data = content$data$reportingDataResponse$row) %>%
    unnest_wider('data') %>%
    unnest_wider('metadata') %>%
    unnest_longer('granularity') %>%
    unnest_wider('granularity')

  fields <- c('avgCPT', 'avgCPM', 'localSpend', 'totalAvgCPI', 'tapInstallCPI', 'app', 'dailyBudget')

  for (field in fields) {
    if (!field %in% names(res)) next
    res <- unnest_wider(res, all_of(field), names_sep = "_")
  }

  res <- rename_with(res, .fn = to_snake_case)
  res

}

apl_parse_ad_group_report <- function(resp) {

  content <- resp_body_json(resp)

  if (length(content$data$reportingDataResponse$row) == 0) return(tibble())

  res <- tibble(data = content$data$reportingDataResponse$row) %>%
    unnest_wider('data') %>%
    unnest_wider('metadata') %>%
    unnest_longer('granularity') %>%
    unnest_wider('granularity')

  fields <- c('defaultBidAmount')

  for (field in fields) {
    if (!field %in% names(res)) next
    res <- unnest_wider(res, all_of(field), names_sep = "_")
  }

  res <- rename_with(res, .fn = to_snake_case)
  res

}

apl_parse_keyword_report <- function(resp) {

  content <- resp_body_json(resp)

  if (length(content$data$reportingDataResponse$row) == 0) return(tibble())

  res <- tibble(data = content$data$reportingDataResponse$row) %>%
    unnest_wider('data') %>%
    unnest_wider('metadata') %>%
    unnest_longer('granularity') %>%
    unnest_wider('granularity')

  fields <- c('bidAmount')

  for (field in fields) {
    if (!field %in% names(res)) next
    res <- unnest_wider(res, all_of(field), names_sep = "_")
  }

  res <- rename_with(res, .fn = to_snake_case)
  res

}

apl_parse_ad_report <- function(resp) {

  content <- resp_body_json(resp)

  if (length(content$data$reportingDataResponse$row) == 0) return(tibble())

  res <- tibble(data = content$data$reportingDataResponse$row) %>%
    unnest_wider('data') %>%
    unnest_wider('metadata') %>%
    unnest_longer('granularity') %>%
    unnest_wider('granularity') %>%
    rename_with(.fn = to_snake_case)

  res

}

apl_parse_search_term_report <- function(resp) {

  content <- resp_body_json(resp)

  if (length(content$data$reportingDataResponse$row) == 0) return(tibble())

  res <- tibble(data = content$data$reportingDataResponse$row) %>%
    unnest_wider('data') %>%
    unnest_wider('metadata') %>%
    unnest_longer('granularity') %>%
    unnest_wider('granularity') %>%
    rename_with(.fn = to_snake_case)

  res

}

apl_parsers <- list(
  simple             = apl_simple_parser,
  campaigns          = apl_parse_campaigns,
  ad_groups          = apl_parse_ad_groups,
  ads                = apl_parse_ads,
  creatives          = apl_parse_creatives,
  user_acl_parser    = apl_user_acl_parser,
  campaign_report    = apl_parse_campaign_report,
  ad_group_report    = apl_parse_ad_group_report,
  keyword_report     = apl_parse_keyword_report,
  ad_report          = apl_parse_ad_report,
  search_term_report = apl_parse_search_term_report
)
