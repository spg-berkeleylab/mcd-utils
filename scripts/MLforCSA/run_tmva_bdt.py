import ROOT
from array import array
from ROOT import TMVA

# Create output file
outputFile = ROOT.TFile("TMVA_output.root", "RECREATE")

# Initialize TMVA
TMVA.Tools.Instance()
factory = TMVA.Factory("TMVAClassification", outputFile,"!V:!Silent:Color:DrawProgressBar:Transformations=I;:AnalysisType=Classification")
dataloader = TMVA.DataLoader("dataset")

# Define input variables
variables = [
    "Cluster_ArrivalTime",
    "Cluster_EnergyDeposited",
    "Incident_Angle",
    "Cluster_Size_x",
    "Cluster_Size_y",
    "Cluster_Size_tot",
    "Cluster_x",
    "Cluster_y",
    "Cluster_z",
]

for v in variables:
    dataloader.AddVariable(v, "F")
for i in range(9):
    dataloader.AddVariable(f"PixelHits_EnergyDeposited_{i}", "F")
    dataloader.AddVariable(f"PixelHits_ArrivalTime_{i}", "F")
    
# Load signal and background files
sig_file = ROOT.TFile("Inputs/Signal/Hits_TTree_training.root")
bkg_file = ROOT.TFile("Inputs/Background/Hits_TTree_training.root")
sig_tree = sig_file.Get("HitTree")
bkg_tree = bkg_file.Get("HitTree")

dataloader.AddSignalTree(sig_tree, 1.0)
dataloader.AddBackgroundTree(bkg_tree, 1.0)

# Prepare dataset
dataloader.PrepareTrainingAndTestTree(ROOT.TCut(""), ROOT.TCut(""),
    "nTrain_Signal=0:nTrain_Background=0:SplitMode=Random:NormMode=NumEvents:!V")

# Book a BDT
factory.BookMethod(dataloader, TMVA.Types.kBDT, "BDT",
    "!H:!V:NTrees=200:MaxDepth=3:BoostType=AdaBoost:AdaBoostBeta=0.5:SeparationType=GiniIndex:nCuts=20")

# Train, test, evaluate
factory.TrainAllMethods()
factory.TestAllMethods()
factory.EvaluateAllMethods()

outputFile.Close()
print("TMVA training completed. Output saved to 'TMVA_output.root'")
