#' Apple Ads Authorization
#'
#' @param client_id You receive your clientId when you upload a public key.
#' @param team_id The client secret is a JWT that you create and sign with your private key.
#' @param key_id The value is your keyId that returns when you upload a public key.
#' @param private_key_path Path to the `.pem` file containing your private key.
#' @param account_name Your apple ads account name
#' @param cache_path Path to the directory where cached authentication data will be stored.
#'
#' @details
#' This implementation process guides you through the following steps:
#' 1. Invite users with API permissions.
#' 2. Generate a private-public key pair.
#' 3. Extract a public key from your persisted private key.
#' 4. Upload a public key.
#' 5. Set system environments variables.
#' 6. Request an access token.
#'
#' ## Generate a Private Key
#' API users need to create a private key. If you’re using MacOS or a UNIX-like operating system, OpenSSL works natively. If you’re on a Windows platform, you need to download [OpenSSL](https://www.openssl.org/).
#' `openssl ecparam -genkey -name prime256v1 -noout -out private-key.pem`
#'
#' ## Extract a Public Key
#' `openssl ec -in private-key.pem -pubout -out public-key.pem`
#' Open the public-key.pem file in a text editor and copy the public key, including the begin and end lines.
#'
#' ## Upload a Public Key
#' Follow these steps to upload your public key:
#' 1. From the Ads UI, choose Account Settings > API. Paste the key created in the above section into the Public Key field.
#' 2. Click Save. A group of credentials displays as a code block above the public key field. Use your clientId, teamId, and keyId to create a client secret.
#'
#' ## Set system environments variables
#' Run `usethis::edit_r_environ()` and set variables:
#' * APL_CLIENT_ID
#' * APL_TEAM_ID
#' * APL_KEY_ID
#' * APL_PRIVATE_KEY_PATH
#' * APL_ACCOUNT_NAME
#'
#' ## Request an access token.
#' Once the environment variables listed above are set, no further action is required from you — any function from the package will automatically request and refresh the access token when executed.
#'
#' For more information see [API Oauth documentation](https://developer.apple.com/documentation/apple_ads/implementing-oauth-for-the-apple-search-ads-api).
#'
#'
#' @returns character with access_token
#' @export
#'
apl_auth <- function(
    client_id        = Sys.getenv('APL_CLIENT_ID'),
    team_id          = Sys.getenv('APL_TEAM_ID'),
    key_id           = Sys.getenv('APL_KEY_ID'),
    private_key_path = Sys.getenv('APL_PRIVATE_KEY_PATH'),
    account_name     = Sys.getenv('APL_ACCOUNT_NAME'),
    cache_path       = rappdirs::site_data_dir("rappleads")
) {

  dir.create(cache_path, showWarnings = FALSE, recursive = TRUE)
  jwt_cache_file <- file.path(cache_path, paste0(account_name, "_jwt.rds"))
  access_token_file <- file.path(cache_path, paste0(account_name, "_access_token.rds"))

  # 1. JWT --------------------------------------------------
  jwt_data <- NULL
  if (file.exists(jwt_cache_file)) {
    jwt_data <- readRDS(jwt_cache_file)
    jwt_exp  <- as.POSIXct(jwt_data$exp, origin = "1970-01-01", tz = "UTC")

    # проверяем не просрочен ли client_secret
    if (difftime(jwt_exp, Sys.time(), units = "days") < 30) {
      jwt_data <- NULL  # просрочен
    }
  }

  if (is.null(jwt_data)) {

    jwt_data <- apl_get_client_secret(
      client_id        = client_id,
      team_id          = team_id,
      key_id           = key_id,
      private_key_path = private_key_path,
      account_name     = account_name,
      cache_path       = cache_path
    )

  }

  # 2. Access Token --------------------------------------------------
  token_data <- NULL
  if (file.exists(access_token_file)) {

    token_data <- readRDS(access_token_file)
    token_exp  <- as.POSIXct(token_data$created_at, origin = "1970-01-01", tz = "UTC") +
      as.difftime(token_data$expires_in, units = "secs")

    # проверяем не просрочен ли токен
    if (difftime(token_exp, Sys.time(), units = "mins") <= 15) {
      token_data <- NULL  # просрочен
    }

  }

  if (is.null(token_data)) {

    # === Запрашиваем access_token ===
    token_data <- apl_get_access_token(
      client_id    = client_id,
      jwt_data     = jwt_data,
      account_name = account_name,
      cache_path   = cache_path
    )
  }

  return(token_data$access_token)

}

#' Get client secret
#'
#' @param client_id You receive your clientId when you upload a public key.
#' @param team_id The client secret is a JWT that you create and sign with your private key.
#' @param key_id The value is your keyId that returns when you upload a public key.
#' @param private_key_path Path to the `.pem` file containing your private key.
#' @param account_name Your apple ads account name
#' @param cache_path Path to the directory where cached authentication data will be stored.
#'
#' @returns jwt_data
apl_get_client_secret <- function(
    client_id,
    team_id,
    key_id,
    private_key_path,
    account_name,
    cache_path = rappdirs::site_data_dir("rappleads")
) {

  dir.create(cache_path, showWarnings = FALSE, recursive = TRUE)
  jwt_cache_file <- file.path(cache_path, paste0(account_name, "_jwt.rds"))
  private_key <- read_key(private_key_path)
  iat <- as.integer(Sys.time())
  exp <- iat + 86400 * 180

  header <- list(
    alg = "ES256",
    kid = key_id
  )

  payload <- httr2::jwt_claim(
    sub = client_id,
    aud = "https://appleid.apple.com",
    iat = iat,
    exp = exp,
    iss = team_id
  )

  jwt <- httr2::jwt_encode_sig(payload, key = private_key, header = header)

  jwt_data <- list(jwt = jwt, exp = exp, iat = iat)
  saveRDS(jwt_data, jwt_cache_file)

  return(jwt_data)

}

#' Get access_token
#'
#' @param client_id You receive your clientId when you upload a public key.
#' @param jwt_data JWT object `apl_get_client_secret()`
#' @param account_name Your apple ads account name
#' @param cache_path Path to the directory where cached authentication data will be stored.
#'
#' @returns access_token object
apl_get_access_token <- function(
    client_id,
    jwt_data,
    account_name,
    cache_path = rappdirs::site_data_dir("rappleads")
) {

  dir.create(cache_path, showWarnings = FALSE, recursive = TRUE)
  access_token_file <- file.path(cache_path, paste0(account_name, "_access_token.rds"))

  resp <- request("https://appleid.apple.com/auth/oauth2/token") |>
    req_method("POST") |>
    req_headers(
      "Content-Type" = "application/x-www-form-urlencoded"
    ) |>
    req_body_form(
      grant_type    = "client_credentials",
      client_id     = client_id,
      client_secret = jwt_data$jwt,
      scope         = "searchadsorg"
    ) |>
    req_perform()

  # === Результат ===
  token_data <- resp |>
    resp_body_json()

  token_data$created_at <- as.integer(Sys.time())
  saveRDS(token_data, access_token_file)

  return(token_data)

}
