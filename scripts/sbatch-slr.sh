#!/bin/sh
#SBATCH --output=sim-slr-%j.out
#SBATCH --error=sim-slr-%j.err
#SBATCH --account=atlas
#SBATCH --constraint=cpu
#SBATCH --qos=regular
#SBATCH --time=02:00:00
#SBATCH --tasks-per-node=1
## SBATCH --image=infnpd/mucoll-ilc-framework:1.6-centos8
## SBATCH --export=SCRATCH
## SBATCH --array 1 10

###########
# Submission script to slurm for sbatch
# Usage: $0 tasklist [workdir=$PWD/wkdir [nprocesses]]
# Notes:
# - nprocesses by defualt is determined from the number of tasks (but max. 256)
# - if submitting a job arrach (e.g. with --array 1-10),
#   then tasklist is assumed to be tasklistXXX,
#   where XXX is the 3-digits zero-padded ${SLURM_ARRAY_TASK_ID}
###########


# Utility functions for job handling

function handle_signal
{
    echo "$(date) bash is being killed, also kill ${PROCPID}"
    kill -s USR1 ${PROCPID}
    wait ${PROCPID}
}
trap handle_signal INT USR1


# Check command-line arguments

if [ ${#} != 1 ] && [ ${#} != 2 ] && [ ${#} != 3 ]; then
    echo "usage: ${0} tasklist [workdir=$PWD/wkdir [nprocesses]]"
    exit 1
fi


# Determine tasklist and, number of parallel processes and other settings

TASKID=""
if ! [ -z "${SLURM_ARRAY_TASK_ID}" ]; then
    printf -v TASKID "%03d" ${SLURM_ARRAY_TASK_ID}
fi
tasklist="${1}${TASKID}"

workdir="${PWD}/wkdir"
if ! [ -z "$2" ]; then
    workdir="${2}${TASKID}"
fi

N_PARALLEL_JOBS=`cat $tasklist | grep -v '^#.*$' | grep -v '^[[:blank:]]*$' | wc -l`
if [ ${N_PARALLEL_JOBS} -gt 256 ]; then
    # reduce to max two processes per CPU
    N_PARALLEL_JOBS=256
fi
if ! [ -z "$3" ]; then
    N_PARALLEL_JOBS=$3
fi


# Prepare to execute

echo "$(date) About to execute on machine / cwd / arguments:"
hostname
uname -a
pwd
echo "tasklist = ${tasklist}"
echo "proc = ${N_PARALLEL_JOBS}"

#1) Run pytaskfarmer inside the container (uncomment the image option for SBATCH above)
#   pro: run shifter only once,
#   cons: requires recent version of python & taskfarmer available in the container
#shifter --module=cvmfs /bin/bash -c "pytaskfarmer.py --proc ${N_PARALLEL_JOBS} --workdir ${workdir} ${tasklist}"

#2) Run pytaskfarmer using a shifter runner for MCD:
pytaskfarmer.py --proc ${N_PARALLEL_JOBS} --workdir ${workdir} --runner mcd_shifter ${tasklist}

export PROCPID=${!}


# Wait for the end of execution

wait ${PROCPID}
echo "$(date) Finish running!"
