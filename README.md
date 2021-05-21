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

## Notes

- **As of 2021-05-20 the corpus has not been fully annotated so results are not final.**
- From the corpus, customer utterances were annotated for dissatisfaction. See [annotations](annotations). The labels `n` and `nn` are read as 0 (negative class, neutral), `d` and `dd` are read as 1 (positive class, dissatisfied), and all other labels are ignored. See [annotation-guide.txt](annotation-guide.txt).

## linearRegressionDialog.m

A dialog-level linear regression based model. For train, dev, and test sets, see [source/tracklists-dialog](source/tracklists-dialog). The first regressor is trained using the original feature set in [mono.fss](mono.fss). The second regressor is trained on summary features based on the frame predictions of the first regressor. For each dialog, the summary features are: (1) the fraction of frames above a *dissatisfaction threshold*; (2) the minimum dissatisfaction value; (3) the maximum dissatisfaction value; (4) the mean dissatisfaction value;
(5) the range of the dissatisfaction values; and (6) the standard deviation of the dissatisfaction values.

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the dev set:

```none
beta=0.25 min(yPred)=0.34 max(yPred)=32.15 mean(yPred)=2.66
bestScore=0.452, bestScoreThreshold=0.367, mse=58.28
baselineScore=0.38, baselinePrecision=0.37, baselineRecall=1.00, baselineMse=0.63
```

## linearRegressionFrame.m

A frame-level linear regression model. For train, dev, and test sets, see [source/tracklists-frame](source/tracklists-frame). Each set is 6
dialogs, half labeled as neutral and half labeled as dissatisfied on the
dialog level. The dissatisfied dialogs typically have more neutral frames compared to dissatisfied frames so the training data is balanced in code.

The learned coefficients are printed in descending order:

```none
Coefficients in descending order with format:
coefficient number, value, abbreviation
  1 | 0.243638 | se vo -3200 -1600
 14 | 0.226075 | se vo  +400  +800
 29 | 0.174070 | se cr  +400  +800
 15 | 0.140129 | se vo  +800  +1600
 30 | 0.138245 | se cr  +800  +1600
...
 76 | -0.108236 | se wp  +300  +400
108 | -0.124224 | se pd  +800  +1600
  2 | -0.136769 | se vo -1600 -800
 67 | -0.138266 | se np  +400  +800
 77 | -0.170379 | se wp  +400  +800
```

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the dev set:

```none
beta=0.25, bestThreshold=-1.157, bestLinearFscore=0.36, baselineFscoreAtBestThreshold=0.36
```

```none
Regressor MAE = 0.762806
Baseline MAE = 0.649257
Linear regressor MSE = 0.866716
Baseline MSE = 0.649257
Regressor R-squared = 0.438322
```

## linearRegressionUtterance.m

Predict on utterances using the linear regressor's frame-level
predictions. For each utterance in the compare set (dev or test), predicts the mean of the
predictions on the frames belonging to that utterance. 

The baseline always predicts a value of 1 for perfectly dissatisfied. Results using the dev set:

```none
[UTTERANCE-LEVEL RESULTS]
```
