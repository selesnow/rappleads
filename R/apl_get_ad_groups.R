#' Get Ad Groups
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with ad group metadata
#' @export
#'
apl_get_ad_groups <- function(org_id = apl_get_me_details()$parentOrgId) {

  result <- apl_make_request(
    endpoint = 'adgroups/find',
    org_id   = org_id,
    parser   = apl_parsers$ad_groups,
    selector = make_selector(sort_field = "campaignId", part = 'selector')
  )

  return(result)

}
