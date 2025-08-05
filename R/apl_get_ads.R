#' Get Ads
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with ads metadata
#' @export
#'
apl_get_ads <- function(org_id = apl_get_me_details()$parentOrgId) {

  result <- apl_make_request(
    endpoint = 'ads/find',
    org_id   = org_id,
    parser   = apl_parsers$ads,
    selector = make_selector(sort_field = "campaignId", part = 'selector')
  )

  return(result)

}
