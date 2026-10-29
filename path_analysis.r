rm(list = ls())

###################################################################
# SUPP TABLE 3
# PATH ANALYSIS: TRUST CHANNELS -> 5C -> VACCINATION
#
# Public script: reads only path_modification_analysis.RDS.
# The public RDS already contains the prespecified analytical sample,
# derived trust variables, and only variables required for the analyses.
# No participant identifier is required or used in this script.
###################################################################

library(boot)
library(dplyr)
library(tidyr)
library(tibble)
library(openxlsx)
library(gt)

############################################################
# SETTINGS
############################################################

# Use 500 for a test run and 5000 for final results.
R_BOOT <- 5000

out_dir <- "./Results/Path_analysis/"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

############################################################
# LOAD ANALYSIS-SPECIFIC DATA
############################################################

data <- readRDS(
  "path_modification_analysis.RDS"
)

# Explicit whitelist of variables required by this script.
required_variables <- c(
  "agegp", "sex", "lti", "site",
  "tr_gw3", "tr_sm3", "tr_ai3", "tr_fd3", "tr_ff3",
  "tr_gw", "tr_sm", "tr_ai", "tr_fd", "tr_ff",
  "vh_conf", "vh_comp", "vh_cons", "vh_calc", "vh_coll",
  "flu_uptake"
)

missing_variables <- setdiff(required_variables, names(data))
if (length(missing_variables) > 0) {
  stop(
    paste0(
      "The following required variables are missing: ",
      paste(missing_variables, collapse = ", ")
    )
  )
}

data <- data %>%
  select(all_of(required_variables)) %>%
  mutate(
    site = factor(site, levels = c("BRN", "HKG", "SGP")),
    flu_uptake_bin = case_when(
      flu_uptake == "Received" ~ 1,
      is.na(flu_uptake) ~ NA_real_,
      TRUE ~ 0
    )
  )

# Safety checks.
stopifnot(!"id" %in% names(data))
stopifnot(setequal(names(data), c(required_variables, "flu_uptake_bin")))

############################################################
# PATH-ANALYSIS VARIABLES AND LABELS
############################################################

trust_vars <- c(
  "tr_gw3", "tr_fd3", "tr_ff3", "tr_ai3", "tr_sm3"
)

mediators <- c(
  "vh_conf", "vh_comp", "vh_cons", "vh_calc", "vh_coll"
)

for (v in trust_vars) {
  data[[v]] <- factor(data[[v]], levels = c("Low", "Moderate", "High"))
}

trust_labels <- c(
  tr_gw3 = "Government website",
  tr_fd3 = "Family doctor",
  tr_ff3 = "Family & friends",
  tr_ai3 = "AI chatbot",
  tr_sm3 = "Social media"
)

mediator_labels <- c(
  vh_conf = "Confidence",
  vh_comp = "Complacency",
  vh_cons = "Constraints",
  vh_calc = "Calculation",
  vh_coll = "Collective responsibility"
)

format_beta <- function(estimate, lower, upper, sig) {
  out <- paste0(
    sprintf("%.3f", estimate), " (",
    sprintf("%.3f", lower), ", ",
    sprintf("%.3f", upper), ")"
  )
  ifelse(sig == "Yes", paste0("**", out, "**"), out)
}

format_aor <- function(estimate, lower, upper, sig) {
  out <- paste0(
    sprintf("%.2f", estimate), " (",
    sprintf("%.2f", lower), ", ",
    sprintf("%.2f", upper), ")"
  )
  ifelse(sig == "Yes", paste0("**", out, "**"), out)
}

clean_term_label <- function(term, trust_var, mediator_var) {
  out <- term
  out <- gsub("^agegp", "Age group: ", out)
  out <- gsub("^sex", "Sex: ", out)
  out <- gsub("^lti", "Long-term illness: ", out)
  out <- gsub("^site", "Site: ", out)
  out <- gsub(paste0("^", trust_var), "Trust: ", out)
  out <- gsub(
    paste0("^", mediator_var, "$"),
    paste0("5C construct: ", mediator_labels[mediator_var]),
    out
  )
  out <- gsub("Moderate", "Moderate vs Low", out)
  out <- gsub("High", "High vs Low", out)
  out <- gsub("Male", "Male vs Female", out)
  out <- gsub("Yes", "Yes vs No", out)
  out
}

get_boot_ci <- function(bt, index) {
  out <- tryCatch(
    {
      ci <- boot.ci(bt, type = "bca", index = index)
      ci$bca[4:5]
    },
    error = function(e) {
      quantile(
        bt$t[, index],
        probs = c(0.025, 0.975),
        na.rm = TRUE
      )
    }
  )
  as.numeric(out)
}

get_coef_by_pattern <- function(coefs, pattern) {
  nm <- grep(pattern, names(coefs), value = TRUE)[1]
  if (length(nm) == 0 || is.na(nm)) return(NA_real_)
  unname(coefs[nm])
}

############################################################
# FUNCTION: ONE PATH ANALYSIS
############################################################

