# Trust in Digital and Traditional Health Information Sources and Influenza Vaccination Uptake among Nurses

## Authors

Kin On KWOK, Wan In WEI, Edward Braddon MCNEIL, Elliot Eu Zai FENG, Arthur TANG, Ashish TRIVEDI, Shui Shan LEE, Alice LAI and John Wah LIM

## Overview

This repository contains analysis-specific datasets and R code used to reproduce the participant demographic, effect-modification, path, and sensitivity analyses examining trust in health information sources, the 5C psychological antecedents of vaccination, and influenza vaccination uptake among nurses in **Brunei, Hong Kong, and Singapore**.

The shared datasets contain only variables required for the analyses presented here. Prespecified participant exclusions and variable derivations were completed before creation of the shared datasets. Participant identifiers and variables unrelated to these analyses are not included.

---

## Repository Contents

The repository contains the following files:

- `demographics.R`: R code for participant characteristics and univariable analyses of influenza vaccination uptake.
- `modification_analysis.R`: R code for the effect-modification analyses.
- `path_analysis.R`: R code for the path analyses and Singapore main-effect sensitivity analyses.
- `demographics.RDS`: analysis-specific dataset for the participant characteristics table.
- `README.md`: description of the datasets and analyses.

---

# Participant Demographics and Characteristics

## Script: `demographics.R`

### Objective

The `demographics.R` script describes participant characteristics among nurses from **Brunei, Hong Kong, and Singapore** and examines univariable associations between these characteristics and influenza vaccination uptake.

The final output combines:

1. participant characteristics stratified by study site;
2. participant characteristics in the overall study sample; and
3. univariable associations between each participant characteristic and influenza vaccination uptake.

## Dataset: `demographics.RDS`

`demographics.RDS` contains only the variables required to generate the participant characteristics table and associated univariable analyses.

| Variable | Description | Coding / use |
|---|---|---|
| `agegp` | Age group | Categorical age group |
| `sex` | Sex | Categorical |
| `lti` | Long-term illness | Categorical |
| `hcon_livn` | Household size | Participant household size |
| `lives_kid` | Lives with children | Categorical |
| `lives_eld` | Lives with elderly people | Categorical |
| `wcc` | Contact with patients | Categorical |
| `site` | Study population/site | BRN = Brunei; HKG = Hong Kong; SGP = Singapore |
| `flu_uptake` | Influenza vaccination uptake | Outcome used in the univariable logistic regression models |

The original study dataset and participant identifiers are not required by `demographics.R`.

### Analysis 1: Participant Characteristics by Study Site

Participant characteristics are summarised separately for Brunei, Hong Kong, and Singapore using `tbl_summary()`.

The characteristics presented are:

- age group;
- sex;
- long-term illness;
- household size;
- living with children;
- living with elderly people; and
- contact with patients.

Missing observations are displayed as **“No response.”** Between-site comparisons are obtained using `add_p()`, which provides a p-value for each participant characteristic. This component is generated as `Table_1_A`.

### Analysis 2: Overall Participant Characteristics

The same participant characteristics are summarised for the overall study sample without stratification by site. Missing observations are displayed as **“No response.”** This component is generated as `Table_1_B`.

### Analysis 3: Univariable Associations With Influenza Vaccination Uptake

Univariable logistic regression is used to examine each participant characteristic separately in relation to influenza vaccination uptake. The analyses include age group, sex, long-term illness, household size, living with children, living with elderly people, and contact with patients.

Because the regression coefficients are exponentiated, results are presented as **odds ratios (ORs)** with confidence intervals and p-values. Global p-values are added for relevant multi-category variables using `add_global_p()`. Because the predictors are modelled separately, the reported estimates are **unadjusted odds ratios**, not adjusted odds ratios. This component is generated as `Table_1_C`.

### Final Participant Characteristics Table

`Table_1_A`, `Table_1_B`, and `Table_1_C` are combined using `tbl_merge()` and formatted using the `gt` package. The final table is exported as:

- `Table 1.html`

---

# Effect-Modification and Path-Analysis Dataset

## Dataset: `path_modification_analysis.RDS`

`path_modification_analysis.RDS` contains only variables required to reproduce the effect-modification, path, and sensitivity analyses.

Prespecified participant exclusions and required variable derivations were completed before creation of this dataset. Participant identifiers and study variables unrelated to the reported analyses were removed.

