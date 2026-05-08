ENV_NAME = chem277a_project2_env
PYTHON = python=3.11

create:
	conda create -y -n $(ENV_NAME) $(PYTHON)

install:
	conda install -y -n $(ENV_NAME) \
		numpy pandas matplotlib seaborn scipy statsmodels scikit-learn \
		tensorflow jupyter notebook nltk

	conda install -y -c conda-forge -n $(ENV_NAME) \
		rdkit umap-learn pyclustering

activate:
	@echo "Run:"
	@echo "conda activate $(ENV_NAME)"