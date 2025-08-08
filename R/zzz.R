.onLoad <- function(libname, pkgname) {

  # options
  op <- options()
  op.gads <- list(C   = 'ORTZ',
                  apl.api_version = 'v5')

  toset <- !(names(op.gads) %in% names(op))
  if (any(toset)) options(op.gads[toset])

  invisible()
}

.onAttach <- function(lib, pkg,...){

  packageStartupMessage(rappleadsWelcomeMessage())

}


rappleadsWelcomeMessage <- function(){
  # library(utils)

  paste0("\n",
         "---------------------\n",
         "Welcome to rappleads version ", utils::packageDescription("rappleads")$Version, "\n",
         "\n",
         "Author:           Alexey Seleznev (Head of analytics dept at Netpeak).\n",
         "Telegram channel: https://t.me/R4marketing \n",
         "YouTube channel:  https://www.youtube.com/R4marketing/?sub_confirmation=1 \n",
         "Email:            selesnow@gmail.com\n",
         "Site:             https://selesnow.github.io \n",
         "Blog:             https://alexeyseleznev.wordpress.com \n",
         "Facebook:         https://facebook.com/selesnown \n",
         "Linkedin:         https://www.linkedin.com/in/selesnow \n",
         "\n",
         "Using Googla Ads API version: ", getOption('gads.api.version'), "\n",
         "\n",
         "Type ?rappleads for the main documentation.\n",
         "The github page is: https://github.com/selesnow/rappleads/\n",
         "Package site: https://selesnow.github.io/rappleads/docs\n",
         "\n",
         "Suggestions and bug-reports can be submitted at: https://github.com/selesnow/rappleads/issues\n",
         "Or contact: <selesnow@gmail.com>\n",
         "\n",
         "\tTo suppress this message use:  ", "suppressPackageStartupMessages(library(rappleads))\n",
         "---------------------\n"
  )
}
