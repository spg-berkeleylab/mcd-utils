# Configuration file containing event setting

# Settings
USERNAME="rbgarg"
pwd=${PWD}
# Initializing arguments with default values
NEVENTS=1
NPAR_PER_EVT=1
PDG=13
PT_MIN=0
PT_MAX=10
GEN_OUTFILE_PREFIX="pgun_mu"

# Defining required paths
BENCHMARKS="/global/cfs/cdirs/atlas/${USERNAME}/MuonCollider/mucoll-benchmarks/"
DATA_PATH="/global/cfs/cdirs/atlas/${USERNAME}/MuonCollider/data/samples/"
MCD_UTILS="/global/cfs/cdirs/atlas/${USERNAME}/mcd-utils/"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--num-events)
      NEVENTS="$2"
      shift 2
      ;;
    -p|--npar-per-event)
      NPAR_PER_EVT="$2"
      shift 2
      ;;
    -i|--pdg)
      PDG="$2"
      shift 2
      ;;
    -m|--pt-min)
      PT_MIN="$2"
      shift 2
      ;;
    -s|--pt-max)
      PT_MAX="$2"
      shift 2
      ;;
    -o|--out-file-prefix)
      GEN_OUTFILE_PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [-n num-events] [-p npar-per-event] [-i pdg] [-m pt-min] [-s pt-max] [-o out-file-prefix]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

DIRKEY="pt${PT_MIN}-${PT_MAX}GeV_n${NEVENTS}_pdg${PDG}"
GEN_OUT_PATH=${DATA_PATH}/${DIRKEY}/gen

# Check if output path exists
if [ ! -d "${GEN_OUT_PATH}" ]; then
    echo "Making Directory: ${GEN_OUT_PATH}"
    mkdir -p ${GEN_OUT_PATH}
else
    echo "Directory ${GEN_OUT_PATH} already exists"
fi
