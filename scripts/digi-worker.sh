## Setup and run k4run instance
## Args: input_file output_prefix [nevents=-1 [skipevents=0 [nBIB=10]]]
## Notes:
## - FIXME: k4run does not support skipEvents!!
## - randomizes BIB selection; select nBIB files
## - if a workspace folder is provided below, the environment is setup to include local packages
## - provided as template and, while it might fit many use-cases, it's meant to be customized
## - ultimately, a k4runTaskList handler for pytaskfarmer should incorporate these functionalities and is preferred, when possible.

# Settings

IN_PATH="/global/cfs/cdirs/atlas/rbgarg/MuonCollider/data/samples/pt0-5000GeV_n10000_pdg13_MuColl_v1/sim/"
OUT_PATH="/global/cfs/projectdirs/atlas/arastogi/MuonCollider/data/MuCol_v1/RealDigi/K4run/WithBIB/"
BIB_MUPLUS_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/bib/10TeV-2023/MuColl_v1/sim_mp_pruned"
BIB_MUMINUS_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/bib/10TeV-2023/MuColl_v1/sim_mm_pruned"

random_postfix=`echo $RANDOM | md5sum | head -c 6`
RUN_PATH="${SCRATCH}/muc-digirun-${random_postfix}" #temporary unique running path

CONFIG_PATH="/global/cfs/projectdirs/atlas/arastogi/MuonCollider/code/TrkHitsStudiesWorkspace/configs/"
CONFIG_FILE="digi_steer_MuColv1.py" #relative to $CONFIG_PATH
GEO_CONFIG="/opt/spack/opt/spack/linux-almalinux9-x86_64/gcc-11.3.1/lcgeo-0.20-grx3loszut2wlx5dbtguwxcuxs7whjad/share/lcgeo/compact/MuColl/MuColl_v1/MuColl_v1.xml"

WORKSPACE_PATH="/global/cfs/projectdirs/atlas/arastogi/MuonCollider/code/TrkHitsStudiesWorkspace"
MYBUILD="build" #build folder (either relative to $WORKSPACE_PATH or absolute path

TIME="Time %E (%P CPU)\nMem %Kk/%Mk (avg/max): %Xk(shared) + %Dk(data)\nI/O %I+%O; swaps: %W"


# Utility functions
tell () {
    now=`date +"%4Y.%m.%d-%H.%M.%S"`
    echo "${now} digi-worker: $1"
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
if ! [ -z "$3" ]; then
    N_EVENTS_PER_JOB=$3
    
    N_SKIP_EVENTS=0
    if ! [ -z "$4" ]; then
	N_SKIP_EVENTS=$4
    fi

    # update output file
    MAX_EVENT=$(( N_SKIP_EVENTS + N_EVENTS_PER_JOB - 1 ))
    OUT_FILE_PREFIX="${OUT_FILE_PREFIX}_${N_SKIP_EVENTS}-${MAX_EVENT}"
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
    echo "PATH=${PATH}"
fi

tell "Preparing to run"
mkdir -p ${RUN_PATH}
cd ${RUN_PATH}

cp -r ${CONFIG_PATH}/${CONFIG_FILE} . #copy the config file

tell "Randomizing BIB selection"
NBIBs=2
if ! [ -z "$5" ]; then
    NBIBs=$5
fi

tell "Running k4run..."
#/usr/bin/time --format="${TIME}" --

k4run --num-events ${N_EVENTS_PER_JOB} ${CONFIG_FILE} --DD4hepXMLFile ${GEO_CONFIG} --LcioEvent.Files ${IN_FILE} --doOverlayFull --OverlayFullPathToMuPlus "${BIB_MUPLUS_DIR}" --OverlayFullPathToMuMinus "${BIB_MUMINUS_PATH}" --OverlayFullNumberBackground ${NBIBs} &> ${OUT_FILE_PREFIX}.log
# --global.SkipNEvents=${N_SKIP_EVENTS}
tell "k4run DONE."

# Copy output
tell "Copying output from current folder ($PWD) to ${OUT_PATH}"
ls -lh
tell "----------"

copyout output_digi_light.slcio ${OUT_FILE_PREFIX}.slcio
copyout ${OUT_FILE_PREFIX}.log ""
copyout output_digi.root ${OUT_FILE_PREFIX}.root


tell "All Done."
