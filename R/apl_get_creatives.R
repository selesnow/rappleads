#' Get All Creatives
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with campaigns
#' @export
#'
apl_get_creatives <- function(org_id = apl_get_me_details()$parentOrgId) {

  result <- apl_make_request(
    endpoint = 'creatives',
    org_id   = org_id,
    parser   = apl_parsers$creatives
  )

  return(result)

}
