import ROOT
import numpy as np
from array import array
import random
import re
import os
import math
from pathlib import Path
import argparse
import pyLCIO

COLLECTIONS = [
        "VXDBarrelHits"
        ]

def options():
    parser = argparse.ArgumentParser(description="Generate BIB output hits TTree root file from input slcio file.")
    parser.add_argument("-i", required=True, type=Path, help="Input LCIO file")
    parser.add_argument(
	"--nhits",
        default=9,
        type=int,
        help="Max number of hits to dump for each collection",
    )
    return parser.parse_args()

def get_theta(r, z):
    angle = math.atan2(r, z)
    return angle

def get_cluster_size(pixelHits):
    ymax = -1e6
    xmax = -1e6
    ymin = 1e6
    xmin = 1e6

    for j in range(len(pixelHits)):
        hitConstituent = pixelHits[j]
        localPos = hitConstituent.getPosition()
        x_local = localPos[0]
        y_local = localPos[1]

        if y_local < ymin:
            ymin = y_local
        if y_local > ymax:
            ymax = y_local

        if x_local < xmin:
            xmin = x_local
        if x_local > xmax:
            xmax = x_local

    cluster_size_y = (ymax - ymin) + 1
    cluster_size_x = (xmax - xmin) + 1

    return cluster_size_x, cluster_size_y

def main():

    ops = options()
    in_file = ops.i
    print(f"Reading file {in_file}")

    stem = in_file.stem #gets the name without extension                                                                                                                               
    in_ind = stem.removeprefix("output_digi_light_") #in_file.stem.split('_')[-1]                                                                                                      
    out_dir = "/global/cfs/cdirs/atlas/arastogi/MuonCollider/CSA_wML/RunDNN/Inputs/Signal"
    out_file = f"{out_dir}/Hits_TTree_{in_ind}.root"
    tree_name = "HitTree"
    # Create a new ROOT file and TTree                                                                                                                                                 
    root_file = ROOT.TFile(out_file, "RECREATE")
    tree = ROOT.TTree(tree_name, "Tree storing hit information")
    
    # Cluster-level variables
    cluster_energy = array('f', [0.])
    cluster_time   = array('f', [0.])
    cluster_size   = array('f', [0.])
    cluster_x    = array('f', [0.])
    cluster_y    = array('f', [0.])
    cluster_z  = array('f', [0.])
    cluster_r  = array('f', [0.])
    cluster_theta  = array('f', [0.])
    cluster_x_size   = array('f', [0.])
    cluster_y_size   = array('f', [0.])

    max_npix = ops.nhits
    pixelE = [array('f', [0.]) for _ in range(max_npix)]
    pixelT = [array('f', [0.]) for _ in range(max_npix)]
    for i in range(max_npix):
        tree.Branch(f"PixelHits_EnergyDeposited_{i}", pixelE[i], f"PixelHits_EnergyDeposited_{i}/F")
        tree.Branch(f"PixelHits_ArrivalTime_{i}", pixelT[i], f"PixelHits_ArrivalTime_{i}/F")

    tree.Branch("Cluster_EnergyDeposited", cluster_energy, "Cluster_EnergyDeposited/F")
    tree.Branch("Cluster_ArrivalTime", cluster_time, "Cluster_ArrivalTime/F")
    tree.Branch("Cluster_Size_tot", cluster_size, "Cluster_Size_tot/F")
    tree.Branch("Cluster_Size_x", cluster_x_size, "Cluster_Size_x/F")
    tree.Branch("Cluster_Size_y", cluster_y_size, "Cluster_Size_y/F")
    tree.Branch("Cluster_x", cluster_x, "Cluster_x/F")
    tree.Branch("Cluster_y", cluster_y, "Cluster_y/F")
    tree.Branch("Cluster_z", cluster_z, "Cluster_z/F")
    tree.Branch("Cluster_r", cluster_r, "Cluster_r/F")
    tree.Branch("Incident_Angle", cluster_theta, "Incident_Angle/F")

    reader = pyLCIO.IOIMPL.LCFactory.getInstance().createLCReader()
    reader.open(str(in_file))

    count_tot = 0
    count_l0 = 0
    # Start of event loop                                                                                                                                                              
    for i_event, event in enumerate(reader):
        cols = {}
        for col in COLLECTIONS:
            cols[col] = get_collection(event, col)

        print(f"Event {i_event} has")
        for col in cols:
            print(f"  {len(cols[col]):5} hits in {col}")
            count_tot = count_tot+len(cols[col])

	# Within each event, get hit collections                                                                                                                                       
        for col_name in COLLECTIONS:
            collection = cols[col_name]
            
            # Start loop over each hit in collection                                                                                                                                   
            for i_hit, hit in enumerate(collection):
                position = hit.getPosition()
                x_pos = position[0]
                y_pos = position[1]
                z_pos = position[2]
                r_pos = math.sqrt(x_pos**2+y_pos**2)

                if r_pos<32: #all VXB hits of first layer
                    count_l0 = count_l0 + 1
                    cluster_energy[0] = hit.getEDep()
                    cluster_time[0] = hit.getTime()
                    cluster_x[0] = x_pos
                    cluster_y[0] = y_pos
                    cluster_z[0] = z_pos
                    cluster_r[0] = r_pos
                    cluster_theta[0] = get_theta(r_pos, z_pos)
                    
                    pixelHits = hit.getRawHits()
                    npix = len(pixelHits)
                    cluster_xhits, cluster_yhits = get_cluster_size(pixelHits)
                    cluster_size[0] = npix
                    cluster_x_size[0] = cluster_xhits
                    cluster_y_size[0] = cluster_yhits
                    
                    pixList = [pixelHits[i].getEDep() for i in range(pixelHits.size())]
                    nh = min(max_npix, len(pixList))
                    pixInd = np.argsort(pixList)[-nh:][::-1]
                    for j in range(max_npix):
                        pixelE[j][0] = 0.
                        pixelT[j][0] = 0.
                    
                    for j, ind in enumerate(pixInd):
                        pixelE[j][0] = pixelHits[int(ind)].getEDep()
                        pixelT[j][0] = pixelHits[int(ind)].getTime()

                    tree.Fill()

    tree.Write()
    root_file.Close()

    print(f"Total VXB clusters {count_tot} and on layer0 {count_l0}")
    print(f"ROOT file '{out_file}' with tree '{tree_name}' created.")

def get_collection(event, name):
    names = event.getCollectionNames()
    if name in names:
        return event.getCollection(name)
    return []


if __name__ == "__main__":
    main()

