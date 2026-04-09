# Chem277A Project 2

## Project Idea
Predict antibacterial activity against *E. coli* using molecular descriptors from small-molecule SMILES data.

## Dataset
- Source: CO-ADD database
- Download page: https://db.co-add.org/downloads
- Data format: CSV

## Basic Workflow
1. Download complete CO-ADD CSV datasets.
2. Filter rows related to *E. coli* activity.
3. Create a binary label (active vs inactive).
4. Compute molecular descriptors from SMILES.
5. Train and compare classical ML models (for example: Logistic Regression, Random Forest, SVM).
6. Run simple EDA and evaluation (optionally feature selection/PCA).