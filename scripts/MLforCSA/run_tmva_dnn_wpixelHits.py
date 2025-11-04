import ROOT

# ----------------------------------------------------------------------
# Setup TMVA
# ----------------------------------------------------------------------
ROOT.TMVA.Tools.Instance()

# Create output file
output = ROOT.TFile("TMVA_DNN_wpixels_output.root", "RECREATE")

# Create factory
factory = ROOT.TMVA.Factory("TMVADNNClassification_wpixels", output,
                            "!V:!Silent:Color:DrawProgressBar:Transformations=I:AnalysisType=Classification")

# Create DataLoader
dataloader = ROOT.TMVA.DataLoader("dataset")

# ----------------------------------------------------------------------
# Input ROOT tree
# ----------------------------------------------------------------------
sig_file = ROOT.TFile("/global/cfs/cdirs/atlas/arastogi/MuonCollider/CSA_wML/RunDNN/Inputs/Signal/Hits_TTree_training.root")
bkg_file = ROOT.TFile("/global/cfs/cdirs/atlas/arastogi/MuonCollider/CSA_wML/RunDNN/Inputs/Background/Hits_TTree_training.root")
sig_tree = sig_file.Get("HitTree")
bkg_tree = bkg_file.Get("HitTree")

# ----------------------------------------------------------------------
# Define input variables for DNN
# ----------------------------------------------------------------------
# Cluster-level features
dataloader.AddVariable("Cluster_EnergyDeposited", "F")
dataloader.AddVariable("Cluster_ArrivalTime", "F")
dataloader.AddVariable("Cluster_x", "F")
dataloader.AddVariable("Cluster_y", "F")
dataloader.AddVariable("Cluster_z", "F")
dataloader.AddVariable("Cluster_r", "F")
dataloader.AddVariable("Incident_Angle", "F")
dataloader.AddVariable("Cluster_Size_x", "F")
dataloader.AddVariable("Cluster_Size_y", "F")
dataloader.AddVariable("Cluster_Size_tot", "F")

# Pixel-level features (for first few pixels)
for i in range(9):
    dataloader.AddVariable(f"PixelHits_EnergyDeposited_{i}", "F")
    dataloader.AddVariable(f"PixelHits_ArrivalTime_{i}", "F")

# Add signal and background trees
dataloader.AddSignalTree(sig_tree, 1.0)
dataloader.AddBackgroundTree(bkg_tree, 0.045) #roughly the ratio of signal to bkg clusters in VXB L0

dataloader.PrepareTrainingAndTestTree(ROOT.TCut(""),
    "nTrain_Signal=3000:nTrain_Background=0:SplitMode=Random:NormMode=NumEvents:!V")

# ----------------------------------------------------------------------
# Define and Book DNN
# ----------------------------------------------------------------------
dnn_options = (
    "H:!V:"
    "VarTransform=N:"                           # Normalize inputs
    "ErrorStrategy=CROSSENTROPY:"               # Binary classification
    "WeightInitialization=XAVIER:"
    "Architecture=CPU:"
    "Layout=RELU|128,RELU|64,RELU|32,LINEAR:"
    "TrainingStrategy="
    "LearningRate=1e-3,Momentum=0.9,ConvergenceSteps=20,"
    "BatchSize=256,TestRepetitions=1,"
    "WeightDecay=1e-4,DropConfig=0.1,MaxEpochs=300"
)

factory.BookMethod(dataloader, ROOT.TMVA.Types.kDNN, "DNN", dnn_options)

# ----------------------------------------------------------------------
# Train, Test, Evaluate
# ----------------------------------------------------------------------
factory.TrainAllMethods()
factory.TestAllMethods()
factory.EvaluateAllMethods()

output.Close()
print("TMVA DNN training complete. Output saved to TMVA_DNN_output.root")
