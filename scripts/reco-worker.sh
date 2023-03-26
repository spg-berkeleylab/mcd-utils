## Setup and run ddsim instance
## Args: job_number (e.g. from job array)

# Settings

IN_PATH="/home/spagan/mcprod-hZ_wzf_3mu/sim.off"
BIB_PATH="/data/BIB/MuCollv1_25ns_nEkin150MeV_QGSPBERT/"
OUT_PATH="/home/spagan/mcprod-hZ_wzf_3mu/out.off"
RUN_PATH="/home/spagan/mcprod-hZ_wzf_3mu/run.off" #temporary unique running path
N_EVENTS_PER_JOB=2

#IN_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/......"
#BIB_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/......"
#OUT_PATH="/global/cfs/cdirs/atlas/spgriso/MuonCollider/data/......"
CONFIG_PATH="${PWD}/config"
#RUN_PATH="${SCRATCH}/....." #temporary unique running path
#N_EVENTS_PER_JOB=100
N_JOBS_PER_FILE=10 # events per file / N_EVENTS_PER_JOB
TIME="Time %E (%P CPU)\nMem %Kk/%Mk (avg/max): %Xk(shared) + %Dk(data)\nI/O %I+%O; swaps: %W"

# Utility functions
tell () {
    now=`date +"%4Y.%m.%d-%H.%M.%S"`
    echo "${now}-sim-worker: $1"
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
    quit "ERROR! Need a job_number as argument." 1
fi
IDX=$1
tell "Starting job $IDX"

N_JOB=$(( $IDX % ${N_JOBS_PER_FILE} ))
N_FILE=$(( $IDX / ${N_JOBS_PER_FILE} + 1  ))
IN_FILE="${IN_PATH}/sim-${N_FILE}.slcio"
N_SKIP_EVENTS=$(( ${N_JOB} * ${N_EVENTS_PER_JOB} ))
OUT_FILE_PREFIX="./reco-${IDX}"


tell "Using input ${IN_FILE} (start evt: ${N_SKIP_EVENTS}, n. evt: ${N_EVENTS_PER_JOB})"

# Prepare and run Marlin
tell "Preparing to run"
mkdir -p ${RUN_PATH}
cd ${RUN_PATH}

cp -r ${CONFIG_PATH}/...... #TODO, copy whole config

tell "Randomizing BIB selection"
BKGPre="sim_mumu-1e3x500-26m-lowth-excl_seed"
BKGPost="_allHits.slcio"
BKGTot=1000
NBIBs=10
BIBs=()
#for i in {1..${NBIBs}}; do
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
tell "BIBs list: ${BIBs}"
tell "--------"


tell "Running Marlin..."
shopt -s expand_aliases
source /opt/ilcsoft/muonc/init_ilcsoft.sh
#/usr/bin/time --format="${TIME}" --
echo time Marlin --global.LCIOInputFiles=${IN_FILE} --global.MaxRecordNumber=${N_EVENTS_PER_JOB} --global.SkipNEvents=${N_SKIP_EVENTS} --OverlayTrimmed.BackgroundFileNames="${BIBs[*]}"  actsseedckf_steer.xml &> ${OUT_FILE_PREFIX}.log

tell "Marlin DONE."

# Copy output
tell "Copying output from current folder ($PWD) to ${OUT_PATH}"
ls -lh
tell "----------"

copyout Output_REC.slcio ${OUT_FILE_PREFIX}.slcio
copyout ${OUT_FILE_PREFIX}.log ""
copyout lctuple_actsseedcdk.root ${OUT_FILE_PREFIX}.root


tell "All Done."
