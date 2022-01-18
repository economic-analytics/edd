<!-- badges: start -->

<!-- badges: end -->

# FEDO: Future Economies Data Observatory

## About

### FEDO
The Future Economies Data Observatory (FEDO) houses thousands of variables from hundreds of data sets of secondary and administrative data for multiple geographies within the United Kingdom.

It seeks to simplify the access, interrogation, visualisation and communication of complex data sources to accelerate research for policy design and evaluation. 

### Future Economies
[Future Economies](https://www.mmu.ac.uk/future-economies/) is a University Centre for Research & Knowledge Exchange at [Manchester Metropolitan University](http://mmu.ac.uk). It encompasses a number of separate knowledge platforms that collectively address the question

> "What should policy makers, business and civil society do to build the economy of the future?"

The knowledge platforms are:

* Manchester Centre for Economic Policy
* Future Economies Analytics
* Applied Economics
* Visitor Economies and Development
* Sports Policy
* Centre for Policy Modelling

### Future Economies Analytics
Future Economies Analytics is a dedicated economic data science, analytics and visualisation unit within the wider Future Economies UCRKE. Its members both develop and use a variety of tools to improve research in and communication of key economic trends as well as providing teaching in data analytics and visualisation and research support in RSE roles to other academics.

## Background
The main author of FEDO has spent more than a decade working in regional economic policy and data analysis and became frustrated at how long it took to assemble economic data from various sources and produce even simple analyses. Different sources routinely use different date formats, non-standard geographic codes, different index dates and often have dimensions of the data stored in variable names. FEDO seeks to simplify the analysis of economic data by providing a single interactive web-platform where economic data, through pre-processing, is available for easy charting with dimensions, dates, geographies and variable names are standardised, allowing for the viewing of data quickly and downloading both charts and raw data tables in a standardised format.

## Data

## Technical information

Built in R, FEDO utilises the web architecture of the `shiny` package, visualisation from `ggplot2`, alongside backend storage in SQL Server with data transfer handled natively within `dbplyr`.

## Data model

At the heart of FEDO is a bespoke and flexible data structure that allows for dynamic realisation of datasets regardless of the number of dimensions within the data, different geography types, industry breakdowns, etc.

The data storage model is based on [Tidy Data](https://vita.had.co.nz/papers/tidy-data.html) principles and utilises R lists to provide rapid iteration of filtering and manipulation through functional programming. Data is manipulated in R and stored in both `.rds` format and also copied to and retrieved from a SQL Server database to reduce memory use. More information on the underlying data schema will be available shortly.

## Using FEDO

The FEDO app is currently deployed at https://futureeconomiesanalytics.shinyapps.io/fedo/.
