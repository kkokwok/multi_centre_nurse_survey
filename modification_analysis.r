rm(list = ls())

###########################################################################
# Moderation / main-effect analyses: trust in information sources, 5C     #
# psychological antecedents and influenza vaccination uptake              #
#                                                                         #
# Input : path_modification_analysis.RDS (analysis-specific dataset; place it   #
#         in the project root, i.e. the same folder as this script)       #
# Output: HTML tables saved in Results/Moderation/                        #
###########################################################################

library(tidyr)
library(gtsummary)
library(gt)
library(dplyr)
library(here)

# -------------------------------------------------------------------------
# Load data
# (record exclusions and derived variables were already applied when the
#  analysis dataset was created; no participant identifier is included)
# -------------------------------------------------------------------------

data <- readRDS("path_modification_analysis.RDS")

# Output folder
out_dir <- here("Results", "Moderation")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


data <- readRDS("path_modification_analysis.RDS")
# Quick check of the dataset
str(data)
summary(data)


# -------------------------------------------------------------------------
# Variable definitions
# -------------------------------------------------------------------------

# Vaccine hesitancy (5C) vars
vh_vars <- c("Confidence"="vh_conf",
             "Complacency"="vh_comp",
             "Constraints"="vh_cons",
             "Calculation"="vh_calc",
             "Collective responsibility"="vh_coll")

# Trust vars (continuous)
tr_vars <- c("Govt. websites"="tr_gw",
             "Social media"="tr_sm",
             "AI chatbots"="tr_ai",
             "Family doctor"="tr_fd",
             "Family_friends"="tr_ff")

# Trust vars (categorised)
tr_vars3 <- c("Govt. websites"="tr_gw3",
              "Social media"="tr_sm3",
              "AI chatbots"="tr_ai3",
              "Family doctor"="tr_fd3",
              "Family_friends"="tr_ff3")

# Labels used in the tables
label_list <- list(
  agegp="Age group (yrs)",
  sex="Sex",
  lti="Long-term illness",
  site="Site",
  tr_gw3="Trust",
  tr_sm3="Trust",
  tr_ai3="Trust",
  tr_fd3="Trust",
  tr_ff3="Trust",
  vh_conf="Confidence",
  vh_comp="Complacency",
  vh_cons="Constraints",
  vh_calc="Calculation",
  vh_coll="Collective responsibility",
  flu_uptake="Influenza uptake"
)

# Check sample sizes of the trust categories by site
split(data, ~site) %>%
  lapply(\(x) count(x, tr_sm3))


###########################################################################
# Suppl table S2A to S2E : Modification analysis for COMBINED dataset     #
###########################################################################

# Core covariates (site is adjusted for in the combined dataset)
core_vars_3 <- c("agegp", "sex", "lti", "site")

# Loop through the trust variables
models <- lapply(tr_vars3, \(tr) {

  # Loop through the 5C variables (trust interacting with each one)
  lapply(vh_vars, \(vh) {

    DATA <- select(data, flu_uptake, all_of(core_vars_3), all_of(tr), all_of(unname(vh_vars))) %>%
      drop_na()

    core <- paste(core_vars_3, collapse = " + ")
    form <- formula(paste0("flu_uptake ~ ", core, " + ", tr, " * ", vh,
                           " + vh_comp + vh_conf + vh_cons + vh_calc + vh_coll"))

    glm(form, data=DATA, family=binomial)
  })
})

lapply(models, \(tr) {

  tbls <- lapply(tr, \(m) {
    X <- tbl_regression(m, exponentiate=TRUE, label=label_list)
    VH <- sub("tr_[a-z]+3\\:(vh_c.+)", "\\1", tail(attr(m$terms, "term.labels"), 1))
    vh_name <- names(vh_vars[match(VH, vh_vars)])
    modify_table_body(X, ~ .x %>%
                        mutate(variable=if_else(grepl(":", variable), "Interaction", variable),
                               label=case_when(grepl("Trust \\* ", label)~"Trust:5C",
                                               grepl("Moderate \\* ", label)~"Moderate",
                                               grepl("High \\* ", label)~"High",
                                               .default=label))) %>%
      modify_spanning_header(c(estimate, conf.low, p.value) ~ paste0("**", vh_name, "**"))
  })

  # Trust variable is the 6th column of the model data
  # (flu_uptake, agegp, sex, lti, site, trust, ...)
  Trust <- names(tr_vars3[match(names(tr$Confidence$data)[6], tr_vars3)])

  tbl_merge(tbls, merge_vars = c("variable", "row_type", "label"),
            tab_spanner = names(vh_vars)) %>%

    # Styling
    as_gt() |>
    tab_options(data_row.padding = px(1)) |>
    opt_table_font(font = "serif", size=12) |>

    # Save results to an html file, which can be opened in Excel or any browser
    gt::gtsave(filename=file.path(out_dir, paste0("Mod3_", Trust, "_final.html")))
})


