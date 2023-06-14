SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

#MAIN=dirname "$0"

echo "script_dir MAIN: $SCRIPT_DIR"
python3.8 $SCRIPT_DIR/../src/ingest.py --src $1 --index_name $2