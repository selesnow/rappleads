#' Get Ad-Level Reports
#'
#' @param org_id The value is your orgId.
#' @param campaign_id The unique identifier for the campaign.
#' @param start_date Start reporting date
#' @param end_date End reporting date
#' @param group_by Use the groupBy field to group responses by selected dimensions. If groupBy specifies age, gender, and geodimensions
#' @param granularity The report data organized by hour, day, week, and month.
#'
#' @returns tibble ad report
#' @export
#'
apl_get_ad_report <- function(
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
        endpoint = stringr::str_glue('reports/campaigns/{cid}/ads'),
        org_id   = org_id,
        selector = make_selector(
          start_date  = start_date,
          end_date    =  end_date,
          granularity = granularity,
          sort_field  = "adGroupId",
          group_by    = group_by),
        parser   = apl_parsers$ad_report
      )
    }
    )
  )

  result <- purrr::transpose(result)
  errors <- result$error

  # collect result
  result <- result$result %>%
            bind_rows()

  return(result)

}
