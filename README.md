# Chem277A Project 2

**Team:** Priscilla Vaskez · Trinity Ho · Yasemin Sucu · Dongwan Kim

## Project Idea
Predict the antibacterial inhibition rate against *E. coli* (`INHIB_AVE_MEAN`) using a combination of molecular descriptors computed from small-molecule SMILES data (for example:  molecular weight, logP, TPSA) and experimental features extracted directly from the `CO-ADD` dataset (for example:  INHIB_STD_MEAN, NASSAYS). Our models learn to predict the continuous inhibition percentage directly from these features. We train and compare three classical ML regression models.

## Dataset
- Source: CO-ADD (Community for Open Antimicrobial Drug Discovery) database
- Download page: https://db.co-add.org/downloads
- Data format: CSV (InhibitionData + DoseResponseData)

## Basic Workflow
1. Download complete CO-ADD CSV datasets.
2. Filter *E. coli* rows from both files and merge on `COADD_ID` (inner join, ~4,174 compounds).
3. Extract the `SMILES` column from the merged dataset and compute molecular descriptors using RDKit (MW, logP, TPSA, HBD, HBA, QED, etc.).
4. Concatenate RDKit descriptors and CO-ADD experimental features (INHIB_STD_MEAN, NASSAYS_MAX, DMAX_AVE_MEAN, etc.) into a single pandas DataFrame, where `X = all features` and `y = INHIB_AVE_MEAN(regression target)`.
5. Run EDA with visualizations to explore feature distributions and correlations.
6. Preprocess features with StandardScaler and apply feature selection (Regularizaiton/PCA).
7. Train and compare three classical regression models.
8. Evaluate models using RMSE, MAE, R², and other metrics, and compare performance across models.