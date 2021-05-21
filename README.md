# Detecting dissatisfaction in spoken dialog

[About the project.]

## Set up

1. Clone this repo or download it as a ZIP and extract.
1. Download [The UTEP Corpus of Dissatisfaction in Spoken Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus). Place the `calls`
   folder and `call-log.xlsx` in the root of this project.
1. Download [Midlevel Prosodic Features Toolkit](https://github.com/nigelgward/midlevel). Place the `midlevel-master` folder
   in the root of this project.
1. Open this project
(the `dissatisfaction-models` folder) in MATLAB.
1. Install MATLAB's [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html).
1. **Add the project folder and its subfolders to
   Path.** Right-click the folder in the Current Folder window or use the
   [addpath](https://www.mathworks.com/help/matlab/ref/addpath.html) function.

## Annotations

From the corpus, customer utterances were annotated for dissatisfaction. See [annotations](annotations). The labels `n` and `nn` are read as 0 (negative class, neutral), `d` and `dd` are read as 1 (positive class, dissatisfied), and all other labels are ignored. See [annotation-guide.txt](annotation-guide.txt).

## linearRegressionDialog.m

A dialog-level linear regression model.

The first regressor is trained using the feature set specified in [mono.fss](mono.fss). The second regressor is trained using features based on the frame predictions of the first regressor. For each dialog, the summary features are: (1) the fraction of frames above a *dissatisfaction threshold*; (2) its minimum dissatisfaction value; (3) its maximum dissatisfaction value; (4) its mean dissatisfaction value;
(5) the range of its dissatisfaction values; and (6) the standard deviation of its dissatisfaction values.

For training, validation, and test sets, see [source/tracklists-dialog](source/tracklists-dialog).

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the dev set:

```
beta=0.25, min(yPred)=-32.24, max(yPred)=10.93, mean(yPred)=-0.27
dissThreshold=0.327
regressorFscore=0.43, regressorPrecision=0.41, regressorRecall=1.00, regressorMSE=65.17
baselineFscore=0.38, baselinePrecision=0.37, baselineRecall=1.00, baselineMSE=0.63
```

## linearRegressionFrame.m

A frame-level linear regression model. For train, dev, and test sets, see [source/tracklists-frame](source/tracklists-frame). Each set is 6
dialogs, half labeled as neutral and half labeled as dissatisfied on the
dialog level. The dissatisfied dialogs typically have more neutral frames compared to dissatisfied frames so the training data is balanced in code.

The learned coefficients are printed in descending order:

```none
Coefficients in descending order with format:
coefficient number, value, abbreviation
 16 | 0.160004 | se vo  +1600  +3200
 78 | 0.151007 | se wp  +800  +1600
 59 | 0.115827 | se np -1600 -800
  1 | 0.110473 | se vo -3200 -1600
 14 | 0.107677 | se vo  +400  +800
...
 57 | -0.071638 | se th  +400  +800
 44 | -0.078300 | se tl  +800  +1600
 30 | -0.082371 | se cr  +800  +1600
108 | -0.095654 | se pd  +800  +1600
  2 | -0.227057 | se vo -1600 -800
```

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the dev set:

```none
regressorRsquared=0.28
beta=0.25, dissThreshold=1.115
regressorFscore=0.38, regressorMSE=0.37
baselineFscore=0.36, baselineMSE=0.66
```

## linearRegressionUtterance.m

An utterance-level linear regression model. For each utterance, this model predicts the mean, predicted dissatisfaction values for the frames in the utterance.

The baseline always predicts a value of 1 for perfectly dissatisfied. Results using the dev set:

```none
beta=0.25, min(yPred)=-0.00, max(yPred)=0.83, mean(yPred)=0.44
dissThreshold=0.800
regressorFscore=0.71, regressorPrecision=1.00, regressorRecall=0.12, regressorMSE=0.26
baselineFscore=0.25, baselinePrecision=0.24, baselineRecall=1.00, baselineMSE=0.76
```
