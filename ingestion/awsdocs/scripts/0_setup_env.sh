conda env create --prefix ./conda-env --file=conda-env.yaml ||:
eval "$(conda shell.bash hook)"
conda activate ./conda-env
pip install -r requirements.txt