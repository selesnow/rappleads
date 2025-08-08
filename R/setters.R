#' Set Tinezone
#'
#' @param timezone You set the default timeZone during account creation through the Apple Search Ads UI. ORTZ (organization time zone) is the default. Possible Values: ORTZ, UTC
#'
#' @returns nothing
#' @export
#'
apl_set_timezone <- function(timezone) {
  options(apl.api_version = timezone)
}

#' Set Client ID
#'
#' @param client_id You receive your clientId when you upload a public key.
#'
#' @returns nothing
#' @export
#'
apl_set_client_id <- function(client_id) {
  Sys.setenv('APL_CLIENT_ID' = client_id)
}

#' Set Team ID
#'
#' @param team_id The client secret is a JWT that you create and sign with your private key.
#'
#' @returns nothing
#' @export
#'
apl_set_team_id <- function(team_id) {
  Sys.setenv('APL_TEAM_ID' = team_id)
}

#' Set KeyID
#'
#' @param key_id The value is your keyId that returns when you upload a public key.
#'
#' @returns nothing
#' @export
#'
apl_set_key_id <- function(key_id) {
  Sys.setenv('APL_KEY_ID' = key_id)
}

#' Set Privat Key Path
#'
#' @param private_key_path Path to the `.pem` file containing your private key.
#'
#' @returns nothing
#' @export
#'
apl_set_private_key_path <- function(private_key_path) {
  Sys.setenv('APL_PRIVATE_KEY_PATH' = private_key_path)
}

#' Set Apple Ads Account Name
#'
#' @param account_name Your apple ads account name
#'
#' @returns nothing
#' @export
#'
apl_set_account_name <- function(account_name) {
  Sys.setenv('APL_ACCOUNT_NAME' = account_name)
}

#' Get List of Auth Cached Accounts
#'
#' @returns character vector with accounts name
#' @export
#'
apl_get_auth_account_list <- function() {

  dir(rappdirs::site_data_dir("rappleads")) %>%
    stringr::str_remove_all('_jwt.rds|_access_token.rds|_client_credential.yml') %>%
    unique()

}
