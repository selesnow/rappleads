#' Get all Campaigns
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with campaigns
#' @export
#'
apl_get_campaigns <- function(org_id) {

  result <- apl_make_request(
    endpoint = 'campaigns',
    org_id   = org_id,
    parser   = apl_parsers$campaigns
    )

  return(result)

}
