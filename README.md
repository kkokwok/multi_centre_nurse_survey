# Trust, 5C Constructs, and Influenza Vaccination Uptake Among Nurses

## Overview

This repository contains the analysis-specific dataset and R code used to reproduce the effect-modification, path, and sensitivity analyses examining trust in health information sources, the 5C psychological antecedents of vaccination, and influenza vaccination uptake among nurses in Brunei, Hong Kong, and Singapore.

The repository contains only variables required for the reported analyses. Prespecified participant exclusions and variable derivations were completed before creation of the shared dataset. Participant identifiers and variables unrelated to these analyses are not included.

## Repository contents

The repository contains the following files:

- `Nurses_analysis_data.RDS`: analysis-specific dataset used by both R scripts.
- `modification_analysis.R`: R code for the effect-modification analyses.
- `path_analysis.R`: R code for the path analyses and Singapore main-effect sensitivity analyses.

## Dataset

### `Nurses_analysis_data.RDS`

This analysis-specific dataset contains only the variables required to reproduce the analyses in this repository.

The included variables cover:

- study population/site;
- age group;
- sex;
- long-term illness;
- trust in government websites;
- trust in family doctors;
- trust in family/friends;
- trust in AI chatbots;
- trust in social media;
- confidence;
- complacency;
- constraints;
- calculation;
- collective responsibility; and
- influenza vaccination uptake.

Both continuous and categorised trust variables required by the analyses are included.

The dataset does not contain participant identifiers or study variables unrelated to the analyses presented in this repository.

## Information sources

The analyses examine trust in five health information sources:

1. Government websites
2. Family doctors
3. Family/friends
4. AI chatbots
5. Social media

## 5C constructs

The following five psychological antecedents of vaccination are examined:

1. Confidence
2. Complacency
3. Constraints
4. Calculation
5. Collective responsibility

# Effect-modification analyses

## Script

`modification_analysis.R`

## Objective

The effect-modification analyses examine whether associations between the five 5C constructs and influenza vaccination uptake vary according to trust in different health information sources.

Each trust source is examined separately in interaction models with each of the five 5C constructs.

Influenza vaccination uptake is modelled as a binary outcome using logistic regression. The reported results include adjusted odds ratios, 95% confidence intervals, and p-values.

## Combined analysis

The first set of effect-modification models is fitted using the combined dataset consisting of participants from:

- Brunei;
- Hong Kong; and
- Singapore.

The models include:

- the relevant trust variable;
- the relevant 5C construct;
- the trust-by-5C interaction term;
- the remaining 5C constructs; and
- the prespecified covariates.

The combined models adjust for:

- age group;
- sex;
- long-term illness; and
- study site.

For the categorical trust analyses, low trust is treated as the reference category.

## Brunei analysis

The effect-modification analyses are repeated separately using the Brunei sample.

The Brunei models adjust for:

- age group;
- sex; and
- long-term illness.

Study site is not included because it is constant within the Brunei sample.

## Hong Kong analysis

The effect-modification analyses are also repeated separately using the Hong Kong sample.

The Hong Kong models adjust for:

- age group;
- sex; and
- long-term illness.

For confidence, complacency, constraints, and collective responsibility, trust is modelled using the categorical trust variables, with low trust as the reference category.

## Hong Kong calculation interaction models

A separate model specification is used for the calculation interaction analyses in the Hong Kong sample because of sparse observations in some categorical trust-calculation combinations.

Calculation scores are grouped into three categories:

- `1.0–5.0`: Low
- `5.1–6.0`: Medium
- `6.1–7.0`: High

For these models, trust is modelled as a continuous variable on its original 1–7 scale.

This specification reduces sparse trust-calculation combinations and avoids unnecessary model parameterisation while retaining the information contained in the original trust scale.

The adjusted odds ratio for continuous trust represents the change in the odds of influenza vaccination uptake associated with a one-point increase in the corresponding trust score, conditional on the reference category of calculation in models containing an interaction.

# Path analyses

## Script

