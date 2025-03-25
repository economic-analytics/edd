## Change log

### 2025-03-25 v0.0.0.9029
- Moves contents of change log and about to `markdown/*.md`
- Adds {markdown} to Imports

### 2025-03-21 v0.0.0.9028
- Add selected Bank of England database data to tool
- Add Bank of England Overnight Interest Rate Swap Futures Curve data

### 2025-01-22 v0.0.0.9027
- Reworking of data files to read all data from separate remote source
- This shrinks the core package size and separates front and back end
- Structure now fully reads from Arrow tables, importing only the data required

### 2024-03-20 v0.0.0.9026
- Add first version of place explorer tool
- Provides GVA(B) share and LQ analysis by ITL1/2/3

### 2024-03-18 v0.0.0.9025
- Change data back-end to parquet files with significant code re-write
- All regional datasets except regional GVA temporarily removed
- Add option to add LOESS smoothing overlay to charts
- Small visual improvements on some rendering options
- Data catalogue display updated

### 2023-09-07 v0.0.0.9024
- Update to R 4.3.1
- Add regional (LAD & ITL) productivity (GVA per filled job) data

### 2023-07-21 v0.0.0.9023
- Add code to data catalogue page

### 2023-04-03 v0.0.0.9022
- Add nominal, percentage and cumulative changes to time series transformation tool

### 2023-03-23 v0.0.0.9021
- UI tweak: changing main_panel to tabs from pills

### 2022-12-06 v0.0.0.9020
- Add changelog to app
- Add Blue Book, Business Investment, Labour Productivity, Quarterly National Accounts, Regional Productivity, Unit Labour Cost & Unit Wage Cost to available ONS datasets
- Add searchable data catalogue

### 2022-12-05 v0.0.0.9019
- Deploy bookmarking/persistent URLs to production
- UX improvements: add closing 'x' buttons to all dataset, variable and dimension labels
- Improve dynamic caption logic
- Removal of redundant code

### 2022-12-02 v0.0.0.9018
- Update deployment URL
- Workbench code for OOP creation, verification and coercion
- Add {lubridate} to Imports (date functions)

### 2022-12-01 v0.0.0.9017
- Add Regional Gross Disposable Household Income to data dictionary and include data in deployed app
- Improve functionality to convert data to `edd_obj`

### 2022-11-25 v0.0.0.9016
- Add initial bookmarking/persistent URL features

### 2022-11-24 v0.0.0.9015
- Add NOMIS clamaint count to data dictionary (for MSOA sub sites)
- Add `data_bres_add_emp_status_options()` which creates FTE and other employment totals
- Amend `add_hocl_msoa_names()` to use `geography_code` as `code_col` default
- Improve dynamic caption labels on plot

### 2022-11-23 v0.0.0.9014
- Remove non-vectorised `ons_parse_dates)` and implement a vectorised `date_text_to_df)`
- Add `message()` options to let users know that parsing dates can be slow
- Update `edd_dict` to add TEST lookup object
- Add new functions for parsing NOMIS csv files, converting these to `edd_df`, `edd_df` to `edd_obj`, generating dimension totals and adding hocl MSOA names to flat dfs

### 2022-11-17 v0.0.0.9013
- `ons_update_datasets()` now has `save_separate_rds = TRUE` fixes #13)
- File rename for clarity
- Comment and naming convention improvements
- Minor UI tweaks
- Update deployment URL

### 2022-11-16 v0.0.0.9012
- Remove redundant code
- Add linewrap to facet strips
- Add `nrow = 2` to legends
- Add {scales} for removal of scientific notation on y-axis of plot
- Amends to handle `y_axis_zero` and `scales::label_comma)` simultaneously
- Chart options UI improvements

### 2022-11-15 v0.0.0.9011
- Full rebuild of plot aesthetic mapping tools, logic and UI
- Improve dynamic y-axis label logic
- Add user option to force y-axis to zero

### 2022-11-14 v0.0.0.9010
- Add dynamic y-axis labelling to plot to handle when data is manually indexed

### 2022-11-11 v0.0.0.9009
- Update naming conventions throughout to EDD
- Add `dir.exists()` check for separate ONS dataset rds file writes
- Change default plot and csv download file names to remove time (`:` not allowed in filenames)
- Improvements to global variable search (i.e. without selecting dataset first)
- Create dynamic data sources and add to plot caption

### 2022-11-09 v0.0.0.9008
- Change aesthetic mapping on charts to have facets as second option
- Force y-axis of plots to be zero if `min(value) > 0`

### 2022-11-08 v0.0.0.9007
- Change event listeners on input dimensions to be dynamic
- Increase chart font sizes

### 2022-11-07 v0.0.0.9006
- Amends to ensure `selectInput()` choices always utilise `<optgroup>` by coercing to a list to handle single item lists
- Add ONS House Price Statistics for Small Areas MSOA median) HPSSA2) to data dictionary
- Add ONS Small Area Population Estimates SAPE) to data dictionary

### 2022-10-31 v0.0.0.9005
- Rebrand from EDDIE to EDD
- Improve automatic allocation of dimensions to plot aesthetics
- Fully implement data load from RDS files in `data/datasets`
- `ons_post_processing()` removed as nesting additional list - added to issues #19

### 2022-10-28 v0.0.0.9004
- Some amendments to structures to allow for forking of main repo to generate a subsites
- Improve file path generation so now non-Windows dependent
- Change dataset load to read all available RDS files in a single directory rather than from data dictionary
- UX improved by removing error messages by insertion of `req()` calls

### 2022-09-12 v0.0.0.9003
- Reinstate `ons_post_processing()` call
- Minor changes to server.R on permanent dimensions
- Brand update to EDDIE
- RGDHI local file location updated

### 2022-09-02 v0.0.0.9002
- Add ONS Regional Gross Disposable Household Income parsing script
- Add ONS Regional Gross Value Added (local authority districts) parsing script
- Update ONS Regional Gross Value Added parsing script to deal with ITL regions instead of NUTS
- Add `utils-df-to-fedobj()` script to improve data processing
- Add `utils-tidy-excel-headers.R` with `merge_column_names()` function to clean Excel files with merged cell and multiple row headers
- Improve parsing of text format dates
- Improve dynamic allocation of dimensions to plot aesthetics
- Temporarily remove `ons_post_processing()` call to change ONS datasets back to original formats

### 2022-05-18 v0.0.0.9001
- Update magrittr pipe (`%>%`) to base R pipe (`|>`)
- Update Depends to R >= 4.2

### 2022-01-08 v0.0.0.9000
- Initial ALPHA commit
- Add ONS Regional Gross Fixed Capital Formation