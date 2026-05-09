# Chem277A Final Project

**Team:** Priscilla Vaskez · Trinity Ho · Yasemin Sucu · Dongwan Kim

## Introduction
CO-ADD is a community antimicrobial screening dataset that reports how submitted small molecules behave in biological assays against organisms such as *E. coli*. Our objective is to build an assay-aware model that can prioritize the strongest *E. coli* inhibitors, because structure-only prediction was not reliable enough with the basic descriptors alone. We therefore add feature engineering from molecular fingerprints, Tanimoto similarity features based on top-10% inhibition compounds, and assay context to improve the signal. `INHIB_AVE` comes from the primary inhibition screen, while `DMAX_AVE` comes from dose-response follow-up; because wet-lab teams may have one assay result before the other, learning the relationship between these assay readouts can help prioritize compounds for additional testing.

## Project Idea
This project did not start as a classification problem. Our first plan was to predict the exact *E. coli* inhibition percentage (`INHIB_AVE`) as a continuous regression target using molecular descriptors from `SMILES` and experimental features from the CO-ADD dataset. We tried that direction first in `ecoli_inhibition_ml.ipynb` with linear regression, PCA-style dimensionality reduction, an updated ANN experiment, and clustering/UMAP checks. The exact inhibition values turned out to be difficult to model cleanly: many compounds were concentrated in the low-to-moderate inhibition range, while the strongest inhibitors were rare and noisier than a simple smooth regression trend. The ANN experiment also pushed us toward classification: using a top-10% inhibition label gave high raw accuracy, but the validation-loss pattern and class imbalance made it better as supporting evidence than as the final model.

Because of this, we reframed the final task as an assay-aware classification problem: predict whether a compound belongs to the top 10% of *E. coli* inhibition based on `INHIB_AVE`. This framing is useful for antimicrobial screening because the practical goal is often not to perfectly predict every inhibition percentage, but to prioritize the most promising compounds for follow-up testing.

The transition is documented in `svm_linear_log_cluster.ipynb`. In that notebook, we first tested a broader top-30% definition using the 70th percentile threshold, then moved to a stricter top-10% definition using the 90th percentile threshold. We also tried SVM, GLM/logistic regression, feature selection, Elastic Net-style regularization, and clustering visualizations. These experiments showed that classification was more aligned with the screening goal, but the early models were still not clean or interpretable enough to be our final approach.

Our final model is in `elasticnet_LogisticRegression_ml.ipynb`. Moving to top-10% classification made raw accuracy look much better, but accuracy alone was misleading because the test set is imbalanced. Earlier models still struggled on the metrics that matter more for drug-inhibition screening, especially recall, F1, and ROC-AUC for the high-inhibition class. To address this, we added stronger feature engineering from molecular fingerprints and Tanimoto similarity features based on top-10% inhibition compounds, then used cross-validated Elastic Net Logistic Regression to regularize the large feature set and select a small, interpretable subset of predictors.

## Dataset
- Source: CO-ADD (Community for Open Antimicrobial Drug Discovery) database
- Download page: https://db.co-add.org/downloads
- Data format: CSV (InhibitionData + DoseResponseData)

## Notebook Roadmap
1. `ecoli_inhibition_ml.ipynb`  
   Read from here. This notebook contains the main data preparation work: loading the two CO-ADD CSV files (`InhibitionData` and `DoseResponseData`), filtering for *E. coli*, merging them with exact experiment keys (`COADD_ID`, `STRAIN`, `ASSAY_ID`), parsing MIC-related fields, computing initial RDKit descriptors, and saving the processed master table as `ecoli_merged_master_4268.csv`. It also includes our early regression attempts, ANN exploration, KMeans/UMAP checks, and the motivation for moving away from exact-value regression.
