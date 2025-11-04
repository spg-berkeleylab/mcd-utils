import ROOT
from array import array
import numpy as np
from sklearn.metrics import roc_curve, auc

# Initialize TMVA
ROOT.TMVA.Tools.Instance()

# Define input variables (must match training)
variables = [
    "Cluster_EnergyDeposited", "Cluster_ArrivalTime", "Cluster_x", "Cluster_y", "Cluster_z", "Cluster_r", "Incident_Angle", "Cluster_Size_x", "Cluster_Size_y", "Cluster_Size_tot"
]

for i in range(9):
    variables.append(f"PixelHits_EnergyDeposited_{i}")
    variables.append(f"PixelHits_ArrivalTime_{i}")

var_arrays = {v: array('f', [0]) for v in variables}
reader = ROOT.TMVA.Reader("Color:!Silent")
for v in variables:
    reader.AddVariable(v, var_arrays[v])
reader.BookMVA("DNN", "dataset/weights/TMVADNNClassification_wpixels_DNN.weights.xml")

# --- Load input ROOT files ---
sig_file = ROOT.TFile("/global/cfs/cdirs/atlas/arastogi/MuonCollider/CSA_wML/RunDNN/Inputs/Signal/Hits_TTree_eval.root")
bkg_file = ROOT.TFile("/global/cfs/cdirs/atlas/arastogi/MuonCollider/CSA_wML/RunDNN/Inputs/Background/Hits_TTree_eval.root")
sig_tree = sig_file.Get("HitTree")
bkg_tree = bkg_file.Get("HitTree")

# --- Evaluate ---
def evaluate_tree(tree, scores_list):
    for i, event in enumerate(tree):
        for v in variables:
            var_arrays[v][0] = getattr(event, v)
            score = reader.EvaluateMVA("DNN")
            scores_list.append(score)

# --- Evaluate signal and background ---
sig_scores = []
bkg_scores = []
evaluate_tree(sig_tree, sig_scores)
evaluate_tree(bkg_tree, bkg_scores)

outFile = ROOT.TFile("DNN_wpixels_EvalResults.root", "RECREATE")
# Signal score histogram
hSig = ROOT.TH1F("hSigScore", "DNN Output;DNN score;Entries (normalized)", 100, 0, 1)
for s in sig_scores:
    hSig.Fill(s)
# Background score histogram
hBkg = ROOT.TH1F("hBkgScore", "DNN Output;DNN score;Entries (normalized)", 100, 0, 1)
for b in bkg_scores:
    hBkg.Fill(b)

# Normalize histograms if you wish:
hSig.Scale(1.0 / hSig.Integral())
hBkg.Scale(1.0 / hBkg.Integral())

# Write everything to file
hSig.Write()
hBkg.Write()

# --- Plot DNN outputs ---
c1 = ROOT.TCanvas("c1", "DNN Output", 800, 600)
hSig.SetLineColor(ROOT.kRed)
hBkg.SetLineColor(ROOT.kBlue)
hSig.SetLineWidth(2)
hBkg.SetLineWidth(2)
hBkg.Draw("HIST")
hSig.Draw("HIST SAME")
hBkg.SetStats(0)

legend = ROOT.TLegend(0.7, 0.75, 0.9, 0.9)
legend.AddEntry(hSig, "Signal clusters", "l")
legend.AddEntry(hBkg, "Background clusters", "l")
legend.Draw()

c1.SaveAs("DNN_Evaluation_wpixels.png")
c1.Write()

# --- Compute ROC curve ---
y_true = np.array([1]*len(sig_scores) + [0]*len(bkg_scores))
y_score = np.array(sig_scores + bkg_scores)

# Standard ROC from sklearn
fpr, tpr, _ = roc_curve(y_true, y_score)

# Convert for background rejection ROC:
bkg_rejection = 1 - fpr     # X-axis
sig_efficiency = tpr        # Y-axis

roc_auc = auc(sig_efficiency, bkg_rejection)
print(f"\nROC AUC (Signal eff vs Background rejection) = {roc_auc:.3f}")

# --- Plot ROC (Signal eff vs Background rejection) ---
c2 = ROOT.TCanvas("c2", "ROC Curve (Signal Eff vs Background Rejection)", 600, 600)
g = ROOT.TGraph(len(sig_efficiency), array('f', bkg_rejection), array('f', sig_efficiency))

g.SetTitle(f"ROC Curve;Background Rejection;Signal Efficiency")
g.SetLineColor(ROOT.kBlue)
g.SetLineWidth(2)
g.Draw("AL")
g.GetXaxis().SetLimits(0, 1)
g.GetYaxis().SetRangeUser(0, 1)

c2.SaveAs("DNN_ROC_SigEff_vs_BkgRej_wpixels.png")
g.Write("ROC_curve")
outFile.Close()

print("\n=== DNN Evaluation Complete ===")
print(f"   AUC = {roc_auc:.3f}")