## Variable Description

| Variable | Description | Coding / scale |
|---|---|---|
| `agegp` | Age group | Categorical age group |
| `sex` | Sex | Categorical |
| `lti` | Long-term illness | Categorical |
| `site` | Study population/site | BRN = Brunei; HKG = Hong Kong; SGP = Singapore |
| `tr_gw3` | Trust in government websites | Low, Moderate, High |
| `tr_sm3` | Trust in social media | Low, Moderate, High |
| `tr_ai3` | Trust in AI chatbots | Low, Moderate, High |
| `tr_fd3` | Trust in family doctors | Low, Moderate, High |
| `tr_ff3` | Trust in family/friends | Low, Moderate, High |
| `tr_gw` | Trust in government websites | Continuous trust score on the original 1–7 scale |
| `tr_sm` | Trust in social media | Continuous trust score on the original 1–7 scale |
| `tr_ai` | Trust in AI chatbots | Continuous trust score on the original 1–7 scale |
| `tr_fd` | Trust in family doctors | Continuous trust score on the original 1–7 scale |
| `tr_ff` | Trust in family/friends | Continuous trust score on the original 1–7 scale |
| `vh_conf` | Confidence | Mean score for the Confidence construct |
| `vh_comp` | Complacency | Mean score for the Complacency construct |
| `vh_cons` | Constraints | Mean score for the Constraints construct |
| `vh_calc` | Calculation | Mean score for the Calculation construct |
| `vh_coll` | Collective responsibility | Mean score for the Collective Responsibility construct |
| `flu_uptake` | Influenza vaccination uptake | Original categorical outcome |

The analysis code derives the following binary outcome from `flu_uptake`:

| Derived variable | Description | Coding |
|---|---|---|
| `flu_uptake_bin` | Binary influenza vaccination uptake | 1 = received influenza vaccination; 0 = did not receive influenza vaccination |

`flu_uptake_bin` is generated by the analysis code and does not need to be stored separately in `path_modification_analysis.RDS`.

## Trust Variables

Trust in each information source was measured on an original **1–7 scale**. The continuous variables retain the original scores:

- `tr_gw`: government websites;
- `tr_fd`: family doctors;
- `tr_ff`: family/friends;
- `tr_ai`: AI chatbots; and
- `tr_sm`: social media.

The corresponding three-category variables are:

- `tr_gw3`: government websites;
- `tr_fd3`: family doctors;
- `tr_ff3`: family/friends;
- `tr_ai3`: AI chatbots; and
- `tr_sm3`: social media.

Categorical trust is represented as **Low**, **Moderate**, or **High**. Low trust is the reference category in models using categorical trust.

## 5C Variables

The analyses examine five psychological antecedents of vaccination:

- `vh_conf`: **Confidence**;
- `vh_comp`: **Complacency**;
- `vh_cons`: **Constraints**;
- `vh_calc`: **Calculation**; and
- `vh_coll`: **Collective responsibility**.

The 5C constructs are examined as potential effect modifiers in the effect-modification analyses and as intermediate variables in the path analyses.

## Study Populations

The `site` variable identifies the three study populations:

- `BRN`: Brunei;
- `HKG`: Hong Kong; and
- `SGP`: Singapore.

Study site is included as a covariate in combined analyses. It is not included in population-specific analyses because it is constant within each population.

---

# Effect-Modification Analyses

## Script: `modification_analysis.R`

### Objective

The effect-modification analyses examine whether associations between the five 5C constructs and influenza vaccination uptake vary according to trust in different health information sources.

The five information sources are government websites, family doctors, family/friends, AI chatbots, and social media. Each trust source is examined separately in interaction models with each of the five 5C constructs.

Influenza vaccination uptake is modelled as a binary outcome using logistic regression. The models contain the relevant trust variable, the relevant 5C construct, their interaction term, the remaining 5C constructs, and the prespecified covariates. Results include adjusted odds ratios, 95% confidence intervals, and p-values.

### Combined Effect-Modification Analysis

The combined analysis includes participants from Brunei, Hong Kong, and Singapore. Models adjust for:

- age group;
- sex;
- long-term illness; and
- study site.

For models using categorical trust, Low trust is the reference category.

### Brunei Effect-Modification Analysis