2. `svm_linear_log_cluster.ipynb`  
   This notebook starts from the processed master CSV (`ecoli_merged_master_4268.csv`) and explores whether the problem works better as classification. We first tested a top-30% inhibition label, then a stricter top-10% label, and compared SVM, GLM/logistic regression, feature selection, regularization, UMAP, KMeans, and GMM-style exploratory models. This notebook is the bridge between the initial regression idea and the final top-10% classifier.
3. `elasticnet_LogisticRegression_ml.ipynb`  
   This is the final modeling notebook. It also starts from `ecoli_merged_master_4268.csv`, but adds more targeted feature engineering: assay-aware variables, RDKit descriptors, MACCS keys, Morgan fingerprints, and Tanimoto similarity features based on top-10% inhibition compounds. The notebook first does an unsupervised view of chemistry space using UMAP on the 2,048-bit Morgan fingerprints and KMeans (k=5) clustering, which confirms that one chemistry family is enriched in actives (~35% active rate vs ~10% baseline) while most of the library is near baseline — motivating the supervised pipeline that follows. The data is split with a stratified 80/20 holdout test set, and the training side is split again into model-training and validation (the test set is never used to pick hyperparameters or thresholds). A buffer filter (`|INHIB_AVE - cutoff| < 1.5 × INHIB_STD`) drops noisy borderline rows from model-training only. Even though an earlier notebook already tried logistic/GLM-style models, this final notebook uses scikit-learn's 'LogisticRegressionCV' with the elastic-net penalty so the model can search over regularization settings, handle the expanded 2,447-feature space, and select a sparse set of predictors. The final evaluation focuses on F1, recall, precision, and ROC-AUC, and an ablation section refits the same model on simplified inputs (`DMAX_AVE`-only, without 20 features from Tanimoto, and full-model with no buffer filter) to show which design choices actually contribute.

## Basic Workflow
1. Download the complete CO-ADD CSV datasets.
2. In `ecoli_inhibition_ml.ipynb`, filter *E. coli* rows from both inhibition and dose-response files.
3. In `ecoli_inhibition_ml.ipynb`, merge rows using exact experiment keys (`COADD_ID`, `STRAIN`, `ASSAY_ID`) so inhibition and dose-response values refer to the same assay context.
4. In `ecoli_inhibition_ml.ipynb`, create the processed master table (`ecoli_merged_master_4268.csv`) with 4,268 exact-matched rows and 4,174 unique compounds.
5. In `ecoli_inhibition_ml.ipynb`, parse MIC-related fields (`DRVAL_MEDIAN`, `MIC_OPERATOR`, `MIC_VALUE_uM`) and compute initial RDKit descriptors from `SMILES`.
6. In `ecoli_inhibition_ml.ipynb`, use regression, ANN, and clustering/UMAP exploratory models to test whether exact `INHIB_AVE` prediction is reliable.
7. Reframe the task as hit classification after observing that high-inhibition compounds are better treated as a prioritization problem.
8. In `svm_linear_log_cluster.ipynb`, test classification thresholds with SVM and GLM/logistic models. We first tried a broader top-30% label, but it was not selective enough for identifying the strongest compounds, so we shifted toward a stricter top-10% hit definition. UMAP, KMeans, and GMM visualizations also helped show that the data had structure but did not cleanly separate by simple descriptor space alone.
9. We considered even stricter labels such as top 5%, but that would make the positive class very small and the test-set evaluation less stable. Top 10% became a better balance between focusing on true high-priority hits and keeping enough samples for modeling.
10. In `elasticnet_LogisticRegression_ml.ipynb`, run an unsupervised view of chemistry space using UMAP on Morgan fingerprints and KMeans (k=5) clustering to confirm that one chemistry family is enriched in actives, motivating the supervised pipeline that follows.
11. In `elasticnet_LogisticRegression_ml.ipynb`, build final features from assay context, RDKit descriptors, MACCS keys, 2048-bit Morgan fingerprints, and 20 Tanimoto similarity features based on top-10% inhibition compounds (Tanimoto reference compounds come from buffer-filtered model-training rows only).
12. In `elasticnet_LogisticRegression_ml.ipynb`, apply a stratified 80/20 holdout test split, then split the training side again into model-training and validation. Apply the buffer filter (`|INHIB_AVE - cutoff| < 1.5 × INHIB_STD`) to model-training rows only; validation and test stay untouched.
13. In `elasticnet_LogisticRegression_ml.ipynb`, train the final scikit-learn Elastic Net Logistic Regression model using `LogisticRegressionCV`. The model searches over `C = [0.003, 0.005, 0.007, 0.01, 0.015, 0.02, 0.03, 0.05]` and `l1_ratio = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]` with 5-fold cross-validation scored by F1. Evaluate the trained model on the held-out test set at the default `0.5` threshold using precision, recall, F1, ROC-AUC, balanced accuracy, and confusion matrices.
14. In `elasticnet_LogisticRegression_ml.ipynb`, run an ablation section that refits the same model on simplified inputs (DMAX-only, without the 20 Tanimoto similarity features, no buffer filter) to confirm that the engineered Tanimoto features and the buffer filter both contribute, while `DMAX_AVE` alone is already a strong but insufficient predictor.