###########################################################################
# Suppl table S4A to S4E : Modification analysis for BRN dataset          #
###########################################################################

# Site-specific analyses: site is no longer a covariate
core_vars_3 <- c("agegp", "sex", "lti")

models <- lapply(tr_vars3, \(tr) {

  # Loop through the 5C variables (trust interacting with each one)
  lapply(vh_vars, \(vh) {

    DATA <- filter(data, site=="BRN") %>%
      select(flu_uptake, all_of(core_vars_3), all_of(tr), all_of(unname(vh_vars))) %>%
      drop_na()

    core <- paste(core_vars_3, collapse = " + ")
    form <- formula(paste0("flu_uptake ~ ", core, " + ", tr, " * ", vh,
                           " + vh_comp + vh_conf + vh_cons + vh_calc + vh_coll"))

    glm(form, data=DATA, family=binomial)
  })
})

lapply(models, \(tr) {

  tbls <- lapply(tr, \(m) {
    X <- tbl_regression(m, exponentiate=TRUE, label=label_list)
    VH <- sub("tr_[a-z]+3\\:(vh_c.+)", "\\1", tail(attr(m$terms, "term.labels"), 1))
    vh_name <- names(vh_vars[match(VH, vh_vars)])
    modify_table_body(X, ~ .x %>%
                        mutate(variable=if_else(grepl(":", variable), "Interaction", variable),
                               label=case_when(grepl("Trust \\* ", label)~"Trust:5C",
                                               grepl("Moderate \\* ", label)~"Moderate",
                                               grepl("High \\* ", label)~"High",
                                               .default=label))) %>%
      modify_spanning_header(c(estimate, conf.low, p.value) ~ paste0("**", vh_name, "**"))
  })

  # Trust variable is the 5th column of the model data
  # (flu_uptake, agegp, sex, lti, trust, ...)
  Trust <- names(tr_vars3[match(names(tr$Confidence$data)[5], tr_vars3)])

  tbl_merge(tbls, merge_vars = c("variable", "row_type", "label"),
            tab_spanner = names(vh_vars)) %>%

    # Styling
    as_gt() |>
    tab_options(data_row.padding = px(1)) |>
    opt_table_font(font = "serif", size=12) |>

    gt::gtsave(filename=file.path(out_dir, paste0("Mod3_", Trust, "_BRN.html")))
})


###########################################################################
# Suppl table S5A to S5E : Modification analysis for HKG dataset          #
# (except calculation model)                                              #
###########################################################################

core_vars_3 <- c("agegp", "sex", "lti")

models <- lapply(tr_vars3, \(tr) {

  # Loop through the 5C variables (trust interacting with each one)
  lapply(vh_vars, \(vh) {

    DATA <- filter(data, site=="HKG") %>%
      select(flu_uptake, all_of(core_vars_3), all_of(tr), all_of(unname(vh_vars))) %>%
      drop_na()

    core <- paste(core_vars_3, collapse = " + ")
    form <- formula(paste0("flu_uptake ~ ", core, " + ", tr, " * ", vh,
                           " + vh_comp + vh_conf + vh_cons + vh_calc + vh_coll"))

    glm(form, data=DATA, family=binomial)
  })
})

lapply(models, \(tr) {

  tbls <- lapply(tr, \(m) {
    X <- tbl_regression(m, exponentiate=TRUE, label=label_list)
    VH <- sub("tr_[a-z]+3\\:(vh_c.+)", "\\1", tail(attr(m$terms, "term.labels"), 1))
    vh_name <- names(vh_vars[match(VH, vh_vars)])
    modify_table_body(X, ~ .x %>%
                        mutate(variable=if_else(grepl(":", variable), "Interaction", variable),
                               label=case_when(grepl("Trust \\* ", label)~"Trust:5C",
                                               grepl("Moderate \\* ", label)~"Moderate",
                                               grepl("High \\* ", label)~"High",
                                               .default=label))) %>%
      modify_spanning_header(c(estimate, conf.low, p.value) ~ paste0("**", vh_name, "**"))
  })

  Trust <- names(tr_vars3[match(names(tr$Confidence$data)[5], tr_vars3)])

  tbl_merge(tbls, merge_vars = c("variable", "row_type", "label"),
            tab_spanner = names(vh_vars)) %>%

    # Styling
    as_gt() |>
    tab_options(data_row.padding = px(1)) |>
    opt_table_font(font = "serif", size=12) |>

    gt::gtsave(filename=file.path(out_dir, paste0("Mod3_", Trust, "_HKG.html")))
})


