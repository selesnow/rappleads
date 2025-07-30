#' Get Me Details
#'
#' @returns list with userId and parentOrgId
#' @export
#'
apl_get_me_details <- function() {

  resp <- request("https://api.searchads.apple.com/api/v5/me") %>%
    req_headers(
      Authorization = paste("Bearer", apl_auth())
    ) %>%
    req_perform()

  result <- resp_body_json(resp)$data

  return(result)

}
