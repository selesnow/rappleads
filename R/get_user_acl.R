#' Get User Access Control List
#'
#' @returns tibble
#' @export
#'
get_user_acl <- function() {

  resp <- request("https://api.searchads.apple.com/api/v5/acls") %>%
    req_headers(
      Authorization = paste("Bearer", apl_auth())
    ) %>%
    req_perform()

  result <- resp %>%  resp_body_json()

  result <- tibble(data = result$data) %>%
            unnest_wider(data) %>%
            rename_with(.fn = to_snake_case)

  return(result)

}
