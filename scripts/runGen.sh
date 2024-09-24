#!/bin/bash


nEvts=10
nPar_per_Evt=1
ptmin=10
ptmax=100
pdg=13


source gen-worker_1.sh --num-events ${nEvts} --npar-per-event ${nPar_per_Evt} --pt-min ${ptmin} --pt-max ${ptmax} --pdg ${pdg}
