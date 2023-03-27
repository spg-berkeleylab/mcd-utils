## User(SPG)-defined aliases for muon collider setup

echo "Setup environment config for muon-collider image"

MUC_HOME="/global/cfs/cdirs/atlas/${USER}/MuonCollider/"
alias acode="cd ${MUC_HOME}/code/"
alias aproject='cd ${MUC_HOME}/data/'

alias ll='ls -ltrh --color=tty'

export PS1="\u@\H:\W> "

if ! [ -z "${SHIFTER_IMAGEREQUEST}" ]; then
  imageStr=`echo ${SHIFTER_IMAGEREQUEST} | rev | cut -d '/' -f 1 | rev | cut -d: -f 2`
  export PS1="${imageStr}:\W> "
fi

# Fix font when logging from NX Client
#export FONTCONFIG_PATH=/etc/fonts

# Setup ILC software
#source /opt/ilcsoft/init_ilcsoft.sh
source /opt/ilcsoft/muonc/init_ilcsoft.sh
