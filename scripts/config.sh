# Configuration file containing event setting

# Settings
USERNAME=${USER}
pwd=${PWD}

# Initializing arguments with default values
RUN_TYPE="temp"
NEVENTS=1
NPAR_PER_EVT=1
PDG=13
PT_MIN=0
PT_MAX=10
N_SKIP_EVENTS=0
OUT_DIR="temp"
IN_FILE_PREFIX="f_temp"
OUT_FILE_PREFIX="temp"
OVERLAY_NUMBKG=192

# Defining required paths
BENCHMARKS="/global/cfs/cdirs/atlas/${USERNAME}/MuonCollider/mucoll-benchmarks/"
TRACKPERF_PATH="/global/cfs/cdirs/atlas/${USERNAME}/MuonCollider/TrackPerfWorkspace/"
DATA_PATH="/global/cfs/cdirs/atlas/${USERNAME}/MuonCollider/data/samples/"
MCD_UTILS="/global/cfs/cdirs/atlas/${USERNAME}/mcd-utils/"
BIB_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/bib/"
BIB_MUPLUS="${BIB_PATH}/10TeV-2023/MuColl_v1/sim_mp_pruned/"
BIB_MUMINUS="${BIB_PATH}/10TeV-2023/MuColl_v1/sim_mm_pruned/"


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--run-type)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            RUN_TYPE="$2"
            shift 2
            ;;
        -n|--num-events)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            NEVENTS="$2"
            shift 2
            ;;
        -p|--npar-per-event)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            NPAR_PER_EVT="$2"
            shift 2
            ;;
        -i|--pdg)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            PDG="$2"
            shift 2
            ;;
        -m|--pt-min)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            PT_MIN="$2"
            shift 2
            ;;
        -s|--pt-max)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            PT_MAX="$2"
            shift 2
            ;;
        -k|--n-skip-events)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            N_SKIP_EVENTS="$2"
            shift 2
            ;;
        -f|--in-file-prefix)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            IN_FILE_PREFIX="$2"
            shift 2
            ;;
        -o|--out-dir)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            OUT_DIR="$2"
            shift 2
            ;;
        -d|--out-file-prefix)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            OUT_FILE_PREFIX="$2"
            shift 2
            ;;
        -v|--overlay-numbkg)
            [[ -z "$2" || "$2" =~ ^- ]] && { echo "Error: Missing value for $1"; exit 1; }
            OVERLAY_NUMBKG="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]
Options:
  -r, --run-type           Run type (e.g., simulation, analysis)
  -n, --num-events         Number of events to process
  -p, --npar-per-event     Number of particles per event
  -i, --pdg               Particle Data Group (PDG) code
  -m, --pt-min             Minimum transverse momentum
  -s, --pt-max             Maximum transverse momentum
  -k, --n-skip-events      Number of events to skip
  -f, --in-file-prefix     Input file prefix
  -o, --out-dir            Output directory
  -d, --out-file-prefix    Output file prefix
  -v, --overlay-numbkg     Number of background overlays
  -h, --help               Show this help message and exit
"
            exit 0
            ;;
        *)
            echo "Unknown option: $1. Use -h for help."
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$RUN_TYPE" || -z "$OUT_DIR" ]]; then
    echo "Error: Missing required arguments. Use -h for help."
    exit 1
fi

#DIRKEY="pt${PT_MIN}-${PT_MAX}GeV_n${NEVENTS}_pdg${PDG}"
#OUT_PATH=${DATA_PATH}/${DIRKEY}/${OUT_DIR}
OUT_PATH=${DATA_PATH}/${OUT_DIR}
IN_FILE=${DATA_PATH}/${IN_FILE_PREFIX}

# Check if output path exists
if [ ! -d "${OUT_PATH}" ]; then
    echo "Making Directory: ${OUT_PATH}"
    mkdir -p ${OUT_PATH}
else
    echo "Directory ${OUT_PATH} already exists"
fi