## Final Model Summary
- Final task: classify whether a compound is in the top 10% of *E. coli* inhibition based on `INHIB_AVE`.
- Final model: scikit-learn `LogisticRegressionCV` with the elastic-net penalty. Hyperparameters are chosen with 5-fold cross-validation scored by F1 over `C = [0.003, 0.005, 0.007, 0.01, 0.015, 0.02, 0.03, 0.05]` and `l1_ratio = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]`. Class imbalance is handled with `class_weight="balanced"`.
- Input table: `ecoli_merged_master_4268.csv`.
- Data split: stratified 80/20 holdout test split, then a second 80/20 split on the training side into model-training and validation. Buffer filter (`BUFFER_K = 1.5`) is applied to model-training rows only; validation and test remain untouched.
- Main feature engineering: assay-aware features, RDKit descriptors, MACCS keys, 2048-bit Morgan fingerprints, and 20 extra Tanimoto similarity features based on top-10% inhibition compounds, computed from the 2048-bit Morgan fingerprints. Tanimoto reference compounds come from buffer-filtered model-training rows only to avoid leakage.
- Final selected predictors: the Elastic Net model reduces the 2,447-feature input to **3 non-zero predictors** — `DMAX_AVE` (~82% contribution), `tan_morgan_top10_count_ge_0_50` (~9%), and `tan_morgan_top10_max` (~9%).
- Test-set metrics at the default 0.50 threshold of top10% inhibition classification in `elasticnet_LogisticRegression_ml.ipynb`: `accuracy = 0.940`, `balanced accuracy = 0.852`, `precision = 0.685`, `recall = 0.741`, `F1 = 0.712`, `ROC-AUC = 0.950`.
- Main metrics emphasized: precision, recall, F1, and ROC-AUC, since this is an imbalanced top 10% classification problem where finding true high-inhibition compounds matters more than raw accuracy alone.
- Ablation tests: the notebook compares the full model against three simplified variants: `DMAX_AVE` only, the full feature matrix without Tanimoto similarity features, and the full feature matrix without the buffer filter on model-training rows. The results show that `DMAX_AVE` alone is already a strong predictor, but the full model gives a better overall balance of precision, recall, F1, and ROC-AUC. Removing the Tanimoto features lowers recall and F1, suggesting that similarity to top-10% inhibition compounds adds useful chemical context. Removing the buffer filter slightly improves recall, but it also increases false positives and lowers F1, so the buffered full model is the better final choice.


# Project Code Run — Setup

## Requirements
- Conda (Anaconda or Miniconda)
- Make

---

## Setup Instructions

### 1. Create environment
```bash
make create
```

### 2. Install packages
```bash
make install
```

### 3. Activate environment
```bash
conda activate chem277a_project2_env
```

---

## Makefile Commands

- `make create` → create Conda environment  
- `make install` → install dependencies  
- `make activate` → show activation command  