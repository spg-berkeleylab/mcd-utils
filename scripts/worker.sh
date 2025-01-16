#!/bin/bash

# Source configuration file
CONFIG_FILE="config.sh"
tell "=====sourcing Config file====="
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
else
    echo "Configuration file not found: ${CONFIG_FILE}"
    exit 1
fi

# Utility functions sourced
tell "=====sourcing Utility functions======"
source ${MCD_UTILS}/scripts/utils.sh

random_postfix=$(echo $RANDOM | md5sum | head -c 6)
RUN_PATH="${SCRATCH}/muc-run-${random_postfix}" #temporary unique running path
tell "=====Running inside ${RUN_PATH}..."
mkdir -p ${RUN_PATH}
cd ${RUN_PATH}

if [ ${RUN_TYPE} == "gen" ]; then

    tell "=====Running Event Generation====="
    time ${BENCHMARKS}/generation/pgun/pgun_lcio.py --events ${NEVENTS} --particles ${NPAR_PER_EVT} --pdg ${PDG} --pt ${PT_MIN} ${PT_MAX} --theta 10 170 -- ${OUT_FILE_PREFIX}.slcio &> ${OUT_FILE_PREFIX}.log

    tell "=====Generation DONE!!"

elif [ ${RUN_TYPE} == "sim" ]; then

    tell "=====Running Event Simulation====="
    time ddsim --steeringFile ${BENCHMARKS}/simulation/ilcsoft/steer_baseline.py --inputFile ${IN_FILE}.slcio --outputFile ${OUT_FILE_PREFIX}.slcio --numberOfEvents ${NEVENTS} --skipNEvents ${N_SKIP_EVENTS} &> ${OUT_FILE_PREFIX}.log

    tell "=====Simulation DONE!!"
    
elif [ ${RUN_TYPE} == "digi" ]; then
    
    tell "=====Running Event Digitization without BIB====="
    time k4run ${BENCHMARKS}/digitisation/k4run/digi_steer.py --LcioEvent.Files ${IN_FILE}.slcio --OutputDigiFileName ${OUT_FILE_PREFIX}.slcio --nEvents ${NEVENTS} &> ${OUT_FILE_PREFIX}.log
    tell "=====Digitization without BIB DONE!!"
    
elif [ ${RUN_TYPE} == "digi_withBIB" ]; then
    
    tell "=====Running Event Digitization with BIB====="
    time k4run ${BENCHMARKS}/digitisation/k4run/digi_steer.py --LcioEvent.Files ${IN_FILE}.slcio --OutputDigiFileName ${OUT_FILE_PREFIX}.slcio --doOverlayFull --OverlayFullPathToMuPlus ${BIB_MUPLUS} --OverlayFullPathToMuMinus ${BIB_MUMINUS} --OverlayFullNumberBackground ${OVERLAY_NUMBKG} --nEvents ${NEVENTS} &> ${OUT_FILE_PREFIX}.log
    tell "=====Digitization with BIB DONE!!"
    
elif [[ ${RUN_TYPE} == "reco" || ${RUN_TYPE} == "reco_withBIB" ]]; then

    tell "=====Running Event reconstruction====="
    cp -a ${BENCHMARKS}/reconstruction/k4run/PandoraSettings ./
    time k4run ${BENCHMARKS}/reconstruction/k4run/reco_steer.py --LcioEvent.Files ${IN_FILE}.slcio --MatFile "${TRACKPERF_PATH}/packages/ACTSTracking/data/material-maps.json" --TGeoFile "${TRACKPERF_PATH}/packages/ACTSTracking/data/MuColl_v1.root" &> ${OUT_FILE_PREFIX}.log
    rm -r PandoraSettings
    tell "=====Event reconstruction DONE!!"
    
else
    echo "Wrong Argument"
fi

# Copy output
tell "Copying output from current folder ($PWD) to ${OUT_PATH}"
ls -lh
tell "----------"

copyout . ${OUT_PATH}

cd ${pwd}

##Deleting the RUN_PATH if empty
if [ -z "$(ls -A ${RUN_PATH})" ]; then
    tell "=====Deleting ${RUN_PATH}"
    rm -rf ${RUN_PATH}
fi

tell "=====All DONE!!"
