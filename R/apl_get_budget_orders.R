#' Get All Budget Orders
#'
#' @param org_id The value is your orgId.
#'
#' @returns tibble with budget data
#' @export
#'
apl_get_budget_orders <- function(org_id = apl_get_me_details()$parentOrgId) {

  result <- apl_make_request(
    endpoint = 'budgetorders',
    org_id   = org_id,
    parser   = apl_parsers$simple
  )

  return(result)

}
