#!/bin/sh
#SBATCH --output=sim-slr-%j.out
#SBATCH --error=sim-slr-%j.err
#SBATCH --account=atlas
#SBATCH --qos=regular
#SBATCH --time=02:00:00
#SBATCH --tasks-per-node=1
#SBATCH --image=infnpd/mucoll-ilc-framework:1.6-centos8
#SBATCH --export=SCRATCH
#SBATCH --array=1-20

function handle_signal
{
    echo "$(date) bash is being killed, also kill ${PROCPID}"
    kill -s USR1 ${PROCPID}
    wait ${PROCPID}
}
trap handle_signal INT USR1

if [ ${#} != 1 ]; then
    echo "usage: ${0} tasklist"
    exit 1
fi
workdir="wk-${TASKID}"
tasklist=sim-tasks-${TASKID}.txt
logdir=${tasklist}_logs

hostname
uname -a
pwd
echo "tasklist = ${tasklist}"

${HOME}/mcgen/pytaskfarmer/pytaskfarmer.py --logDir ${logdir} --proc 32 ${tasklist} &
export PROCPID=${!}
wait ${PROCPID}
echo "$(date) Finish running!"

#shifter --module=cvmfs /bin/bash sim-worker.sh ${TASKID}
#shifter --module=cvmfs /bin/bash pytaskfarmer.py ${tasklist}
${HOME}/utils/pytaskfarmer/pytaskfarmer.py --proc 32 --workdir ${workdir} --logDir ${logdir} --runner mcd-runner ${tasklist}

