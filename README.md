# Chem277A Final Project

**Team:** Priscilla Vaskez · Trinity Ho · Yasemin Sucu · Dongwan Kim

## Repository
https://github.com/dw1229/chem277a-final-ecoli-inhibition-ml

## Introduction
CO-ADD is a community antimicrobial screening dataset that reports how submitted small molecules behave in biological assays against organisms such as *E. coli*. Our objective is to build an assay-aware model that can prioritize the strongest *E. coli* inhibitors, because structure-only prediction was not reliable enough with the basic descriptors alone. We therefore add feature engineering from molecular fingerprints, Tanimoto similarity features based on top-10% inhibition compounds, and assay context to improve the signal. `INHIB_AVE` comes from the primary inhibition screen, while `DMAX_AVE` comes from dose-response follow-up; because wet-lab teams may have one assay result before the other, learning the relationship between these assay readouts can help prioritize compounds for additional testing.

## Project Idea
This project did not start as a classification problem. Our first plan was to predict the exact *E. coli* inhibition percentage (`INHIB_AVE`) as a continuous regression target using molecular descriptors from `SMILES` and experimental features from the CO-ADD dataset. We tried that direction first in `ecoli_inhibition_ml.ipynb` with linear regression, PCA-style dimensionality reduction, ANN experiments, and clustering/UMAP checks. The exact inhibition values turned out to be difficult to model cleanly: many compounds were concentrated in the low-to-moderate inhibition range, while the strongest inhibitors were rare and noisier than a simple smooth regression trend.

Because of this, we reframed the final task as an assay-aware classification problem: predict whether a compound belongs to the top 10% of *E. coli* inhibition based on `INHIB_AVE`. This framing is useful for antimicrobial screening because the practical goal is often not to perfectly predict every inhibition percentage, but to prioritize the most promising compounds for follow-up testing.

The transition is documented across the development notebooks. `svm_linear_log_cluster.ipynb` tested the move from top-30% classification to a stricter top-10% label using SVM, GLM/logistic regression, feature selection, Elastic Net-style regularization, and clustering visualizations. `ANN_ecoli.ipynb` explored whether a neural network could improve minority-class detection with regularization, class weights, SMOTE, and early stopping. These experiments helped motivate the final assay-aware top-10% classifier, but the final submitted workflow is consolidated in `ecoli_inhibition_final.ipynb`.

The final model uses stronger feature engineering from assay-context variables, RDKit descriptors, MACCS keys, 2,048-bit Morgan fingerprints, and Tanimoto similarity features based on top-10% inhibition compounds. We then use scikit-learn `LogisticRegressionCV` with an elastic-net penalty to regularize the large feature set and select a small, interpretable subset of predictors.

## Dataset
- Source: CO-ADD (Community for Open Antimicrobial Drug Discovery) database
- Download page: https://db.co-add.org/downloads
- Data format: CSV (`InhibitionData` + `DoseResponseData`)

## Notebook Roadmap
1. `ecoli_inhibition_final.ipynb`  
   **Start here for the final submission.** This is the main consolidated notebook and should be read first. It contains the full project story in one runnable workflow: CO-ADD data preparation, regression motivation, ANN exploration, SVM and GLM/logistic classification experiments, UMAP/KMeans checks, final assay-aware feature engineering, Elastic Net Logistic RegressionCV, final metrics, selected predictors, and ablation tests. For the final submitted analysis, this notebook is sufficient. For the trial-and-error path behind the final workflow, the development notebooks below can be read in order.
2. `ecoli_inhibition_ml.ipynb`  
   Development notebook for the original data preparation and baseline exploration. It loads the two CO-ADD CSV files, filters for *E. coli*, merges inhibition and dose-response rows with exact experiment keys (`COADD_ID`, `STRAIN`, `ASSAY_ID`), parses MIC-related fields, computes initial RDKit descriptors, and saves the processed master table as `ecoli_merged_master_4268.csv`. It also contains early regression and exploratory checks that motivated moving away from exact-value regression.
3. `ANN_ecoli.ipynb`  
   Development notebook focused on ANN experiments. It tests regularization, class weighting, SMOTE oversampling, early stopping, and threshold-based evaluation for the imbalanced top-10% classification setup. The main ANN lessons are summarized in the final notebook.
4. `svm_linear_log_cluster.ipynb`  
   Development notebook for the classification transition. It starts from `ecoli_merged_master_4268.csv`, compares top-30% and top-10% labels, and tests SVM, GLM/logistic regression, feature selection, regularization, UMAP, KMeans, and GMM-style exploratory models.
5. `elasticnet_LogisticRegression_ml.ipynb`  
   Development notebook for the final Elastic Net Logistic Regression pipeline. It builds the larger assay-aware feature matrix and tests the sparse `LogisticRegressionCV` model. The same final modeling logic is integrated into `ecoli_inhibition_final.ipynb` for submission.

