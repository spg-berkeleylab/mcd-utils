#!/bin/bash

runType="reco" #"gen", "sim", "digi", "digi_withBIB", "reco", "reco_withBIB"
echo "RunType = $runType"

#Gen-parameters
nEvts=10
nPar_per_Evt=1
ptmin=10
ptmax=100
pdg=13
#digi-parameters
overlay_numBkg=2 #19, 100, 192 (BIB:1%, 10%, 50%, 100%)

in_file_prefix=
out_file_prefix=

if [ ${runType} == "gen" ]; then
    out_file_prefix="gen"
elif [ ${runType} == "sim" ]; then
    in_file_prefix="gen/gen"
    out_file_prefix="sim"
elif [[ ${runType} == "digi" || ${runType} == "digi_withBIB" ]]; then
    in_file_prefix="sim/sim"
    out_file_prefix="digi"
elif [ ${runType} == "reco" ]; then
    in_file_prefix="digi/output_digi"
    out_file_prefix="reco"
elif [ ${runType} == "reco_withBIB" ]; then
    in_file_prefix="digi_withBIB/output_digi"
    out_file_prefix="reco"
fi
echo "In_file_prefix = ${in_file_prefix}"
echo "Out_file_prefix = ${out_file_prefix}"

dirKey="pt${ptmin}-${ptmax}GeV_n${nEvts}_pdg${pdg}"
OutPath=${dirKey}/${runType}

if [ ${runType} == "gen" ]; then
    
    source worker.sh --run-type ${runType} --num-events ${nEvts} --npar-per-event ${nPar_per_Evt} --pt-min ${ptmin} --pt-max ${ptmax} --pdg ${pdg} --out-dir ${OutPath} --out-file-prefix ${out_file_prefix}
    
elif [ ${runType} == "sim" ]; then

    source worker.sh --num-events ${nEvts} --in-file-prefix ${dirKey}/${in_file_prefix} --out-dir ${OutPath} --out-file-prefix ${out_file_prefix} --run-type ${runType}
    
elif [ ${runType} == "digi" ]; then

    source worker.sh --num-events ${nEvts} --in-file-prefix ${dirKey}/${in_file_prefix} --out-dir ${OutPath} --out-file-prefix ${out_file_prefix} --run-type ${runType}
    
elif [ ${runType} == "digi_withBIB" ]; then

    source worker.sh --num-events ${nEvts} --in-file-prefix ${dirKey}/${in_file_prefix} --out-dir ${OutPath} --out-file-prefix ${out_file_prefix} --overlay-numbkg ${overlay_numBkg} --run-type ${runType}
    
elif [[ ${runType} == "reco" || ${runType} == "reco_withBIB" ]]; then

    source worker.sh --in-file-prefix ${dirKey}/${in_file_prefix} --out-dir ${OutPath} --out-file-prefix ${out_file_prefix} --run-type ${runType}
    
else

    echo "Wrong Argument"
    
fi

    

   
