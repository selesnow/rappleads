#' Get Search Term-Level Reports
#'
#' @param org_id The value is your orgId.
#' @param campaign_id The unique identifier for the campaign.
#' @param start_date Start reporting date
#' @param end_date End reporting date
#' @param group_by Use the groupBy field to group responses by selected dimensions. If groupBy specifies age, gender, and geodimensions
#' @param granularity The report data organized by hour, day, week, and month.
#'
#' @returns tibble search term report
#' @export
#'
apl_get_search_term_report <- function(
    org_id      = apl_get_me_details()$parentOrgId,
    campaign_id = apl_get_campaigns()$id,
    start_date  = Sys.Date() - 8,
    end_date    = Sys.Date() - 1,
    group_by    = NULL,
    granularity = c('DAILY', 'HOURLY', 'WEEKLY', 'MONTHLY')
) {

  result <- pbapply::pblapply(
    campaign_id,
    purrr::safely(\(cid) {
      apl_make_request(
        endpoint = stringr::str_glue('reports/campaigns/{cid}/searchterms'),
        org_id   = org_id,
        selector = make_selector(start_date, end_date, granularity, sort_field = "impressions", group_by = group_by),
        parser   = apl_parsers$search_term_report
      )
    }
    )
  )

  result <- purrr::transpose(result)
  errors <- result$error

  # check for errors
  for (error in errors) {
    if (is.null(error)) next
    cli::cli_alert_warning(resp_body_json(error$resp)$error$errors[[1]]$message)
  }

  # collect result
  result <- result$result %>%
            bind_rows()

  return(result)

}