The analyses are repeated separately in the Brunei sample. Models adjust for age group, sex, and long-term illness. Study site is not included because all observations are from Brunei.

### Hong Kong Effect-Modification Analysis

The analyses are also repeated separately in the Hong Kong sample. Models adjust for age group, sex, and long-term illness.

For interaction models involving Confidence, Complacency, Constraints, and Collective Responsibility, trust is modelled categorically, with Low trust as the reference category.

### Hong Kong Calculation Interaction Models

A separate specification is used for the Calculation interaction models in Hong Kong because of sparse observations in some categorical trust–Calculation combinations.

Calculation mean scores are grouped into:

- **1.0–5.0:** Low;
- **5.1–6.0:** Medium; and
- **6.1–7.0:** High.

Trust is modelled continuously on its original **1–7 scale**. This reduces sparse trust–Calculation combinations and avoids unnecessary model parameterisation while retaining the information in the original trust scale.

In these interaction models, the adjusted odds ratio for continuous trust is interpreted conditional on the reference level of Calculation.

---

# Path Analyses

## Script: `path_analysis.R`

### Objective

The path analyses examine whether trust in each health information source is associated with influenza vaccination uptake directly and indirectly through individual 5C constructs.

The general pathway is:

**Trust in information source → 5C construct → Influenza vaccination uptake**

Five trust sources are paired separately with five 5C constructs, resulting in:

**5 trust sources × 5 5C constructs = 25 path models per population analysis**

For each trust–5C combination, the analysis examines:

1. the association between trust and the relevant 5C construct;
2. the association between the relevant 5C construct and influenza vaccination uptake;
3. the direct association between trust and influenza vaccination uptake; and
4. the indirect association between trust and influenza vaccination uptake through the relevant 5C construct.

The 5C component is estimated using linear regression, while influenza vaccination uptake is estimated using logistic regression. Indirect associations are calculated from the product of the relevant regression coefficients, with bootstrap confidence intervals.

These analyses examine **direct and indirect associations** and do not establish causal mediation.

### Combined Path Analysis

Twenty-five path models are fitted using the combined Brunei, Hong Kong, and Singapore dataset. Models adjust for age group, sex, long-term illness, and study site. Brunei is the reference category for study site.

### Brunei Path Analysis

The same 25 path models are fitted separately in the Brunei sample, adjusting for age group, sex, and long-term illness.

### Hong Kong Path Analysis

The same 25 path models are fitted separately in the Hong Kong sample, adjusting for age group, sex, and long-term illness.

## Model Performance for Path Analyses

Each individual trust–5C path model is saturated. Conventional global fit indices such as chi-square, RMSEA, CFI, and SRMR are therefore not informative.

Model-performance statistics are reported separately for the two component models.

For the linear 5C model, reported statistics include:

- R²;
- adjusted R²;
- F-test p-value;
- AIC; and
- BIC.

For the logistic vaccination-uptake model, reported statistics include:

- McFadden R²;
- Nagelkerke R²;
- likelihood-ratio chi-square test;
- AUC;
- AIC; and
- BIC.

---

# Singapore Main-Effect Sensitivity Analyses

The `path_analysis.R` script also conducts two Singapore-specific main-effect sensitivity analyses using continuous trust scores:

1. family doctor trust; and
2. family/friends trust.

Continuous trust is used because of small numbers in some categorical trust groups. Retaining trust on its original scale reduces sparsity and avoids the additional parameters introduced by categorising trust.

## Model 1: Family Doctor Trust

The first multivariable logistic regression model examines continuous family doctor trust in relation to influenza vaccination uptake. The model includes:

- age group;
- sex;
- long-term illness;
- Confidence;
- Complacency;
- Constraints;
- Calculation;
- Collective Responsibility; and
- continuous family doctor trust.

The adjusted odds ratio for trust represents the change in the odds of influenza vaccination uptake associated with a **one-point increase in family doctor trust**.

## Model 2: Family/Friends Trust

The second multivariable logistic regression model examines continuous family/friends trust in relation to influenza vaccination uptake, with the same covariate adjustment.

The adjusted odds ratio for trust represents the change in the odds of influenza vaccination uptake associated with a **one-point increase in family/friends trust**.

For both Singapore models, reference categories are age 60 years or older, female sex, and no long-term illness.

---

# Summary of Analyses

