import re
import os
import math
from pathlib import Path
import argparse
import pyLCIO
import ROOT, array
from array import array

COLLECTIONS = [
        "VXDBarrelHits"
        ]

def options():
    parser = argparse.ArgumentParser(description="Generate BIB output hits TTree root file from input slcio file.")
    parser.add_argument("-i", required=True, type=Path, help="Input LCIO file")
    parser.add_argument(
        "--nhits",
        default=0,
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
    out_dir = "Inputs/Signal"
    out_file = f"{out_dir}/Hits_TTree_{in_ind}.root"
    tree_name = "HitTree"
    # Create a new ROOT file and TTree
    root_file = ROOT.TFile(out_file, "RECREATE")
    tree = ROOT.TTree(tree_name, "Tree storing hit information")
    
    # Define variables to be stored in the tree
    x = ROOT.std.vector('float')()
    y = ROOT.std.vector('float')()
    z = ROOT.std.vector('float')()
    t =	ROOT.std.vector('float')()
    e =	ROOT.std.vector('float')()
    r = ROOT.std.vector('float')()
    theta =	ROOT.std.vector('float')()
    cluster_size_x   = ROOT.std.vector('float')()
    cluster_size_y   = ROOT.std.vector('float')()
    cluster_size_tot = ROOT.std.vector('float')()

    # Create branches
    tree.Branch("Cluster_x", x)
    tree.Branch("Cluster_y", y)
    tree.Branch("Cluster_z", z)
    tree.Branch("Cluster_r", r)
    tree.Branch("Cluster_ArrivalTime", t)
    tree.Branch("Cluster_EnergyDeposited", e)
    tree.Branch("Incident_Angle", theta)
    tree.Branch("Cluster_Size_x", cluster_size_x)
    tree.Branch("Cluster_Size_y", cluster_size_y)
    tree.Branch("Cluster_Size_tot", cluster_size_tot)
    
    reader = pyLCIO.IOIMPL.LCFactory.getInstance().createLCReader()
    reader.open(str(in_file))

    # Start of event loop
    for i_event, event in enumerate(reader):
        cols = {}
        for col in COLLECTIONS:
            cols[col] = get_collection(event, col)

        print(f"Event {i_event} has")
        for col in cols:
            print(f"  {len(cols[col]):5} hits in {col}")

        # Within each event, get hit collections
        for col_name in COLLECTIONS:
            collection = cols[col_name]

            # Start loop over each hit in collection
            for i_hit, hit in enumerate(collection):
                # Limit hit number based on input at runtime
                if i_hit < ops.nhits:
                    break
                
                position = hit.getPosition()
                x_pos = position[0]
                y_pos = position[1]
                z_pos = position[2]
                r_pos = math.sqrt(x_pos**2+y_pos**2)
                
                if r_pos<32: #all VXB hits of first layer
                    # Reset variable storage
                    x.clear()
                    y.clear()
                    z.clear()
                    r.clear()
                    t.clear()
                    e.clear()
                    theta.clear()
                    cluster_size_x.clear()
                    cluster_size_y.clear()
                    cluster_size_tot.clear()
                    
                    pixelHits = hit.getRawHits()
                    x.push_back(x_pos)
                    y.push_back(y_pos)
                    z.push_back(z_pos)
                    t.push_back(hit.getTime())
                    e.push_back(hit.getEDep())
                    theta.push_back(get_theta(r_pos, z_pos))
                    r.push_back(r_pos)
            
                    cluster_x, cluster_y = get_cluster_size(pixelHits)
                    cluster_size_x.push_back(cluster_x)
                    cluster_size_y.push_back(cluster_y)
                    cluster_size_tot.push_back(len(pixelHits))

                tree.Fill()
                    
    # Write and close
    tree.Write()
    root_file.Close()

    print(f"ROOT file '{out_file}' with tree '{tree_name}' created.")

def get_collection(event, name):
    names = event.getCollectionNames()
    if name in names:
        return event.getCollection(name)
    return []


if __name__ == "__main__":
    main()
