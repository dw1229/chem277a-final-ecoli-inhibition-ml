# Chem277A Project 2

**Team:** Priscilla Vaskez · Trinity Ho · Yasemin Sucu · Dongwan Kim

## Project Idea
Predict the antibacterial inhibition rate against *E. coli* (`INHIB_AVE`) using a combination of molecular descriptors computed from small-molecule SMILES data (for example: molecular weight, logP, TPSA) and experimental features extracted directly from the CO-ADD dataset (for example: `INHIB_STD`, `NASSAYS`, `DMAX_AVE`, MIC-derived features). Our models learn to predict the continuous inhibition percentage directly from these features. We train and compare three classical ML regression models.

## Dataset
- Source: CO-ADD (Community for Open Antimicrobial Drug Discovery) database
- Download page: https://db.co-add.org/downloads
- Data format: CSV (InhibitionData + DoseResponseData)

## Basic Workflow
1. Download complete CO-ADD CSV datasets.
2. Filter *E. coli* rows from both files and merge using exact experiment keys (`COADD_ID`, `STRAIN`, `ASSAY_ID`) so inhibition and dose-response values come from the same assay context.
3. Keep exact-matched rows (~4,268 rows across ~4,174 unique compounds), drop unnecessary text columns like `COMPOUND_NAME`, and inspect missing values.
4. Parse `DRVAL_MEDIAN` into `MIC_OPERATOR` + numeric MIC value, then convert mixed MIC units (`uM` / `ug/mL`) into a unified `MIC_VALUE_uM`.
5. Compute RDKit descriptors from `SMILES` (MW, logP, TPSA, HBD, HBA, RotBonds, Rings, ArRings, QED) and append them to the merged table.
6. Save the processed master table (`ecoli_merged_master_4268.csv`) for reuse.
7. Define numeric feature columns, build `X` and `y` (`INHIB_AVE` as target), split train/test, and apply `StandardScaler`.
8. Train and compare regression models, then evaluate using RMSE, MAE, R², and related metrics.