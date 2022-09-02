fedobj <- structure(data.frame(
  dates =
))


setClass("fedobj", slots = c(data = "data.frame"))
getClass("fedobj")


setClass("fedobj",
         slots = c(data = "data.frame",
                   dimensions = "data.frame",
                   meta = "data.frame"),
         contains = "data.frame"
)

fo <- new("fedobj")



setClass("EddieData",
         slots = c(date = "character",
                   variable = "character",
                   value = "numeric"),
         contains = "data.frame")

setClass("EddieDataGeog",
         slots = c(geography.code = "character",
                   geography.name = "character"),
         contains = "EddieData")
