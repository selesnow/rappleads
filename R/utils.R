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
  req <- request("https://api.searchads.apple.com/api/v5/") %>%
    req_url_path_append(endpoint) %>%
    req_headers(
      Authorization  = paste("Bearer", apl_auth()),
      `X-AP-Context` = if (is.null(org_id)) NULL else paste0("orgId=", org_id)
    ) %>%
    req_url_query(
      limit  = 1000,
      offset = 0
    ) %>%
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
  resps <- req_perform_iterative(
    req,
    next_req = next_req,
    max_reqs = Inf
  )

  # parsing
  res <- resps_data(resps, parser)

  return(res)

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


# Parsers -----------------------------------------------------------------
apl_simple_parser <- function(resp) {

  content <- resp_body_json(resp)

  content$data

}

apl_user_acl_parser <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider(data) %>%
    rename_with(.fn = to_snake_case)

}

apl_parse_campaigns <- function(resp) {

  content <- resp_body_json(resp)

  tibble(data = content$data) %>%
    unnest_wider(data) %>%
    unnest_wider(budgetAmount, names_sep = '_') %>%
    unnest_wider(dailyBudgetAmount, names_sep = '_') %>%
    rename_with(.fn = to_snake_case)

}

apl_parse_campaign_report <- function(resp) {

  content <- resp_body_json(resp)

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

apl_parsers <- list(
  simple          = apl_simple_parser,
  campaigns       = apl_parse_campaigns,
  user_acl_parser = apl_user_acl_parser,
  campaign_report = apl_parse_campaign_report
)
