library(dplyr)
library(gtsummary)
library(gt)
library(here)

data <- readRDS("demographics.RDS")


label_list <- list(
  agegp = "Age group (years)",
  sex = "Sex",
  lti = "Long-term illness",
  hcon_livn = "Household size",
  lives_kid = "Lives with children",
  lives_eld = "Lives with elderly",
  wcc = "Contact with patients"  
)

Table_1_A <- data %>%
  tbl_summary(
    include = c(agegp, sex, lti, hcon_livn, lives_kid, lives_eld, wcc),
    by = site,
    label = label_list,
    type = list(
      lives_kid ~ "categorical",
      lives_eld ~ "categorical",
      lti ~ "categorical"

    ),
    missing_text = "No response"
  ) %>%
  add_p() %>%
  remove_footnote_header()

Table_1_B <- data %>%
  tbl_summary(
    include = c(agegp, sex, lti, hcon_livn, lives_kid, lives_eld, wcc),
    label = label_list,
    type = list(
      lives_kid ~ "categorical",
      lives_eld ~ "categorical",
      lti ~ "categorical"
    ),
    missing_text = "No response"
  )

Table_1_C <- data %>%
  tbl_uvregression(
    include = c(agegp, sex, lti, hcon_livn, lives_kid, lives_eld, wcc),
    y = flu_uptake,
    method = glm,
    method.args = list(family = binomial),
    exponentiate = TRUE,
    label = label_list,
    pvalue_fun = ~style_pvalue(.x, digits = 3)
  ) %>%
  add_global_p()

Table_1 <- tbl_merge(
  tbls = list(Table_1_A, Table_1_B, Table_1_C),
  tab_spanner = FALSE
) %>%
  as_gt() %>%
  tab_options(data_row.padding = px(1)) %>%
  opt_table_font(font = "serif")

gt::gtsave(
  Table_1,
  filename = here("Table 1.html")
)