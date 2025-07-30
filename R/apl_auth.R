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

  payload <- jose::jwt_claim(
    sub = client_id,
    aud = "https://appleid.apple.com",
    iat = iat,
    exp = exp,
    iss = team_id
  )

  jwt <- jwt_encode_sig(payload, key = private_key, header = header)

  jwt_data <- list(jwt = jwt, exp = exp, iat = iat)
  saveRDS(jwt_data, jwt_cache_file)

  return(jwt_data)

}

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