###########################################################################
# Suppl table S5A to S5E : Modification analysis for HKG dataset          #
# (calculation model only; calculation grouped into 3 categories due to   #
#  small sample sizes, variable vh_calc4)                                 #
###########################################################################

# Separate objects are used here so that vh_vars / label_list above
# are not overwritten (they are needed again in the SGP section)
vh_vars_calc <- c("Confidence"="vh_conf",
                  "Complacency"="vh_comp",
                  "Constraints"="vh_cons",
                  "Calculation"="vh_calc4",
                  "Collective responsibility"="vh_coll")

label_list_calc <- list(
  agegp="Age group (yrs)",
  sex="Sex",
  lti="Long-term illness",
  site="Site",
  tr_gw3="Trust",
  tr_sm3="Trust",
  tr_ai3="Trust",
  tr_fd3="Trust",
  tr_ff3="Trust",
  vh_conf="Confidence",
  vh_comp="Complacency",
  vh_cons="Constraints",
  vh_calc="Calculation",
  vh_calc4="Calculation gp",
  vh_coll="Collective responsibility",
  flu_uptake="Influenza uptake"
)

core_vars_3 <- c("agegp", "sex", "lti")

DATA <- filter(data, site=="HKG") %>%
  select(flu_uptake, all_of(core_vars_3), all_of(unname(tr_vars)), all_of(unname(vh_vars_calc))) %>%
  drop_na()

models <- lapply(tr_vars, \(tr) {

  # Trust (continuous) interacting with grouped calculation (vh_calc4)
  core <- paste(core_vars_3, collapse = " + ")
  form <- formula(paste0("flu_uptake ~ ", core, " + ", tr,
                         " * vh_calc4 + vh_comp + vh_conf + vh_cons + vh_coll"))

  glm(form, data=DATA, family=binomial)
})

tbls <- lapply(models, \(m) {
  X <- tbl_regression(m, exponentiate=TRUE, label=label_list_calc)
  VH <- sub("tr_[a-z]+3\\:(vh_c.+)", "\\1", tail(attr(m$terms, "term.labels"), 1))
  vh_name <- names(vh_vars_calc[match(VH, vh_vars_calc)])
  modify_table_body(X, ~ .x %>%
                      mutate(variable=if_else(grepl("^tr_..$", variable), "Trust",
                                              if_else(grepl("^tr_..", variable), sub("tr_..", "Trust", label), variable)),
                             label=if_else(grepl("^tr_..$", label), "Trust",
                                           if_else(grepl("^tr_", label), sub("tr_..", "Trust", label), label))
                      )) %>%
    modify_spanning_header(c(estimate, conf.low, p.value) ~ paste0("**", vh_name, "**"))
})

tbl_merge(tbls, merge_vars = c("variable", "row_type", "label"),
          tab_spanner = names(tr_vars3)) %>%

  # Styling
  as_gt() |>
  tab_options(data_row.padding = px(1)) |>
  opt_table_font(font = "serif", size=12) |>

  gt::gtsave(filename=file.path(out_dir, "Mod3_Calculation_HKG.html"))


###########################################################################
# Suppl table S8 : Main effect model for SGP dataset                      #
###########################################################################

core_vars_3 <- c("agegp", "sex", "lti")

# Loop through the trust variables
models <- lapply(tr_vars3, \(tr) {

  DATA <- filter(data, site=="SGP") %>%
    select(flu_uptake, all_of(core_vars_3), all_of(tr), all_of(unname(vh_vars))) %>%
    drop_na()

  core <- paste(core_vars_3, collapse = " + ")
  form <- formula(paste0("flu_uptake ~ ", core, " + ", tr,
                         " + vh_comp + vh_conf + vh_cons + vh_calc + vh_coll"))

  glm(form, data=DATA, family=binomial)
})

tbls <- lapply(models, \(m) {
  tbl_regression(m, exponentiate=TRUE, label=label_list)
})

tbl_merge(tbls,
          tab_spanner = names(tr_vars3)) %>%

  # Styling
  as_gt() |>
  tab_options(data_row.padding = px(1)) |>
  opt_table_font(font = "serif", size=12) |>

  gt::gtsave(filename=file.path(out_dir, "Mod3_SGP.html"))