## `demographics.R`

This script produces:

- participant characteristics by study site;
- p-values comparing characteristics across Brunei, Hong Kong, and Singapore;
- participant characteristics for the overall sample;
- univariable logistic regression analyses of participant characteristics and influenza vaccination uptake; and
- the merged participant characteristics table exported as `Table 1.html`.

## `modification_analysis.R`

This script produces:

- effect-modification analyses for the combined Brunei, Hong Kong, and Singapore sample;
- population-specific effect-modification analyses for Brunei;
- population-specific effect-modification analyses for Hong Kong; and
- separate Hong Kong Calculation interaction models using grouped Calculation scores and continuous trust.

## `path_analysis.R`

This script produces:

- 25 path models for the combined Brunei, Hong Kong, and Singapore sample;
- 25 population-specific path models for Brunei;
- 25 population-specific path models for Hong Kong;
- one Singapore main-effect sensitivity model using continuous family doctor trust; and
- one Singapore main-effect sensitivity model using continuous family/friends trust.

---

# Software Requirements

The analyses are conducted in R. Required packages include:

- `boot`
- `dplyr`
- `tidyr`
- `tibble`
- `gtsummary`
- `gt`
- `openxlsx`
- `here`

Install missing packages using:

```r
install.packages(
  c(
    "boot",
    "dplyr",
    "tidyr",
    "tibble",
    "gtsummary",
    "gt",
    "openxlsx",
    "here"
  )
)
```

---

# Running the Analyses

## Step 1: Download the Repository

Download or clone the repository. The following files should be available:

- `demographics.RDS`
- `demographics.R`
- `path_modification_analysis.RDS`
- `modification_analysis.R`
- `path_analysis.R`

## Step 2: Use Relative Data Paths

If the datasets and scripts are stored in the same working directory, load the datasets using:

```r
demographics_data <- readRDS("demographics.RDS")
analysis_data <- readRDS("path_modification_analysis.RDS")
```

Alternatively, when using an R project:

```r
demographics_data <- readRDS(here::here("demographics.RDS"))
analysis_data <- readRDS(here::here("path_modification_analysis.RDS"))
```

The public R code should not require access to the original study dataset or use computer-specific absolute paths.

## Step 3: Run the Demographic Analysis

```r
source("demographics.R")
```

## Step 4: Run the Effect-Modification Analyses

```r
source("modification_analysis.R")
```

## Step 5: Run the Path and Singapore Sensitivity Analyses

```r
source("path_analysis.R")
```

For a quick path-analysis test run:

```r
R_BOOT <- 500
```

For the final analyses:

```r
R_BOOT <- 5000
```

The final analysis may take time because 25 path models are estimated for each of the combined, Brunei, and Hong Kong analyses, with bootstrap resampling for each model.

---

# Interpretation

These analyses are based on observational data. Direct, indirect, interaction, main-effect, and univariable estimates should be interpreted as **associations rather than causal effects**.

The path analyses assess whether observed associations are consistent with indirect pathways through the 5C constructs. They do not establish causal mediation.

Interaction analyses assess whether associations differ according to levels of trust or the relevant 5C construct on the model scale. Statistically significant interaction terms do not by themselves establish causal effect modification.

The demographic logistic regressions model each participant characteristic separately. Their odds ratios are therefore unadjusted and should not be interpreted as independent effects after adjustment for other participant characteristics.

---

# Data Confidentiality

The original study dataset is **not included** in this repository.

The shared RDS files were created specifically for the analyses reported here by:

- applying prespecified participant exclusions where relevant;
- generating required derived variables;
- retaining only variables required for the reported analyses;
- removing participant identifiers; and
- excluding study variables unrelated to these analyses.

The shared datasets should be used only for reproducing and evaluating the analyses presented with the associated study.

---

# Citation

If these datasets or analysis scripts are used, please cite the associated publication.

Full citation details will be added following publication.


---
# Data Availability

The analysis-specific datasets used to reproduce the analyses are available from the corresponding author upon reasonable request and are not publicly deposited in this repository.

- `path_modification_analysis.RDS`: analysis-specific dataset used for the effect-modification, path, and sensitivity analyses.


# Contact

For questions regarding the analyses, datasets, or code, please contact the corresponding author: Kin On KWOK by email at 
kkokwok@cuhk.edu.hk
