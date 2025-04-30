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

# define files to upload
appFiles <- list.files(
  path = c(
    "markdown",
    "R",
    "renv",
    "rsconnect/shinyapps.io/economic-analytics"
  ),
  full.names = TRUE
)

appFiles <- c(
  ".Rprofile",
  "app.R",
  "DESCRIPTION",
  "NAMESPACE",
  "renv.lock",
  appFiles
)

# deploy application
rsconnect::deployApp(
  appDir = appDir,
  appFiles = appFiles,
  appName = "edd-app",
  appFiles = appFiles,
  appName = "edd-app",
  account = accountName,
  forceUpdate = TRUE
)