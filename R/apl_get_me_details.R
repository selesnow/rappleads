#' Get Me Details
#'
#' @returns list with userId and parentOrgId
#' @export
#'
apl_get_me_details <- function() {

  result <- apl_make_request(
    endpoint = 'me',
    parser   = apl_parsers$simple
  )

  return(result)

}
