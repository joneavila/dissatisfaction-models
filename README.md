# Models for detecting dissatisfaction in spoken dialog

## Set up

1. Clone this repo or download it as a ZIP archive and extract it.
2. Download [The UTEP Corpus of Dissatisfaction in Spoken
   Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus). Copy or move the
   `calls` folder, `annotations` folder, and `call-log.xlsx` to the root of the
   project folder.
3. Download [Midlevel Prosodic Features
   Toolkit](https://github.com/nigelgward/midlevel). Copy or move the `midlevel-master`
   folder to the root of the project folder.
4. Install MathWorks' [Signal Processing
   Toolbox](https://www.mathworks.com/products/signal.html) and [Statistics and
   Machine Learning
   Toolbox](https://www.mathworks.com/products/statistics.html). To install
   add-ons, from MATLAB's "Home" menu tab, click "Add-Ons", then "Get Add-Ons" or "Manage Add-Ons".
5. Open the root of the project folder (`dissatisfaction-models` folder) in
   MATLAB. MATLAB's address field (below the ribbon menu) should end with `.../dissatisfaction-models`.
6. Add the root of the project folder and its subfolders to Path. To add a folder to Path,
   from MATLAB's "Current Folder" pane, right-click the folder, then click "Add
   to Path", then click "Selected Folder and Subfolders". Alternatively, you can
   use the
   [addpath](https://www.mathworks.com/help/matlab/ref/addpath.html) function.

## To do
- [ ] The values for neutral and dissatisfaction labels are set to 0 and 1,
  respectively, throughout the code. These values should not be hardcoded.
- [ ] Many functions rely on the `pwd` command. This explains why you must be in
  the root of the project folder.
- [ ] Since working from a Mac, I've changed back slashes to forward slashes.
  There might be a way to keep the code compatible for all systems?

## Annotations

Customer utterances were annotated for dissatisfaction (see [The UTEP Corpus of
Dissatisfaction in Spoken
Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus)). For the
frame-level and utterance-level models below, the labels `n` and `nn` are read
as 0 (negative class, neutral), `d` and `dd` are read as 1 (positive class,
dissatisfied), and all other labels are ignored.

## linearRegressionFrame.m

A frame-level linear regression model.

For training, validation, and test sets, see
[source/tracklists-frame](source/tracklists-frame). Each set comprises 6
dialogs, half labeled as neutral and half labeled as dissatisfied. The
dissatisfied dialogs typically have more neutral frames compared to dissatisfied
frames, so the training data is balanced in code.

The learned coefficients are printed in descending order, with time feature
included:

```none
Coefficients in descending order with format:
coefficient number, value, feature abbreviation
119 | 0.180460 | time into dialog
78 | 0.156935 | se wp  +800  +1600
59 | 0.148045 | se np -1600 -800
45 | 0.136897 | se th -1600 -800
16 | 0.126064 | se vo  +1600  +3200
...
76 | -0.065106 | se wp  +300  +400
71 | -0.068658 | se wp -400 -300
108 | -0.089846 | se pd  +800  +1600
30 | -0.104341 | se cr  +800  +1600
 2 | -0.285015 | se vo -1600 -800
 ```

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on
the test set, with time feature included:

```none
beta=0.25, min(yPred)=-3.16, max(yPred)=5.53, mean(yPred)=0.53
regressorRsquared=0.35
dissThreshold=0.411
regressorFscore=0.58, regressorPrecision=0.57, regressorRecall=0.81, regressorMSE=0.35
baselineFscore=0.45, baselinePrecision=0.43, baselineRecall=1.00, baselineMSE=0.57
```

```none
beta=1.00, min(yPred)=-3.16, max(yPred)=5.53, mean(yPred)=0.53
regressorRsquared=0.35
dissThreshold=0.411
regressorFscore=0.67, regressorPrecision=0.57, regressorRecall=0.81, regressorMSE=0.35
baselineFscore=0.60, baselinePrecision=0.43, baselineRecall=1.00, baselineMSE=0.57
```

## linearRegressionUtterance.m

An utterance-level linear regression model. For each utterance, this model
predicts the mean, predicted dissatisfaction values for the frames in the
utterance. This model shares the frame-level's training, validation, and test
set.

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on
the test set, with time feature included:

```none
beta=0.25, min(yPred)=-0.03, max(yPred)=1.30, mean(yPred)=0.50
dissThreshold=0.571
regressorFscore=0.62, regressorPrecision=0.62, regressorRecall=0.73, regressorMSE=0.25
baselineFscore=0.39, baselinePrecision=0.38, baselineRecall=1.00, baselineMSE=0.62
```

## linearRegressionDialog.m

A dialog-level linear regression model.

The first regressor is trained using the feature set specified in
[mono.fss](mono.fss). The second regressor is trained using features based on
the frame predictions of the first regressor. For each dialog, the summary
features are: (1) the fraction of frames above a *dissatisfaction threshold*
(see [linearRegressionFrame.m](#linearRegressionFrame.m)); (2) its minimum
dissatisfaction value; (3) its maximum dissatisfaction value; (4) its mean
dissatisfaction value; (5) the range of its dissatisfaction values; and (6) the
standard deviation of its dissatisfaction values.

The summary features are computed for each dialog from (including) the first
non-`o` (out of character) utterance to (including) the last non-`o` utterance.

For training, validation, and test sets, see
[source/tracklists-dialog](source/tracklists-dialog). The baseline always
predicts a value of 1 for perfectly dissatisfied. Results on the test set:

```none
beta=0.25, min(yPred)=0.20, max(yPred)=64.28, mean(yPred)=1.46
dissThreshold=0.408
regressorFscore=0.63, regressorPrecision=0.65, regressorRecall=0.39, regressorMSE=55.61
baselineFscore=0.52, baselinePrecision=0.51, baselineRecall=1.00, baselineMSE=0.49
```

## calculateCorpusStats.m

Print the number of neutral and dissatisfied frames in the dialog-level sets and
print the number of neutral and dissatisfied utterances in the dialog-level
sets. Output:

```none
train frames
    neutral=8335, dissatisfied=7899
dev frames
    neutral=14084, dissatisfied=7581
test frames
    neutral=54543, dissatisfied=20893
train utterances
    neutral=46 (n=33, nn=13), dissatisfied=24 (d=16, dd=8)
dev utterances
    neutral=52 (n=43, nn=9), dissatisfied=23 (d=14, dd=9)
test utterances
    neutral=256 (n=200, nn=56), dissatisfied=82 (d=63, dd=19)
```

## calculateCorrelations.m

Calculates the point-biserial correlation coefficient (Pearson's correlation
coefficient) for each feature and dissatisfaction. Results are stored in
`resultsTable`. Head and tail of `resultsTable`:

```none
"se vo -3200 -1600"  0.0399280043250400  0.0399293872328013
"se vo -1600 -800"   0.0628281694906818  0.0628303455464271
"se vo -800 -400"    0.0181824412947618  0.0181830710442223
...
"se vr  +400  +800" -0.0222615534871412 -0.0222623245167907
"se vr  +800  +1600"-0.0453442255170480 -0.0453457960158128
"time into dialog"   0.309024112402498   0.309034815462936
```
