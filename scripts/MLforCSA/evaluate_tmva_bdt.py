import ROOT
from ROOT import TMVA, TFile, TH1F
from array import array

# -------------------------------------------------------------
# Initialize TMVA reader
# -------------------------------------------------------------
TMVA.Tools.Instance()
reader = TMVA.Reader("!Color:!Silent")

# Define input variables (same as training)
variables = [
    "Cluster_ArrivalTime",
    "Cluster_EnergyDeposited",
    "Incident_Angle",
    "Cluster_Size_x",
    "Cluster_Size_y",
    "Cluster_Size_tot",
    "Cluster_x",
    "Cluster_y",
    "Cluster_z"
]

# Create float containers
var_dict = {v: array('f', [0.]) for v in variables}
for v in variables:
    reader.AddVariable(v, var_dict[v])

# Load trained weights
reader.BookMVA("BDT", "dataset/weights/TMVAClassification_BDT.weights.xml")

# -------------------------------------------------------------
# Load signal and background trees
# -------------------------------------------------------------
sig_file = TFile("Inputs/Signal/Hits_TTree_eval.root")
bkg_file = TFile("Inputs/Background/Hits_TTree_eval.root")
sig_tree = sig_file.Get("HitTree")
bkg_tree = bkg_file.Get("HitTree")

# -------------------------------------------------------------
# Helper function: evaluate per object
# -------------------------------------------------------------
def evaluate_objects(tree, hist, label):
    n_events = tree.GetEntries()
    print(f"Evaluating {label} sample ({n_events} events)...")
    n_objects_total = 0
    for ev in range(n_events):
        tree.GetEntry(ev)
        # all vectors have same size for this event
        n_objects = len(getattr(tree, variables[0]))
        n_objects_total += n_objects
        for i in range(n_objects):
            for var in variables:
                vec = getattr(tree, var)
                var_dict[var][0] = float(vec[i])
            score = reader.EvaluateMVA("BDT")
            hist.Fill(score)
    print(f"  → processed {n_objects_total} objects total.")

# -------------------------------------------------------------
# Create output ROOT file and histograms
# -------------------------------------------------------------
output_file = TFile("TMVA_ObjectEvaluation.root", "RECREATE")
h_sig = TH1F("h_BDT_signal", "BDT Response;BDT score;Objects (normalized)", 50, -1, 1)
h_bkg = TH1F("h_BDT_background", "BDT Response;BDT score;Objects (normalized)", 50, -1, 1)

evaluate_objects(sig_tree, h_sig, "signal")
evaluate_objects(bkg_tree, h_bkg, "background")

# Normalize for comparison
if h_sig.Integral() > 0:
    h_sig.Scale(1.0 / h_sig.Integral())
if h_bkg.Integral() > 0:
    h_bkg.Scale(1.0 / h_bkg.Integral())

# -------------------------------------------------------------
# Draw histograms
# -------------------------------------------------------------
c1 = ROOT.TCanvas("c1", "BDT Object Evaluation", 800, 600)
h_sig.SetLineColor(ROOT.kRed)
h_sig.SetLineWidth(2)
h_bkg.SetLineColor(ROOT.kBlue)
h_bkg.SetLineWidth(2)
h_sig.Draw("hist")
h_bkg.Draw("hist same")
h_sig.SetStats(0)

legend = ROOT.TLegend(0.65, 0.75, 0.88, 0.88)
legend.AddEntry(h_sig, "Signal clusters", "l")
legend.AddEntry(h_bkg, "Background clusters", "l")
legend.Draw()

c1.Write()
c1.SaveAs("BDT_ObjectResponse_Comparison.png")

# ROC Curve                                                                                                                                                                                  
sig_eff = []
bkg_eff = []
n_bins = h_sig.GetNbinsX()

for i in range(n_bins):
    sig_int = h_sig.Integral(i+1, n_bins)
    bkg_int = h_bkg.Integral(i+1, n_bins)
    sig_eff.append(sig_int)
    bkg_eff.append(1-bkg_int)

# Draw ROC curve                                                                                                                                                                             
roc = ROOT.TGraph(len(sig_eff), array('f', bkg_eff), array('f', sig_eff))
roc.SetTitle("ROC Curve;Background Rejection;Signal Efficiency")
roc.SetLineWidth(2)
roc.SetLineColor(ROOT.kGreen+2)

c2 = ROOT.TCanvas("c2", "ROC", 600, 600)
roc.Draw("AL")
c2.SaveAs("bdt_roc_curve.png")

roc.Write("ROC_curve")

output_file.Write()
output_file.Close()
print("Object-level BDT evaluation complete.")
print("Results saved to 'TMVA_ObjectEvaluation.root' and 'BDT_ObjectResponse_Comparison.png'")
