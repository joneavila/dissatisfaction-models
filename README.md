# Models for estimating dissatisfaction in spoken dialog

Code for models used in [*Nigel Ward, Jonathan Avila and Aaron Alarcon*, Towards
Continuous Estimation of Dissatisfaction in Spoken
Dialog](http://cs.utep.edu/nigel/dissatisfaction/).

<p align="center">🙂 💬 🤖 📈</p>

## Set up

1. Clone this repo or download it as a ZIP archive and extract it.
2. Download [The UTEP Corpus of Dissatisfaction in Spoken
   Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus). Copy or
   move the `calls` folder, `annotations` folder, and `call-log.xlsx` to the
   project's root folder (`dissatisfaction-models`).
3. Download [Midlevel Prosodic Features
   Toolkit](https://github.com/nigelgward/midlevel). Copy or move the
   `midlevel-master` folder to the project's root folder.
4. Install MathWorks' [Signal Processing
   Toolbox](https://www.mathworks.com/products/signal.html) and [Statistics and
   Machine Learning
   Toolbox](https://www.mathworks.com/products/statistics.html). To install
   add-ons from MATLAB, from the "Home" menu tab, click "Add-Ons", then click
   "Get Add-Ons".
5. Open the project's root folder in MATLAB. MATLAB's address field (below the
   ribbon menu) should end with `.../dissatisfaction-models`.
6. Add project's root folder and its subfolders to Path. To add a folder to Path
   from MATLAB, from the "Current Folder" pane, right-click the folder, hover
   over "Add to Path", then click "Selected Folder and Subfolders".
   Alternatively, use the
   [addpath](https://www.mathworks.com/help/matlab/ref/addpath.html) function.

## [mono.fss](mono.fss) (feature specification file)

All models share a set of 125 features, specified in
[mono.fss](source/mono.fss). This feature specification file is an extended
version of the original (from the Midlevel Toolkit
[here](https://github.com/nigelgward/midlevel/blob/master/flowtest/mono.fss)),
adding features for *smoothed cepstral peak prominence*,  *late (delayed) pitch
peak*, and *voiced-unvoiced intensity ratio*.

## [loadDataFrame.m](source/loadDataFrame.m) and [loadDataDialog.m](source/loadDataFrame.m)

Load the data used by the frame-level and dialog-level models, respectively.

On first run, these scripts will compute the data and save `.mat` files to
`data/frame-level` and `data/dialog-level`, respectively. On subsequent runs,
they simply load these files. They assume "all or nothing", so they will not
recompute the data unless their data directories are empty or missing.

The dissatisfied dialogs
typically have more neutral frames compared to dissatisfied frames, so the
training data is balanced before it's saved.

These scripts call the [getXYfromFile.m](source/getXYfromFile.m) and [getXYfromTrackList.m](source/getXYfromTrackList.m) functions,
described next. All models use [The UTEP Corpus of Dissatisfaction in Spoken
Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus) and its
metadata. In code, the dissatisfaction labels `n` and `nn` are read as 0
(negative class, neutral), `d` and `dd` are read as 1 (positive class,
dissatisfied), and all other labels are ignored.

## [getXYfromFile.m](source/getXYfromFile.m)

```MATLAB
function [X, y, frameUtterances, frameTimes] = getXYfromFile(filename, featureSpec)
```

This function computes the features specified in *featureSpec* for audio *filename*, plus a
*time-into-dialog* feature. The *time-into-dialog* feature measures the time
elapsed, in seconds, since the first utterance labeled as neutral or
dissatisfied. This means predictors, *X*,
are returned one column wider than than expected. Labels are returned in *y*.

*frameUtterances* and *frameTimes* are used in failure analysis only. For frame *i*,
*frameUtterances(i)* is the utterance the frame belongs to (*1..n*). For frame *i*, *frameTimes(i)* is the time elapsed, in seconds, since
the first utterance labeled as neutral or dissatisfied.
*frameTimes* is the same as the *time-into-dialog* feature in *X*, but unlike
*X*, does not get normalized by the [loadDataFrame.m](source/loadDataFrame.m) or
[loadDataDialog.m](source/loadDataFrame.m) scripts.

## [getXYfromTrackList.m](source/getXYfromTrackList.m)

```MATLAB
function [X, y, frameTrackNums, frameUtterances, frameTimes] = getXYfromTrackList(trackList, featureSpec)
```

*X*, *y*,
*frameUtterances*, and *frameTimes* hold the same information as described for
the [getXYfromFile.m](source/getXYfromFile.m) function, concatenated for all
tracks listed in *trackList*.

*frameTrackNums* is used in failure analysis only. For
frame *i*, *frameTrackNums(i)* is the track the frame belongs to.

## [linearRegressionFrame.m](source/linearRegressionFrame.m)

A frame-level linear regression model.

For a list of dialogs in the training, validation, and test sets, see
[tracklists-frame](source/tracklists-frame). Each set comprises 6 dialogs, half
labeled as neutral and half labeled as dissatisfied.

The models' coefficients are printed in descending order. For a complete list of
coefficients, see
[linearRegressionFrameCoeffs.txt](source/linearRegressionFrameCoeffs.txt).
Abbreviated list of coefficients:

```none
Coefficients sorted by value, descending order with format:
coefficient number, value, feature abbreviation
125 | +0.180743 | NA (not specified in featureSpec)
 78 | +0.157677 | se wp  +800  +1600
 59 | +0.146737 | se np -1600 -800
 45 | +0.143111 | se th -1600 -800
 16 | +0.138269 | se vo  +1600  +3200
 ...
 76 | -0.063752 | se wp  +300  +400
 71 | -0.070330 | se wp -400 -300
114 | -0.090297 | se pd  +800  +1600
 30 | -0.108605 | se cr  +800  +1600
  2 | -0.286484 | se vo -1600 -800
```

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on
the test set:

```none
min(yPred)=-3.48, max(yPred)=4.85, mean(yPred)=0.54
dissThreshold=0.429
regressorRsquared=0.35
regressorFscore=0.58, regressorPrecision=0.57, regressorRecall=0.81, regressorMSE=0.34
baselineFscore=0.45, baselinePrecision=0.43, baselineRecall=1.00, baselineMSE=0.57
```

### Failure analysis

The last section of the script creates audio clips for failure analysis. Audio
clips (`.wav`) created from the model's best and worst predicted frames are stored
in `failure-analysis/clips-ascend` and `failure-analysis/clips-descend`,
respectively. (The smaller the difference between the model's prediction and
actual dissatisfaction score, the better.) Each directory will contain a
`clip-details.txt`, listing the clips in order and more information for
each: the filename of the original dialog, the time in seconds into the dialog,
the model's predicted dissatisfaction score, and the actual dissatisfaction score.

## [linearRegressionUtterance.m](source/linearRegressionUtterance.m)

An utterance-level linear regression model.

For an utterance, this model predicts its dissatisfaction as the mean prediction
on all frames in the utterance. This model shares the frame-level model's
training, validation, and test set (see
[tracklists-frame](source/tracklists-frame)).

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on
the test set:

```none
beta=0.25, min(yPred)=-0.02, max(yPred)=1.26, mean(yPred)=0.51
dissThreshold=0.557
regressorFscore=0.61, regressorPrecision=0.60, regressorRecall=0.82, regressorMSE=0.25
baselineFscore=0.39, baselinePrecision=0.38, baselineRecall=1.00, baselineMSE=0.62
```

## [linearRegressionDialog.m](source/linearRegressionDialog.m)

A dialog-level linear regression model.

This model uses two linear regressors. The first level regressor outputs
dissatisfaction scores from prosody features. The second level regressor
predicts dissatisfaction from summary features, calculated from the first level
regressor's output. For training, validation, and test sets, see
[tracklists-dialog](source/tracklists-dialog).

For each dialog, the summary features are: (1) the fraction of frames above a
"dissatisfaction threshold" (see comment in
[linearRegressionFrame.m](source/linearRegressionFrame.m)); (2) the range of its
dissatisfaction scores; and (3) the standard deviation of its dissatisfaction
scores. The summary features are computed for each dialog from (including) the
first utterance labeled as neutral or dissatisfied to (including) the last
utterance labeled as neutral or dissatisfied.

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on
the test set:

```none
beta=0.25, min(yPred)=-0.19, max(yPred)=2.33, mean(yPred)=0.36
dissThreshold=0.168
regressorFscore=0.55, regressorPrecision=0.54, regressorRecall=0.84, regressorMSE=0.39
baselineFscore=0.52, baselinePrecision=0.51, baselineRecall=1.00, baselineMSE=0.49
```

## [calculateCorpusStats.m](source/calculateCorpusStats.m)

Print the number of neutral and dissatisfied frames, and the number of neutral
and dissatisfied utterances, in the dialog-level sets.

Output:

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

## To do

- [ ] The values for neutral and dissatisfaction labels are hardcoded as 0 and
  1, respectively, throughout the code. Try defining them only once.
- [ ] Many functions rely on the `pwd` command. This explains why the project's
  root folder must be set as the working directory before running any scripts.
  Avoid using `pwd` entirely if possible, and update the code to use relative
  paths only.
- [ ] Since working from a non-Windows machine, I've replaced all backslashes
  (`\`) with forward slashes (`/`) in path strings. This means the code is not
  currently compatible with Windows machines. Try making the code compatible for
  all systems.
- [ ] Add documentation for remaining key files, or indicate which files need
  updating since August 11, 2021.
