

get_user_acl <- function(access_token) {
  resp <- request("https://api.searchads.apple.com/api/v5/acls") %>%
    req_headers(
      Authorization = paste("Bearer", apl_auth())
    ) %>%
    req_perform()

  result <- resp |> resp_body_json()

  result <- tibble(data = result$data) %>%
            unnest_wider(data)


}
