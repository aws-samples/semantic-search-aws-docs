SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

#MAIN=dirname "$0"

echo "script_dir MAIN: $SCRIPT_DIR"
bash $SCRIPT_DIR/clone_awsdocs.sh $1
bash $SCRIPT_DIR/run_ingestion.sh $2