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
  granularity = c('DAILY', 'HOURLY', 'WEEKLY', 'MONTHLY')
){

  granularity <- match.arg(granularity, several.ok =  FALSE)

  selector <- list(
    startTime   = start_date,
    endTime     = end_date,
    granularity = granularity,
    selector = list(
      fields  = NULL,
      orderBy = list(
        list(
          field     = "startTime",
          sortOrder = "ASCENDING"
        )),
      pagination = list(
        offset = 0,
        limit  = 1000
      )
    )
  )

  result <- apl_make_request(
    endpoint = 'reports/campaigns',
    org_id   = org_id,
    selector = selector,
    parser   = apl_parsers$campaign_report
  )

  return(result)

}