run_path_analysis <- function(
    data,
    trust_var,
    mediator_var,
    model_name,
    covariates,
    R_boot = 5000
) {
  med_formula <- as.formula(
    paste(mediator_var, "~", trust_var, "+", covariates)
  )

  out_formula <- as.formula(
    paste(
      "flu_uptake_bin ~", mediator_var, "+", trust_var, "+", covariates
    )
  )

  # Fit the two component models using the supplied analytical dataset.
  # Missing observations are handled by each model using R's default na.omit.
  m1 <- lm(med_formula, data = data)
  m2 <- glm(out_formula, family = binomial, data = data, y = TRUE)

  s1 <- summary(m1)
  f1 <- s1$fstatistic

  n_out <- nobs(m2)
  null_dev <- m2$null.deviance
  res_dev <- m2$deviance

  mcfadden <- 1 - res_dev / null_dev
  cox_snell <- 1 - exp((res_dev - null_dev) / n_out)
  nagelkerke <- cox_snell / (1 - exp(-null_dev / n_out))

  lr_chisq <- null_dev - res_dev
  lr_df <- m2$df.null - m2$df.residual
  lr_p <- pchisq(lr_chisq, lr_df, lower.tail = FALSE)

  y_obs <- m2$y
  p_hat <- fitted(m2)
  rk <- rank(p_hat)
  n1 <- sum(y_obs == 1)
  n0 <- sum(y_obs == 0)
  auc <- if (n1 > 0 && n0 > 0) {
    (sum(rk[y_obs == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
  } else {
    NA_real_
  }

  fit_row <- data.frame(
    Model = model_name,
    Trust_Label = unname(trust_labels[trust_var]),
    Mediator_Label = unname(mediator_labels[mediator_var]),
    Global_df = 0,
    N_mediator_model = nobs(m1),
    R2_mediator = s1$r.squared,
    Adj_R2_mediator = s1$adj.r.squared,
    F_p_mediator = unname(pf(f1[1], f1[2], f1[3], lower.tail = FALSE)),
    AIC_mediator = AIC(m1),
    BIC_mediator = BIC(m1),
    N_uptake_model = n_out,
    McFadden_R2 = mcfadden,
    Nagelkerke_R2 = nagelkerke,
    LR_chisq = lr_chisq,
    LR_df = lr_df,
    LR_p = lr_p,
    AUC = auc,
    AIC_uptake = AIC(m2),
    BIC_uptake = BIC(m2)
  )

  m1_table <- coef(summary(m1))
  m2_table <- coef(summary(m2))

  direct_rows <- grep(paste0("^", trust_var), rownames(m2_table))
  direct_table <- m2_table[direct_rows, , drop = FALSE]
  direct_p <- direct_table[, "Pr(>|z|)"]

  boot_fun <- function(data, indices) {
    d <- data[indices, , drop = FALSE]

    med_mod <- tryCatch(lm(med_formula, data = d), error = function(e) NULL)
    out_mod <- tryCatch(
      glm(out_formula, family = binomial, data = d),
      error = function(e) NULL
    )

    if (is.null(med_mod) || is.null(out_mod)) {
      return(c(indirect_mod = NA_real_, indirect_high = NA_real_))
    }

    med_coef <- coef(med_mod)
    a_mod <- get_coef_by_pattern(
      med_coef,
      paste0("^", trust_var, ".*Moderate")
    )
    a_high <- get_coef_by_pattern(
      med_coef,
      paste0("^", trust_var, ".*High")
    )
    b <- coef(out_mod)[mediator_var]

    c(
      indirect_mod = a_mod * b,
      indirect_high = a_high * b
    )
  }

  set.seed(123)
  bt <- boot(data = data, statistic = boot_fun, R = R_boot)

  ci_mod <- get_boot_ci(bt, index = 1)
  ci_high <- get_boot_ci(bt, index = 2)

  summary_res <- data.frame(
    Model = model_name,
    Trust = trust_var,
    Trust_Label = unname(trust_labels[trust_var]),
    Mediator = mediator_var,
    Mediator_Label = unname(mediator_labels[mediator_var]),
    Contrast = c("Moderate vs Low", "High vs Low"),
    Direct_P = as.numeric(direct_p),
    Direct_Significant = ifelse(direct_p < 0.05, "Yes", "No"),
    Indirect_Beta = as.numeric(bt$t0),
    Indirect_Lower_95CI = c(ci_mod[1], ci_high[1]),
    Indirect_Upper_95CI = c(ci_mod[2], ci_high[2])
  ) %>%
    mutate(
      Indirect_aOR = exp(Indirect_Beta),
      Indirect_Lower_aOR = exp(Indirect_Lower_95CI),
      Indirect_Upper_aOR = exp(Indirect_Upper_95CI),
      Indirect_Significant = ifelse(
        Indirect_Lower_95CI > 0 | Indirect_Upper_95CI < 0,
        "Yes", "No"
      ),
      Either_Direct_or_Indirect_Significant = ifelse(
        Direct_Significant == "Yes" | Indirect_Significant == "Yes",
        "Yes", "No"
      )
    )

  m1_coef <- as.data.frame(m1_table) %>%
    rownames_to_column("Term") %>%
    filter(Term != "(Intercept)") %>%
    mutate(
      Model = model_name,
      Trust_Label = unname(trust_labels[trust_var]),
      Mediator_Label = unname(mediator_labels[mediator_var]),
      Row_Group = "Mediator model",
      Row_Label = clean_term_label(Term, trust_var, mediator_var),
      Lower_95CI = Estimate - 1.96 * `Std. Error`,
      Upper_95CI = Estimate + 1.96 * `Std. Error`,
      Significant = ifelse(`Pr(>|t|)` < 0.05, "Yes", "No"),
      Display = format_beta(Estimate, Lower_95CI, Upper_95CI, Significant),
      Column_Type = "Mediator model: adjusted beta"
    ) %>%
    select(
      Model, Trust_Label, Mediator_Label, Row_Group,
      Row_Label, Column_Type, Display
    )

  m2_coef <- as.data.frame(m2_table) %>%
    rownames_to_column("Term") %>%
    filter(Term != "(Intercept)") %>%
    mutate(
      Model = model_name,
      Trust_Label = unname(trust_labels[trust_var]),
      Mediator_Label = unname(mediator_labels[mediator_var]),
      Row_Group = "Outcome model",
      Row_Label = clean_term_label(Term, trust_var, mediator_var),
      aOR = exp(Estimate),
      Lower_aOR = exp(Estimate - 1.96 * `Std. Error`),
      Upper_aOR = exp(Estimate + 1.96 * `Std. Error`),
      Significant = ifelse(`Pr(>|z|)` < 0.05, "Yes", "No"),
      Display = format_aor(aOR, Lower_aOR, Upper_aOR, Significant),
      Column_Type = "Outcome model: adjusted OR"
    ) %>%
    select(
      Model, Trust_Label, Mediator_Label, Row_Group,
      Row_Label, Column_Type, Display
    )

  indirect_sig <- ifelse(
    c(ci_mod[1], ci_high[1]) > 0 |
      c(ci_mod[2], ci_high[2]) < 0,
    "Yes", "No"
  )

  indirect_coef <- data.frame(
    Model = model_name,
    Trust_Label = unname(trust_labels[trust_var]),
    Mediator_Label = unname(mediator_labels[mediator_var]),
    Row_Group = "Indirect association",
    Row_Label = c(
      "Indirect association: Moderate vs Low",
      "Indirect association: High vs Low"
    ),
    Column_Type = "Outcome model: adjusted OR",
    Display = format_aor(
      estimate = exp(as.numeric(bt$t0)),
      lower = exp(c(ci_mod[1], ci_high[1])),
      upper = exp(c(ci_mod[2], ci_high[2])),
      sig = indirect_sig
    )
  )

  list(
    summary = summary_res,
    coefficients = bind_rows(m1_coef, m2_coef, indirect_coef),
    fit = fit_row
  )
}

############################################################
# FUNCTION: RUN ALL 25 MODELS FOR ONE DATASET
############################################################

run_dataset <- function(
    dat,
    tag,
    long_name,
    covariates,
    cov_text,
    R_boot = 5000
) {
  cat("\n##################################################\n")
  cat("DATASET: ", long_name, " (N = ", nrow(dat), ")\n", sep = "")
  cat("##################################################\n")

  all_summaries <- list()
  all_coefficients <- list()
  all_fit <- list()
  model_no <- 1

  for (trust in trust_vars) {
    for (mediator in mediators) {
      model_name <- paste0("Model", model_no)
      cat(
        tag, " | Running ", model_name, ": ",
        trust, " through ", mediator, "\n"
      )

      fit <- run_path_analysis(
        data = dat,
        trust_var = trust,
        mediator_var = mediator,
        model_name = model_name,
        covariates = covariates,
        R_boot = R_boot
      )

      all_summaries[[model_no]] <- fit$summary
      all_coefficients[[model_no]] <- fit$coefficients
      all_fit[[model_no]] <- fit$fit
      model_no <- model_no + 1
    }
  }

  final_summary <- bind_rows(all_summaries)
  final_coefficients <- bind_rows(all_coefficients)
  final_fit <- bind_rows(all_fit)

  final_fit_print <- final_fit %>%
    mutate(
      across(
        c(R2_mediator, Adj_R2_mediator, McFadden_R2, Nagelkerke_R2, AUC),
        ~ round(.x, 3)
      ),
      across(
        c(AIC_mediator, BIC_mediator, AIC_uptake, BIC_uptake, LR_chisq),
        ~ round(.x, 1)
      ),
      F_p_mediator = signif(F_p_mediator, 3),
      LR_p = signif(LR_p, 3)
    )

  trust_levels <- c(
    "Government website", "Family doctor", "Family & friends",
    "AI chatbot", "Social media"
  )

  mediator_levels <- c(
    "Confidence", "Complacency", "Constraints",
    "Calculation", "Collective responsibility"
  )

  all_coefficients_for_table <- final_coefficients %>%
    mutate(
      Trust_Label = factor(Trust_Label, levels = trust_levels),
      Mediator_Label = factor(Mediator_Label, levels = mediator_levels),
      Model_Label = paste0(
        as.character(Trust_Label), " -> ", as.character(Mediator_Label)
      ),
      Model_Column = case_when(
        Column_Type == "Mediator model: adjusted beta" ~ paste0(
          Model_Label, " | Mediator model beta (95% CI)"
        ),
        Column_Type == "Outcome model: adjusted OR" ~ paste0(
          Model_Label, " | Uptake model aOR / indirect aOR (95% CI)"
        )
      )
    )

  column_order <- all_coefficients_for_table %>%
    distinct(Trust_Label, Mediator_Label, Column_Type, Model_Column) %>%
    mutate(
      Column_Type = factor(
        Column_Type,
        levels = c(
          "Mediator model: adjusted beta",
          "Outcome model: adjusted OR"
        )
      )
    ) %>%
    arrange(Trust_Label, Mediator_Label, Column_Type) %>%
    pull(Model_Column)

  supplementary_wide_table <- all_coefficients_for_table %>%
    select(Row_Group, Row_Label, Model_Column, Display) %>%
    pivot_wider(names_from = Model_Column, values_from = Display) %>%
    arrange(
      factor(
        Row_Group,
        levels = c(
          "Mediator model", "Outcome model", "Indirect association"
        )
      ),
      Row_Label
    ) %>%
    select(Row_Group, Row_Label, all_of(column_order))

  gt_supplementary_table <- supplementary_wide_table %>%
    gt() %>%
    tab_header(
      title = md(paste0(
        "**Supplementary Table 3. Full coefficient estimates for all path-analysis models: ",
        long_name, "**"
      )),
      subtitle = md(
        "*All significant and non-significant direct and indirect associations are shown*"
      )
    ) %>%
    cols_label(
      Row_Group = "Model component",
      Row_Label = "Variable / path"
    ) %>%
    fmt_markdown(columns = everything()) %>%
    tab_source_note(
      md(paste0(
        "*Bolded estimates indicate statistically significant coefficients or indirect associations. ",
        "Estimates in mediator-model columns are adjusted beta coefficients. Estimates in uptake-model ",
        "columns are adjusted odds ratios or indirect adjusted odds ratios. All models were adjusted for ",
        cov_text,
        ". Intercepts are omitted. Confidence intervals are shown as (lower, upper).*"
      ))
    ) %>%
    opt_table_font(font = "Times New Roman") %>%
    tab_options(data_row.padding = px(3))

  gt_fit_table <- final_fit_print %>%
    select(
      Model, Trust_Label, Mediator_Label,
      N_mediator_model, R2_mediator, Adj_R2_mediator, F_p_mediator,
      N_uptake_model, McFadden_R2, Nagelkerke_R2,
      LR_chisq, LR_df, LR_p, AUC
    ) %>%
    gt() %>%
    tab_header(
      title = md(paste0(
        "**Supplementary Table. Model fit of the 25 path-analysis models: ",
        long_name, "**"
      ))
    ) %>%
    cols_label(
      Trust_Label = "Trust source",
      Mediator_Label = "5C construct",
      N_mediator_model = "N",
      R2_mediator = "R2",
      Adj_R2_mediator = "Adj. R2",
      F_p_mediator = "F-test p",
      N_uptake_model = "N",
      McFadden_R2 = "McFadden R2",
      Nagelkerke_R2 = "Nagelkerke R2",
      LR_chisq = "LR chi-square",
      LR_df = "df",
      LR_p = "LR p"
    ) %>%
    tab_spanner(
      label = "Mediator model (linear)",
      columns = c(
        N_mediator_model, R2_mediator,
        Adj_R2_mediator, F_p_mediator
      )
    ) %>%
    tab_spanner(
      label = "Uptake model (logistic)",
      columns = c(
        N_uptake_model, McFadden_R2, Nagelkerke_R2,
        LR_chisq, LR_df, LR_p, AUC
      )
    ) %>%
    tab_source_note(
      md(paste0(
        "*Each path model is saturated (df = 0), so global fit indices are not informative. ",
        "Fit is reported for the two component models. LR chi-square is the likelihood-ratio ",
        "test against the intercept-only model; AUC is the area under the ROC curve.*"
      ))
    ) %>%
    opt_table_font(font = "Times New Roman") %>%
    tab_options(data_row.padding = px(3))

  f <- function(x) file.path(out_dir, paste0("Supp_Table3_", tag, "_", x))

  write.xlsx(
    final_summary,
    f("Path_Analysis_Final_Summary_All_Models.xlsx"),
    rowNames = FALSE,
    overwrite = TRUE
  )
  write.xlsx(
    final_coefficients,
    f("Path_Analysis_All_Model_Coefficients_Long.xlsx"),
    rowNames = FALSE,
    overwrite = TRUE
  )
  write.xlsx(
    supplementary_wide_table,
    f("Path_Analysis_All_Models_Wide_Table.xlsx"),
    rowNames = FALSE,
    overwrite = TRUE
  )
  write.xlsx(
    final_fit_print,
    f("Path_Analysis_Model_Fit_All_Models.xlsx"),
    rowNames = FALSE,
    overwrite = TRUE
  )
  gtsave(
    gt_supplementary_table,
    f("Path_Analysis_All_Models_Wide_Table.html")
  )
  gtsave(
    gt_supplementary_table,
    f("Path_Analysis_All_Models_Wide_Table.rtf")
  )
  gtsave(
    gt_fit_table,
    f("Path_Analysis_Model_Fit_All_Models.html")
  )

  invisible(list(
    summary = final_summary,
    coefficients = final_coefficients,
    fit = final_fit_print,
    wide_table = supplementary_wide_table
  ))
}

############################################################
# RUN PATH ANALYSES
############################################################

res_combined <- run_dataset(
  dat = data,
  tag = "Combined",
  long_name = "Combined dataset (Brunei, Hong Kong, Singapore)",
  covariates = "agegp + sex + lti + site",
  cov_text = "age group, sex, long-term illness, and site (Brunei as reference)",
  R_boot = R_BOOT
)

data_brn <- data %>%
  filter(site == "BRN") %>%
  droplevels()

res_brn <- run_dataset(
  dat = data_brn,
  tag = "BRN",
  long_name = "Brunei",
  covariates = "agegp + sex + lti",
  cov_text = "age group, sex, and long-term illness",
  R_boot = R_BOOT
)

data_hkg <- data %>%
  filter(site == "HKG") %>%
  droplevels()

res_hkg <- run_dataset(
  dat = data_hkg,
  tag = "HKG",
  long_name = "Hong Kong",
  covariates = "agegp + sex + lti",
  cov_text = "age group, sex, and long-term illness",
  R_boot = R_BOOT
)

cat("\nSample sizes by site:\n")
print(table(data$site, useNA = "ifany"))
cat("BRN N:", nrow(data_brn), "\n")
cat("HKG N:", nrow(data_hkg), "\n")

###################################################################
# SINGAPORE SENSITIVITY ANALYSIS
# MAIN-EFFECT MODELS USING CONTINUOUS TRUST SCORES
###################################################################

# Continue using the same analysis-specific data object loaded at
# the beginning. Do not reload the original RDS and do not use id.

sgp_required_variables <- c(
  "site", "agegp", "sex", "lti",
  "tr_fd", "tr_ff",
  "vh_comp", "vh_conf", "vh_cons", "vh_calc", "vh_coll",
  "flu_uptake", "flu_uptake_bin"
)

missing_sgp_variables <- setdiff(sgp_required_variables, names(data))
if (length(missing_sgp_variables) > 0) {
  stop(
    paste0(
      "The following Singapore-analysis variables are missing: ",
      paste(missing_sgp_variables, collapse = ", ")
    )
  )
}

data_sgp <- data %>%
  filter(site == "SGP") %>%
  select(all_of(sgp_required_variables)) %>%
  droplevels()

cat(
  "\nSingapore sample size before complete-case selection: ",
  nrow(data_sgp), "\n", sep = ""
)

# Reference categories: age 60+, female, and no long-term illness.
data_sgp <- data_sgp %>%
  mutate(
    agegp = factor(
      agegp,
      levels = c("60+", "50-59", "40-49", "30-39", "<30")
    ),
    sex = factor(sex, levels = c("Female", "Male")),
    lti = factor(lti, levels = c("No", "Yes"))
  )

cat("\nAge-group categories:\n")
print(table(data_sgp$agegp, useNA = "ifany"))
cat("\nSex categories:\n")
print(table(data_sgp$sex, useNA = "ifany"))
cat("\nLong-term illness categories:\n")
print(table(data_sgp$lti, useNA = "ifany"))
cat("\nFamily doctor trust distribution:\n")
print(table(data_sgp$tr_fd, useNA = "ifany"))
cat("\nFamily/friends trust distribution:\n")
print(table(data_sgp$tr_ff, useNA = "ifany"))
cat("\nInfluenza vaccination uptake:\n")
print(table(data_sgp$flu_uptake, data_sgp$flu_uptake_bin, useNA = "ifany"))

data_sgp_fd <- data_sgp %>%
  select(
    flu_uptake_bin, agegp, sex, lti,
    vh_comp, vh_conf, vh_cons, vh_calc, vh_coll, tr_fd
  ) %>%
  drop_na() %>%
  droplevels()

data_sgp_ff <- data_sgp %>%
  select(
    flu_uptake_bin, agegp, sex, lti,
    vh_comp, vh_conf, vh_cons, vh_calc, vh_coll, tr_ff
  ) %>%
  drop_na() %>%
  droplevels()

if (length(unique(data_sgp_fd$flu_uptake_bin)) < 2) {
  stop("The family doctor model contains only one uptake outcome category.")
}
if (length(unique(data_sgp_ff$flu_uptake_bin)) < 2) {
  stop("The family/friends model contains only one uptake outcome category.")
}

sgp_fd_continuous <- glm(
  flu_uptake_bin ~ agegp + sex + lti +
    vh_comp + vh_conf + vh_cons + vh_calc + vh_coll + tr_fd,
  family = binomial(link = "logit"),
  data = data_sgp_fd,
  y = TRUE
)

sgp_ff_continuous <- glm(
  flu_uptake_bin ~ agegp + sex + lti +
    vh_comp + vh_conf + vh_cons + vh_calc + vh_coll + tr_ff,
  family = binomial(link = "logit"),
  data = data_sgp_ff,
  y = TRUE
)

model_diagnostics <- data.frame(
  Model = c("Family doctor", "Family and friends"),
  N = c(nobs(sgp_fd_continuous), nobs(sgp_ff_continuous)),
  Converged = c(
    sgp_fd_continuous$converged,
    sgp_ff_continuous$converged
  ),
  Maximum_absolute_beta = c(
    max(abs(coef(sgp_fd_continuous)), na.rm = TRUE),
    max(abs(coef(sgp_ff_continuous)), na.rm = TRUE)
  ),
  Maximum_standard_error = c(
    max(coef(summary(sgp_fd_continuous))[, "Std. Error"], na.rm = TRUE),
    max(coef(summary(sgp_ff_continuous))[, "Std. Error"], na.rm = TRUE)
  ),
  stringsAsFactors = FALSE
)

format_aor_ci <- function(estimate, lower, upper, significant) {
  output <- paste0(
    sprintf("%.2f", estimate), " (",
    sprintf("%.2f", lower), ", ",
    sprintf("%.2f", upper), ")"
  )
  ifelse(significant == "Yes", paste0("**", output, "**"), output)
}

format_p_value <- function(p_value, significant) {
  output <- case_when(
    is.na(p_value) ~ "",
    p_value < 0.001 ~ "<0.001",
    p_value >= 0.995 ~ ">0.99",
    TRUE ~ sprintf("%.3f", p_value)
  )
  ifelse(significant == "Yes", paste0("**", output, "**"), output)
}

term_dictionary <- data.frame(
  Term = c(
    "agegp50-59", "agegp40-49", "agegp30-39", "agegp<30",
    "sexMale", "ltiYes",
    "vh_comp", "vh_conf", "vh_cons", "vh_calc", "vh_coll",
    "tr_fd", "tr_ff"
  ),
  Characteristic = c(
    "   50-59", "   40-49", "   30-39", "   <30",
    "   Male", "   Yes",
    "Complacency", "Confidence", "Constraints", "Calculation",
    "Collective responsibility", "Trust", "Trust"
  ),
  Row_Order = c(3, 4, 5, 6, 9, 12, 13, 14, 15, 16, 17, 18, 18),
  stringsAsFactors = FALSE
)

extract_main_effect_model <- function(model, source_label, trust_variable) {
  as.data.frame(coef(summary(model))) %>%
    rownames_to_column("Term") %>%
    filter(Term != "(Intercept)") %>%
    mutate(
      Information_source = source_label,
      aOR = exp(Estimate),
      Lower_95CI = exp(Estimate - 1.96 * `Std. Error`),
      Upper_95CI = exp(Estimate + 1.96 * `Std. Error`),
      P_value = `Pr(>|z|)`,
      Significant = ifelse(P_value < 0.05, "Yes", "No"),
      Trust_scale = ifelse(
        Term == trust_variable,
        "Per one-point increase",
        NA_character_
      ),
      Display_aOR_CI = format_aor_ci(
        aOR, Lower_95CI, Upper_95CI, Significant
      ),
      Display_P = format_p_value(P_value, Significant)
    ) %>%
    left_join(term_dictionary, by = "Term") %>%
    mutate(
      Characteristic = case_when(
        !is.na(Characteristic) ~ Characteristic,
        grepl("^agegp", Term) ~ paste0("   ", sub("^agegp", "", Term)),
        grepl("^sex", Term) ~ paste0("   ", sub("^sex", "", Term)),
        grepl("^lti", Term) ~ paste0("   ", sub("^lti", "", Term)),
        Term == trust_variable ~ "Trust",
        TRUE ~ Term
      ),
      Row_Order = case_when(
        !is.na(Row_Order) ~ Row_Order,
        grepl("^agegp", Term) ~ 6,
        grepl("^sex", Term) ~ 9,
        grepl("^lti", Term) ~ 12,
        Term == trust_variable ~ 18,
        TRUE ~ 999
      )
    ) %>%
    select(
      Information_source, Characteristic, Row_Order, Term,
      Estimate, `Std. Error`, aOR, Lower_95CI, Upper_95CI,
      P_value, Significant, Trust_scale, Display_aOR_CI, Display_P
    )
}

sgp_fd_continuous_results <- extract_main_effect_model(
  sgp_fd_continuous, "Family doctor", "tr_fd"
)
sgp_ff_continuous_results <- extract_main_effect_model(
  sgp_ff_continuous, "Family and friends", "tr_ff"
)
sgp_continuous_results <- bind_rows(
  sgp_fd_continuous_results,
  sgp_ff_continuous_results
)

sgp_continuous_trust_only <- sgp_continuous_results %>%
  filter(Term %in% c("tr_fd", "tr_ff"))

extract_logistic_fit <- function(model, source_label) {
  model_n <- nobs(model)
  null_deviance <- model$null.deviance
  residual_deviance <- model$deviance
  mcfadden_r2 <- 1 - residual_deviance / null_deviance
  cox_snell_r2 <- 1 - exp((residual_deviance - null_deviance) / model_n)
  nagelkerke_r2 <- cox_snell_r2 / (1 - exp(-null_deviance / model_n))
  lr_chisq <- null_deviance - residual_deviance
  lr_df <- model$df.null - model$df.residual
  lr_p <- pchisq(lr_chisq, df = lr_df, lower.tail = FALSE)

  observed_outcome <- model$y
  predicted_probability <- fitted(model)
  n_vaccinated <- sum(observed_outcome == 1)
  n_unvaccinated <- sum(observed_outcome == 0)

  auc <- if (n_vaccinated > 0 && n_unvaccinated > 0) {
    probability_rank <- rank(predicted_probability)
    (
      sum(probability_rank[observed_outcome == 1]) -
        n_vaccinated * (n_vaccinated + 1) / 2
    ) / (n_vaccinated * n_unvaccinated)
  } else {
    NA_real_
  }

  data.frame(
    Information_source = source_label,
    N = model_n,
    McFadden_R2 = mcfadden_r2,
    Nagelkerke_R2 = nagelkerke_r2,
    LR_chisq = lr_chisq,
    LR_df = lr_df,
    LR_p = lr_p,
    AUC = auc,
    AIC = AIC(model),
    BIC = BIC(model),
    Converged = model$converged,
    stringsAsFactors = FALSE
  )
}

sgp_continuous_model_fit <- bind_rows(
  extract_logistic_fit(sgp_fd_continuous, "Family doctor"),
  extract_logistic_fit(sgp_ff_continuous, "Family and friends")
) %>%
  mutate(
    across(c(McFadden_R2, Nagelkerke_R2, AUC), ~ round(.x, 3)),
    across(c(LR_chisq, AIC, BIC), ~ round(.x, 1)),
    LR_p = signif(LR_p, 3)
  )

sgp_model_rows <- sgp_continuous_results %>%
  select(
    Information_source, Characteristic, Row_Order,
    Display_aOR_CI, Display_P
  ) %>%
  pivot_wider(
    names_from = Information_source,
    values_from = c(Display_aOR_CI, Display_P),
    names_glue = "{Information_source}_{.value}"
  ) %>%
  rename(
    `Family doctor_aOR` = `Family doctor_Display_aOR_CI`,
    `Family doctor_p` = `Family doctor_Display_P`,
    `Family and friends_aOR` = `Family and friends_Display_aOR_CI`,
    `Family and friends_p` = `Family and friends_Display_P`
  )

reference_rows <- data.frame(
  Characteristic = c(
    "Age group (yrs)", "   60+", "Sex", "   Female",
    "Long-term illness", "   No"
  ),
  Row_Order = c(1, 2, 7, 8, 10, 11),
  `Family doctor_aOR` = c("", "-", "", "-", "", "-"),
  `Family doctor_p` = rep("", 6),
  `Family and friends_aOR` = c("", "-", "", "-", "", "-"),
  `Family and friends_p` = rep("", 6),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

sgp_continuous_wide <- bind_rows(reference_rows, sgp_model_rows) %>%
  arrange(Row_Order) %>%
  select(
    Characteristic,
    `Family doctor_aOR`, `Family doctor_p`,
    `Family and friends_aOR`, `Family and friends_p`
  )

gt_sgp_continuous <- sgp_continuous_wide %>%
  gt() %>%
  tab_header(
    title = md(paste0(
      "**Sensitivity analysis of family doctor and family/friends trust ",
      "using continuous scores in the Singapore sample**"
    )),
    subtitle = md("*Main-effect logistic regression models*")
  ) %>%
  cols_label(
    Characteristic = "Characteristic",
    `Family doctor_aOR` = "aOR (95% CI)",
    `Family doctor_p` = "p-value",
    `Family and friends_aOR` = "aOR (95% CI)",
    `Family and friends_p` = "p-value"
  ) %>%
  tab_spanner(
    label = "Family doctor",
    columns = c(`Family doctor_aOR`, `Family doctor_p`)
  ) %>%
  tab_spanner(
    label = "Family and friends",
    columns = c(`Family and friends_aOR`, `Family and friends_p`)
  ) %>%
  fmt_markdown(columns = c(
    `Family doctor_aOR`, `Family doctor_p`,
    `Family and friends_aOR`, `Family and friends_p`
  )) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(
      columns = Characteristic,
      rows = Characteristic %in% c(
        "Age group (yrs)", "Sex", "Long-term illness"
      )
    )
  ) %>%
  tab_style(
    style = cell_borders(sides = "top", color = "black", weight = px(2)),
    locations = cells_body(rows = Characteristic == "Complacency")
  ) %>%
  cols_align(
    align = "center",
    columns = c(
      `Family doctor_aOR`, `Family doctor_p`,
      `Family and friends_aOR`, `Family and friends_p`
    )
  ) %>%
  cols_align(align = "left", columns = Characteristic) %>%
  sub_missing(
    columns = c(
      `Family doctor_aOR`, `Family doctor_p`,
      `Family and friends_aOR`, `Family and friends_p`
    ),
    missing_text = ""
  ) %>%
  tab_source_note(
    source_note = md(paste0(
      "*Values are adjusted odds ratios (aORs) with 95% confidence intervals. ",
      "Trust estimates represent the change in the odds of influenza vaccination ",
      "for each one-point increase in the corresponding continuous trust score. ",
      "Both models included all five 5C constructs and were adjusted for age group, ",
      "sex, and long-term illness. Reference categories were age 60 years or older, ",
      "female sex, and no long-term illness. Bold estimates and p-values indicate p < 0.05.*"
    ))
  ) %>%
  opt_table_font(font = "Times New Roman") %>%
  tab_options(
    data_row.padding = px(3),
    heading.align = "center",
    table.font.size = px(12),
    source_notes.font.size = px(10),
    column_labels.font.weight = "bold",
    table.width = pct(100)
  )

gt_sgp_model_fit <- sgp_continuous_model_fit %>%
  gt() %>%
  tab_header(
    title = md(
      "**Model performance of continuous-trust main-effect models in Singapore**"
    )
  ) %>%
  cols_label(
    Information_source = "Information source",
    N = "N",
    McFadden_R2 = "McFadden R2",
    Nagelkerke_R2 = "Nagelkerke R2",
    LR_chisq = "LR chi-square",
    LR_df = "df",
    LR_p = "LR p-value",
    AUC = "AUC",
    AIC = "AIC",
    BIC = "BIC",
    Converged = "Converged"
  ) %>%
  tab_source_note(
    source_note = md(paste0(
      "*LR chi-square represents the likelihood-ratio test against the ",
      "intercept-only model. AUC represents the area under the receiver ",
      "operating characteristic curve.*"
    ))
  ) %>%
  opt_table_font(font = "Times New Roman") %>%
  tab_options(data_row.padding = px(3))

excel_output_file <- file.path(
  out_dir,
  "SGP_Main_Effect_Continuous_Trust_FamilyDoctor_FamilyFriends_With_Pvalues.xlsx"
)
html_output_file <- file.path(
  out_dir,
  "SGP_Main_Effect_Continuous_Trust_FamilyDoctor_FamilyFriends_With_Pvalues.html"
)
rtf_output_file <- file.path(
  out_dir,
  "SGP_Main_Effect_Continuous_Trust_FamilyDoctor_FamilyFriends_With_Pvalues.rtf"
)
model_fit_html_file <- file.path(
  out_dir,
  "SGP_Main_Effect_Continuous_Trust_Model_Fit.html"
)
rds_output_file <- file.path(
  out_dir,
  "SGP_Main_Effect_Continuous_Trust_Model_Objects.rds"
)

write.xlsx(
  x = list(
    "Publication table" = sgp_continuous_wide,
    "Trust estimates only" = sgp_continuous_trust_only,
    "Full model results" = sgp_continuous_results,
    "Model fit" = sgp_continuous_model_fit,
    "Model diagnostics" = model_diagnostics,
    "Family doctor trust distribution" = as.data.frame(
      table(data_sgp$tr_fd, useNA = "ifany")
    ),
    "Family friends trust distribution" = as.data.frame(
      table(data_sgp$tr_ff, useNA = "ifany")
    )
  ),
  file = excel_output_file,
  rowNames = FALSE,
  overwrite = TRUE
)

gtsave(gt_sgp_continuous, filename = html_output_file)
gtsave(gt_sgp_continuous, filename = rtf_output_file)
gtsave(gt_sgp_model_fit, filename = model_fit_html_file)

# The saved model objects contain only model-specific complete-case data
# derived from Nurses_analysis_data.RDS; the original study RDS is never read.
saveRDS(
  object = list(
    family_doctor_model = sgp_fd_continuous,
    family_friends_model = sgp_ff_continuous,
    full_results = sgp_continuous_results,
    trust_results = sgp_continuous_trust_only,
    model_fit = sgp_continuous_model_fit,
    publication_table = sgp_continuous_wide
  ),
  file = rds_output_file
)

cat("\n====================================================\n")
cat("ALL ANALYSES COMPLETED\n")
cat("====================================================\n")
cat("\nOutput folder:\n", out_dir, "\n", sep = "")
cat("\nSingapore Excel output:\n", excel_output_file, "\n", sep = "")
cat("\nSingapore HTML table:\n", html_output_file, "\n", sep = "")
cat("\nSingapore RTF table:\n", rtf_output_file, "\n", sep = "")
cat("\nSingapore model objects:\n", rds_output_file, "\n", sep = "")
