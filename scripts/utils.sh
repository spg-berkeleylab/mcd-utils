# utils.sh

# Utility functions

tell () {
    now=`date +"%4Y.%m.%d-%H.%M.%S"`
    echo "${now} Running: $1"
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
        if ! mv ${IN} ${OUT} ; then
            tell "ERROR! Failed to transfer ${IN} -> ${OUT}"
        fi
  else
    tell "ERROR! File ${IN} does not exist"
  fi
}
