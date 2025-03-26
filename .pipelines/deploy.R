# .libPaths("/usr/local/lib/R/site-library")

# use renv to detect and install required packages.
# if (file.exists("renv.lock")) {
#   renv::restore(prompt = FALSE)
# } else {
#   renv::hydrate()
# }

# required inputs
accountName <- Sys.getenv("SHINYAPPS_ACCOUNT")
accountToken <- Sys.getenv("SHINYAPPS_TOKEN")
accountSecret <- Sys.getenv("SHINYAPPS_SECRET")
appDir <- Sys.getenv("GITHUB_WORKSPACE")

# set up account
cat("checking account info...")
rsconnect::setAccountInfo(accountName, accountToken, accountSecret)
cat(" [OK]\n")

# deploy application
rsconnect::deployApp(
  appDir = appDir,
  appName = 'edd-app',
  account = accountName,
  forceUpdate = TRUE
)