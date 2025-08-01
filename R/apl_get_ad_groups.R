#' Get Ad Groups
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with ad group metadata
#' @export
#'
apl_get_ad_groups <- function(org_id = apl_get_me_details()$parentOrgId) {

  selector <- list(
    fields  = NULL,
    orderBy = list(
      list(
        field     = "campaignId",
        sortOrder = "ASCENDING"
      )),
    pagination = list(
      offset = 0,
      limit  = 1000
    )
  )

  result <- apl_make_request(
    endpoint = 'adgroups/find',
    org_id   = org_id,
    parser   = apl_parsers$ad_groups,
    selector = selector
  )

  return(result)

}
