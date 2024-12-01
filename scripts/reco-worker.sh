## Setup and run Marlin instance
## Args: input_file output_prefix [nevents=-1 [skipevents=0 [nBIB=10]]]
## Notes:
## - randomizes BIB selection; select nBIB files
## - if a workspace folder is provided below, the environment is setup to include local packages
## - provided as template and, while it might fit many use-cases, it's meant to be customized
## - ultimately, a MarlinTaskList handler for pytaskfarmer should incorporate these functionalities and is preferred, when possible.

# Settings

IN_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/samples/mcprod-hZ_wzf_3mu/sim"
OUT_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/samples/mcprod-hZ_wzf_3mu/rec"
BIB_PATH="/data/bib/MuCollv1_25ns_nEkin150MeV_QGSPBERT/"

random_postfix=`echo $RANDOM | md5sum | head -c 6`
RUN_PATH="${SCRATCH}/muc-recrun-${random_postfix}" #temporary unique running path

CONFIG_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/samples/mcprod-hZ_wzf_3mu/rec/config"
CONFIG_FILE="actsseedckf_steer.xml" #relative to $CONFIG_PATH

WORKSPACE_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/code/mcprod-hZ_wzf_3mu"
MYBUILD="build" #build folder (either relative to $WORKSPACE_PATH or absolute path

TIME="Time %E (%P CPU)\nMem %Kk/%Mk (avg/max): %Xk(shared) + %Dk(data)\nI/O %I+%O; swaps: %W"


# Utility functions
tell () {
    now=`date +"%4Y.%m.%d-%H.%M.%S"`
    echo "${now} reco-worker: $1"
}

quit () {
    tell "$1"
    sleep 0.1
    exit $2
}

copyout() {
  IN=$1
  OUT=$2
  if [ -f $1 ]; then
  	if ! mv ${IN} ${OUT_PATH}/${OUT} ; then
	    tell "ERROR! Failed to transfer ${IN} -> ${OUT}"
 	fi
  else
    tell "ERROR! File ${IN} does not exist"
  fi	
}

# Determine input file and events
if [ -z "$1" ]; then
    quit "ERROR! Usage: $0 input_file output_prefix [nevents=-1 [skipevents=0 [nBIB=10]]]" 1
fi
IN_FILE="${IN_PATH}/$1"

if [ -z "$2" ]; then
    quit "ERROR! Usage: $0 input_file output_prefix [nevents=-1 [skipevents=0 [nBIB=10]]]" 1
fi
OUT_FILE_PREFIX=$2


N_EVENTS_PER_JOB=-1
MAX_MARLIN_RECORD=-1 #to adapt to the way Marlin input processor sets nEvents
if ! [ -z "$3" ]; then
    N_EVENTS_PER_JOB=$3
    MAX_MARLIN_RECORD=$((N_EVENTS_PER_JOB + 1))
    
    N_SKIP_EVENTS=0
    if ! [ -z "$4" ]; then
	N_SKIP_EVENTS=$4
    fi
    # update output file
    MAX_EVENT=$(( N_SKIP_EVENTS + N_EVENTS_PER_JOB - 1 ))
    OUT_FILE_PREFIX="${OUT_FILE_PREFIX}_${N_SKIP_EVENTS}-${MAX_EVENT}"
fi
else
    source /opt/ilcsoft/muonc/init_ilcsoft.sh
fi


tell "Input: ${IN_FILE} (start evt: ${N_SKIP_EVENTS}, n. evt: ${N_EVENTS_PER_JOB})."
tell "Output: ${OUT_FILE_PREFIX}.slcio/.log"

# Prepare and run Marlin
if ! [ -z "${WORKSPACE_PATH}" ]; then
    tell "Setting up workspace environment"
    cd ${WORKSPACE_PATH}    
    tell "Local packages:"
    for pkglib in `find ${MYBUILD}/packages -name '*.so' -type l -o -name '*.so' -type f`; do
	pkgname=$(basename ${pkglib})
	tell "- ${pkgname}"
    done
		  
    if ! [ -r "setup.sh" ]; then
	quit "Workspace provided (${WORKSPACE_PATH}), but no 'setup.sh' found."
    fi
    source setup.sh $MYBUILD
    echo "MARLIN_DLL=${MARLIN_DLL}"
fi

tell "Preparing to run"
mkdir -p ${RUN_PATH}
cd ${RUN_PATH}

cp -r ${CONFIG_PATH}/* . #copy the whole config (e.g. Pandora wants it run-time there)

tell "Randomizing BIB selection"
NBIBs=10
if ! [ -z "$5" ]; then
    NBIBs=$5
fi
BKGPre="sim_mumu-1e3x500-26m-lowth-excl_seed"
BKGPost="_allHits.slcio"
BKGTot=1000
BIBs=()
for (( i=1; i<=${NBIBs}; i++ )); do
  RNDBKG=$(printf "%04d" $(($RANDOM % $BKGTot)) )
  BKGFILE=${BKGPre}${RNDBKG}${BKGPost}
  BIBFILE=BKG_seed${RNDBKG}.slcio  
  ln -s ${BIB_PATH}/$BKGFILE $BIBFILE #soft-link
  BIBs+=( $BIBFILE )
done
tell "List of BIB links created:"
ls -lh
tell "--------"
tell "BIBs list: ${BIBs[*]}"
tell "--------"


tell "Running Marlin..."
#source /opt/ilcsoft/muonc/init_ilcsoft.sh
#/usr/bin/time --format="${TIME}" --
time Marlin --global.LCIOInputFiles=${IN_FILE} --global.MaxRecordNumber=${MAX_MARLIN_RECORD} --global.SkipNEvents=${N_SKIP_EVENTS} --OverlayTrimmed.BackgroundFileNames="${BIBs[*]}"  ${CONFIG_FILE} &> ${OUT_FILE_PREFIX}.log

tell "Marlin DONE."

# Copy output
tell "Copying output from current folder ($PWD) to ${OUT_PATH}"
ls -lh
tell "----------"

copyout Output_REC.slcio ${OUT_FILE_PREFIX}.slcio
copyout ${OUT_FILE_PREFIX}.log ""
copyout lctuple_actsseedcdk.root ${OUT_FILE_PREFIX}.root


tell "All Done."