## Basic Workflow
1. In `ecoli_inhibition_final.ipynb`, load the complete CO-ADD inhibition and dose-response CSV datasets (this original data-loading workflow is also shown in `ecoli_inhibition_ml.ipynb`).
2. Filter both datasets to *E. coli* rows (also shown in `ecoli_inhibition_ml.ipynb`).
3. Merge rows using exact experiment keys (`COADD_ID`, `STRAIN`, `ASSAY_ID`) so inhibition and dose-response values refer to the same assay context.
4. Create or load the processed master table (`ecoli_merged_master_4268.csv`) with 4,268 exact-matched rows and 4,174 unique compounds.
5. Parse MIC-related fields (`DRVAL_MEDIAN`, `MIC_OPERATOR`, `MIC_VALUE_uM`) and compute molecular descriptors from `SMILES`.
6. First test exact `INHIB_AVE` prediction as a regression problem using linear regression, PCA-style dimensionality reduction, and error diagnostics. These baseline results show that the continuous inhibition values are difficult to predict cleanly, especially because many compounds cluster in the low-to-moderate inhibition range while the strongest inhibitors are rare.
7. Next, explore nonlinear and alternative views of the data. `ANN_ecoli.ipynb` tests neural-network models with regularization, class weights, SMOTE oversampling, and early stopping to see whether nonlinear modeling improves the imbalanced top-10% classification task. The ANN experiments improve some classification-style metrics but also show overfitting and class-imbalance issues, while the UMAP, KMeans, and GMM-style clustering checks suggest that the data has structure but does not separate cleanly from simple descriptor space alone.
8. Then use `svm_linear_log_cluster.ipynb` to test the classification framing more directly with SVM and GLM/logistic models. We first try a broader top-30% inhibition label, but it is not selective enough for identifying the strongest compounds, so we shift toward a stricter top-10% hit definition.
9. Reframe the final task as top-10% hit classification after observing that high-inhibition compounds are better treated as a prioritization problem than as exact-value regression.
10. Build final features from assay context, RDKit descriptors, MACCS keys, 2,048-bit Morgan fingerprints, and 20 Tanimoto similarity features based on top-10% inhibition compounds. Tanimoto reference compounds come from buffer-filtered model-training rows only.
11. Apply a stratified 80/20 holdout test split, then split the training side again into model-training and validation. Apply the buffer filter (`|INHIB_AVE - cutoff| < 1.5 × INHIB_STD`) to model-training rows only; validation and test stay untouched.
12. Train the final scikit-learn `LogisticRegressionCV` model with the elastic-net penalty. The model searches over `C = [0.003, 0.005, 0.007, 0.01, 0.015, 0.02, 0.03, 0.05]` and `l1_ratio = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]` with 5-fold cross-validation scored by F1.
13. Evaluate the final model on the held-out test set at the default `0.5` threshold using precision, recall, F1, ROC-AUC, balanced accuracy, and confusion matrices.
14. Run ablation tests that refit the same model on simplified inputs (`DMAX_AVE` only, without Tanimoto similarity features, and without the buffer filter) to check which design choices contribute most.

## Final Model Summary
- Final task: classify whether a compound is in the top 10% of *E. coli* inhibition based on `INHIB_AVE`.
- Final submission notebook: `ecoli_inhibition_final.ipynb`.
- Final model: scikit-learn `LogisticRegressionCV` with the elastic-net penalty. Hyperparameters are chosen with 5-fold cross-validation scored by F1 over `C = [0.003, 0.005, 0.007, 0.01, 0.015, 0.02, 0.03, 0.05]` and `l1_ratio = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]`. Class imbalance is handled with `class_weight="balanced"`.
- Input table: `ecoli_merged_master_4268.csv`.
- Data split: stratified 80/20 holdout test split, then a second 80/20 split on the training side into model-training and validation. Buffer filter (`BUFFER_K = 1.5`) is applied to model-training rows only; validation and test remain untouched.
- Main feature engineering: assay-aware features, RDKit descriptors, MACCS keys, 2,048-bit Morgan fingerprints, and 20 extra Tanimoto similarity features based on top-10% inhibition compounds, computed from the 2,048-bit Morgan fingerprints. Tanimoto reference compounds come from buffer-filtered model-training rows only to avoid leakage.
- Final selected predictors: the Elastic Net model reduces the 2,447-feature input to **3 non-zero predictors**: `DMAX_AVE` (~82% contribution), `tan_morgan_top10_count_ge_0_50` (~9%), and `tan_morgan_top10_max` (~9%).
- Test-set metrics at the default 0.50 threshold of top-10% inhibition classification: `accuracy = 0.9403`, `balanced accuracy = 0.8517`, `precision = 0.6848`, `recall = 0.7412`, `F1 = 0.7119`, `ROC-AUC = 0.9496`.
- Main metrics emphasized: precision, recall, F1, and ROC-AUC, since this is an imbalanced top-10% classification problem where finding true high-inhibition compounds matters more than raw accuracy alone.
- Ablation tests: the notebook compares the full model against three simplified variants: `DMAX_AVE` only, the full feature matrix without Tanimoto similarity features, and the full feature matrix without the buffer filter on model-training rows. The results show that `DMAX_AVE` alone is already a strong predictor, but the full model gives a better overall balance of precision, recall, F1, and ROC-AUC. Removing the Tanimoto features lowers recall and F1, suggesting that similarity to top-10% inhibition compounds adds useful chemical context. Removing the buffer filter slightly improves recall, but it also increases false positives and lowers F1, so the buffered full model is the better final choice.

## Project Code Run - Setup

## Requirements
- Conda (Anaconda or Miniconda)
- Make

## Setup Instructions

### Option A: use the Makefile
```bash
make create
make install
conda activate chem277a_project2_env
```

### Option B: use the environment file directly
```bash
conda env create -f environment.yml
conda activate chem277a-project2
```

If the environment already exists, update it with:
```bash
conda env update -f environment.yml --prune
```

## Makefile Commands
- `make create` - create Conda environment
- `make install` - install dependencies
- `make activate` - show activation command