`path_analysis.R`

## Objective

The path analyses examine whether trust in each health information source is associated with influenza vaccination uptake directly and indirectly through each of the five 5C constructs.

The general pathway is:

**Trust in an information source → 5C construct → Influenza vaccination uptake**

Each trust source is paired separately with each 5C construct. Therefore, 25 trust–5C models are estimated for each population analysis:

- 5 trust sources × 5 5C constructs = 25 models.

The analyses estimate:

1. the association between trust and the relevant 5C construct;
2. the association between the relevant 5C construct and influenza vaccination uptake;
3. the direct association between trust and influenza vaccination uptake; and
4. the indirect association between trust and influenza vaccination uptake through the relevant 5C construct.

The mediator component is estimated using linear regression. The influenza vaccination uptake component is estimated using logistic regression.

Indirect associations are estimated using the product of the relevant regression coefficients. Bootstrap confidence intervals are calculated for the indirect associations.

Because the individual path models are saturated, global model-fit indices such as the chi-square test, RMSEA, CFI, and SRMR are not informative. Model-performance statistics are therefore reported separately for the linear mediator model and logistic uptake model.

## Combined path analysis

Twenty-five path models are fitted using the combined dataset consisting of participants from Brunei, Hong Kong, and Singapore.

The combined models adjust for:

- age group;
- sex;
- long-term illness; and
- study site.

Brunei is used as the reference category for study site.

## Brunei path analysis

The same 25 path models are fitted separately using the Brunei sample.

The Brunei models adjust for:

- age group;
- sex; and
- long-term illness.

Study site is not included because it is constant within the Brunei sample.

## Hong Kong path analysis

The same 25 path models are fitted separately using the Hong Kong sample.

The Hong Kong models adjust for:

- age group;
- sex; and
- long-term illness.

Study site is not included because it is constant within the Hong Kong sample.

# Singapore main-effect sensitivity analyses

The `path_analysis.R` script also conducts two Singapore-specific main-effect sensitivity analyses.

These analyses examine:

1. continuous trust in family doctors; and
2. continuous trust in family/friends.

Continuous trust is used because of small numbers in some categorical trust groups. Retaining trust on its original scale reduces sparsity and avoids the additional parameters introduced by categorical trust variables.

## Model 1: Family doctor trust

The first logistic regression model examines the association between continuous family doctor trust and influenza vaccination uptake.

The model includes:

- age group;
- sex;
- long-term illness;
- confidence;
- complacency;
- constraints;
- calculation;
- collective responsibility; and
- continuous family doctor trust.

## Model 2: Family/friends trust

The second logistic regression model examines the association between continuous family/friends trust and influenza vaccination uptake.

The model includes:

- age group;
- sex;
- long-term illness;
- confidence;
- complacency;
- constraints;
- calculation;
- collective responsibility; and
- continuous family/friends trust.

For both models, the adjusted odds ratio for trust represents the change in the odds of influenza vaccination uptake associated with a one-point increase in the corresponding trust score.

The reference categories for the demographic covariates are:

- age 60 years or older;
- female sex; and
- no long-term illness.

# Summary of analyses

## `modification_analysis.R`

The script produces:

- effect-modification models for the combined Brunei, Hong Kong, and Singapore sample;
- population-specific effect-modification models for Brunei;
- population-specific effect-modification models for Hong Kong; and
- separate Hong Kong calculation interaction models using categorical calculation and continuous trust.

## `path_analysis.R`

The script produces:

- 25 path models for the combined Brunei, Hong Kong, and Singapore sample;
- 25 population-specific path models for Brunei;
- 25 population-specific path models for Hong Kong;
- one Singapore main-effect model using continuous family doctor trust; and
- one Singapore main-effect model using continuous family/friends trust.

# Software requirements

The analyses were conducted in R.

The required R packages include:

- `boot`
- `dplyr`
- `tidyr`
- `tibble`
- `gtsummary`
- `gt`
- `openxlsx`
- `here`

Install any missing packages before running the scripts:

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
