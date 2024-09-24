#!/bin/bash

# Source configuration file
CONFIG_FILE="config.sh"
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
else
    echo "Configuration file not found: ${CONFIG_FILE}"
    exit 1
fi

# Utility functions sourced
source ${MCD_UTILS}/scripts/utils.sh

# Debugging output to see the parsed arguments
tell "Running Event Generation with the following setting:"
tell "NEVENTS: ${NEVENTS}"
tell "NPAR_PER_EVENT: ${NPAR_PER_EVT}"
tell "PDG: ${PDG}"
tell "PT Range: ${PT_MIN} - ${PT_MAX}"
tell "OUTPUT PATH: ${OUT_PATH}"

random_postfix=$(echo $RANDOM | md5sum | head -c 6)
RUN_PATH="${SCRATCH}/muc-run-${random_postfix}" #temporary unique running path

# Run Generation
tell "Running Event Generation in ${RUN_PATH}..."
mkdir -p ${RUN_PATH}
cd ${RUN_PATH}

#source /opt/ilcsoft/muonc/init_ilcsoft.sh # ILC sw already setup in the script
#/usr/bin/time --format="${TIME}" --
time ${BENCHMARKS}/generation/pgun/pgun_lcio.py --events ${NEVENTS} --particles ${NPAR_PER_EVT} --pdg ${PDG} --pt ${PT_MIN} ${PT_MAX} --theta 10 170 -- ${OUT_FILE_PREFIX}.slcio &> ${OUT_FILE_PREFIX}.log

tell "Generation DONE."

# Copy output
tell "Copying output from current folder ($PWD) to ${OUT_PATH}"
ls -lh
tell "----------"

copyout ${OUT_FILE_PREFIX}.slcio ${OUT_PATH}
copyout ${OUT_FILE_PREFIX}.log ${OUT_PATH}

cd ${pwd}

##Deleting the RUN_PATH if empty
if [ -z "$(ls -A ${RUN_PATH})" ]; then
    echo "Deleting ${RUN_PATH}"
    rm -rf ${RUN_PATH}
    fi

tell "All Done."
