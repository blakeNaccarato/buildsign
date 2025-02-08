set -o errexit -o nounset -o pipefail -o xtrace
if [ -n "${1:-}" ]; then
    cd "$1"
fi
