#' Get Campaign-Level Reports
#'
#' @param org_id The value is your orgId.
#' @param start_date Start reporting date
#' @param end_date End reporting date
#' @param granularity The report data organized by hour, day, week, and month.
#'
#' @returns tibble with report data
#' @export
#'
apl_get_campaign_report <- function(
  org_id      = apl_get_me_details()$parentOrgId,
  start_date  = Sys.Date() - 8,
  end_date    = Sys.Date() - 1,
  group_by    = NULL,
  granularity = c('DAILY', 'HOURLY', 'WEEKLY', 'MONTHLY')
){

  result <- apl_make_request(
    endpoint = 'reports/campaigns',
    org_id   = org_id,
    selector = make_selector(start_date, end_date, granularity, group_by = group_by),
    parser   = apl_parsers$campaign_report
  )

  return(result)

}


