---
title: "Untitled"
output: github_document
---

# EDD

## About EDD

EDD (Economic Data Dashboard) is an R package with an integrated [Shiny](https://shiny.rstudio.com/) app. Much of the functionality of the R package is specifically designed to deliver the Shiny app, but many of the additional included functions will be useful to economists and analysts in their routine work, and there are many others designed to be used outside of the Shiny app itself in an interactive environment.

The EDD Shiny app is hosted at <https://economic-analytics.shinyapps.io/edd-app,> and can be launched from an interactive R session by calling `edd::launch_edd()`.

## Data model

Built in R with front end UI in Shiny (Bootstrap), EDD is designed to not be reliant on external databases for data, instead using in-memory features of R (though v0.1 will migrate data storage to Parquet files).

Data is grouped into core datasets, most of which follow their designation from the Office for National Statistics or their publisher. These are named by their common abbreviations, where available, e.g. DIOP for Index of Production, DRSI for Retail Sales Index, MGDP for monthly GDP, etc. A full list of current and proposed datasets is available in the data section.

All data is first transformed into single flat tables (data frames), in normalised form (3NF, or Hadley Wickham's Tidy Data definition) to provide native integration in many of R and the Tidyverse's core packages.

### Dimensionality

Much economic data is highly dimensional, i.e. there are often many variables describing geography, industry, business size, legal structure, age, sex and many other characteristics. These are always returned in the EDD data model as columns for each dimension, regardless of the number of possible options for each dimension. This means that for each row in a table, there is only one measured (numerical) value; all other dimension data is returned as separate variables, including date.

### Dates

Dates are always stored as Date objects and returned in ISO8601 format (YYYY-MM-DD). To ensure that different frequencies of the same data are identifiable (e.g. much data is available as monthly, quarterly and annual series), there is a separate variable, `freq`, that holds a single character identifier ("m", "q", "a"), so that particular frequencies can be distinguished. Datasets contain mixed frequency data by design and are only separated into distinct frequency `data.frames` (actually `tsibble`s) at the point of any modelling or forecasting.

Dates are always stored as the first date in the period to which they refer, e.g. `"2020-01-01"` represents either January 2020, Q1 2020 or the whole of 2020 depending on the contents of `freq`, and `"2022-10-01"` represents either October 2022 or Q4 2022. There is an included function, `date_to_text()`, which translates a date in EDD's two-column format to a string, e.g.:

    date_to_text(data.frame(date = "2022-10-01", freq = "m"))

    #> "October 2022"

    dates <- data.frame(date = c("2022-07-01", "2022-10-01"), freq = rep("q", 2))
    date_to_text(dates)

    #> "Q3 2022" "Q4 2022"

Whilst maintaining data in a fully described "Tidy" format makes integration into common R packages simple, it provides a challenge in large datasets: high levels of duplication of dimensional data which occupies significant amounts of memory where datasets are particularly large and highly-dimensional. For this reason, before data flows to the processing engine, all datasets are transformed to fifth normal form (5NF) to remove all data redundancy and save memory.

### Example

| Date       | Geography Code | Geography Name | Industry Code | Industry Name | Variable      | Value |
|------------|----------------|----------------|---------------|---------------|---------------|-------|
| 2022-04-01 | E08000003      | Manchester     | C             | Construction  | GVA CVM Index | 101.5 |

For a large time series, with all local authorities (\> 300), SIC2007 Sectors (20) and a number of variables, the data redundancy becomes large. Data is further normalised to remove this:

| date       | geography_code | industry_code | variable      | value |
|------------|----------------|---------------|---------------|-------|
| 2022-04-01 | E08000003      | C             | GVA CVM Index | 101.5 |

: data `data.frame`

| geography_code | geography_name |
|----------------|----------------|
| E08000003      | Manchester     |

: geography `data.frame`

| industry_code | industry_name |
|---------------|---------------|
| C             | Construction  |

: industry `data.frame`

| variable_code | variable_name |
|---------------|---------------|
| GVA CVM Index | GVA CVM Index |

: variable `data.frame`

As well as reducing both storage space and memory usage, it also allows for lazy loading of the primary `data` table, as UI select boxes are populated from the dimension lookup tables which store only distinct values, reducing data transfer to the user.

As the user selects their dimension options, then the data table is filtered through a series of joins to each dimension table. This means the final data frame is built for UI analysis in 3NF ("tidy") contains only those rows requested by the user and minimises redundancy until the last moment.

### Nested data frame

R supports the use of nested data frames within data frames, i.e. a column of a data frame can be another data frame whose number of rows does not need to equal that of the parent (a key constraint on data frames). EDD utilises this to group together multiple columns that relate to the same variable, ensuring that all relevant information for any particular dimension is not separated from others. For example, in our initial 3NF data frame from above, the data is actually stored like this:

| dates\$date  | dates\$freq | geography\$code | geography\$name | industry\$code | industry\$name | variable\$code | variable\$name | value |
|--------------|-------------|-----------------|-----------------|----------------|----------------|----------------|----------------|-------|
| "2022-12-01" | "m"         | E08000003       | Manchester      | C              | Manufacturing  | GVA CVM Index  | GVA CVM Index  | 101.5 |

: Structure of `edd_list_df`

Notice that `value`, the only numeric-type variable in any EDD data frame, is the only "true" single variable column: the rest are all columns of data frames that themselves form columns in the "data" data frame. In R:

    dataset <- data.frame(dates     = data.frame(date, freq),
                          geography = data.frame(code, name),
                          industry  = data.frame(code, name),
                          variable  = data.frame(code, name, unit),
                          value)

Whilst R natively supports the above ideas, they are more easily expressed through the Tidyverse's `tibble` which is the implementation in EDD.

The advantage of this format is that all characteristics of all dimensions are easily passed around between functions as a single object by simply referring to the parent `data.frame`, e.g. `dataset$geography` or `dataset[["geography"]]` and all columns, regardless of their number, are always passed. This means it is easy to add additional, optional columns as appropriate to dimensions

Clearly with a large number of datasets, the number of subsidiary dimension lookup tables grows rapidly and may cause confusion. To address this, dimension lookup tables are connected to their parent data table by their inclusion in the same list.

    dataset <- list(
      data = tibble(dates = tibble(date, freq),
                    industry_code,
                    geography_code,
                    variable_code,
                    value),
      dimensions = list(
        geography = tibble(code, name, ...),
        industry  = tibble(code, name, ...),
        variable  = tibble(code, name, ...)
      )
    )

Utilising R `list` objects also allows additional metadata to be attached to datasets, e.g.:

    dataset[["meta"]] <- list(
      source = "Office for National Statistics",
      last_updated = "2022-11-15",
      next_updated = "2022-12-14"
    )

This standardised data architecture underpins the EDD model. It is not (yet) enforced through any OOP tooling, but effective constructor and verification functions (`as_edd_obj()`, `is_edd_obj()`) are available, as well as functions to return this model to 3NF (`edd_obj_to_edd_df()`) and vice versa (`df_to_edd_df()`, `edd_df_to_edd_obj()`).

### Object verification

Verification of the variety of different objects that EDD uses is undertaken through a set of `is_*()` functions that return a logical vector of length 1. `is_df()`, `is_edd_df()` and `is_edd_obj()` are the primary functions. Each of these objects is described in more detail here.

Class `edd_df` identifies a `data.frame` which has correctly named columns and can be transformed into other objects for use inside EDD. The rules that are tested to verify a class of `df` are:

-   existence of a column `date` in one of the below formats:

    -   `"2022"` (annual data)

    -   `"2022 Q4"`, `"Q4 2022"` (quarterly data)

    -   `"2022 Dec"`, `"2022 December"`, `"Dec 2022"`, `"December 2022"` (monthly data)

    -   ISO8601 (`"2022-12-02"`), though data frequency cannot be inferred and will need to be provided separately in a column, `freq`.

If none of these formats exist, EDD will prompt you for a format mask which you can also supply in the `date_parse_dates()` function's `format` argument.

\- existence of a column `value` which contains only numeric values (or values coercible to numeric)

\- existence of a column `variable` which contains only character values describing the value

This is the minimum acceptable `data.frame` that will verified with `is_edd_df()`.

Other columns can be added so long as they follow the EDD naming scheme:

### Object construction

Any flat CSV or Excel file can be passed to the constructor function as long as a number of conditions are met:

Compulsory fields:

Any CSV to be imported must contain, at a minimum, the following fields:

\* date

\* variable

\* value

This is the smallest amount of information that EDD requires to import your data. Case does not matter as all field names are converted to lower case at import.

If the data contains any dimensions, these should be in their own separate columns, e.g.

\`"date", "geography", "industry", "value"\`

If any dimension has more than one field associated with it, e.g. geography code, geography name, then these fields should be named in this way:

\`"geography_code", "geography_name"\`
