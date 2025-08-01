#' Get User Access Control List
#'
#' @returns tibble
#' @export
#'
apl_get_user_acl <- function() {

  result <- apl_make_request(
    endpoint = 'acls',
    parser   = apl_parsers$user_acl_parser
  )

  return(result)

}
