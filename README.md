# Detecting dissatisfaction in spoken dialog

## Set up

1. Clone this repo or download it as a ZIP and extract.
1. Download The UTEP Corpus of Dissatisfaction in Spoken Dialog at
   <https://github.com/joneavila/utep-dissatisfaction-corpus>. Place the `calls`
   folder and `call-log.xlsx` in the root of this project.
1. Download Midlevel Prosodic Features Toolkit at
   <https://github.com/nigelgward/midlevel>. Place the `midlevel-master` folder
   in the root of this project.
1. Open this project
(`dissatisfaction-models` folder) in MATLAB and add the folder and its subfolders to
   Path. Right-click the folder in the Current Folder window or use the
   [addpath](https://www.mathworks.com/help/matlab/ref/addpath.html) function.

## Notes

**Results for 'ja' annotations only. Results are for dev set unless otherwise stated.**

We took the corpus and annotated customer utterances. See [annotations](annotations). To predict dissatisfaction
on a scale from 0 to 1 where 0 is neutral (negative class) and 1 is dissatisfied
(positive class), `n` and `nn` are read as 0, `d` and `dd` are read as 1, and
all other labels are ignored. See [annotations/annotation-guide.txt](annotations/annotation-guide.txt).

Features used are original mono.fss with added `cp` for same windows. See
[mono.fss](mono.fss). (The linear regression model uses a different spec file,
with less cp windows.)

The code was written in MATLAB and uses MATLAB's built-in functions for
performing linear regression, logistic regression, and k-nearest neighbor
classification.

## Frame-level model (linear regression)

The frame-level models share a train, dev, and test set (see [frame-level/train.tl](frame-level/train.tl),
[frame-level/dev.tl](frame-level/dev.tl), and [frame-level/test.tl](frame-level/test.tl)). Each set is 6
dialogs, half labeled as neutral and half labeled as dissatisfied on the
dialog-level. The dissatisfied dialogs still have many neutral utterances so the
data is not balanced.

set | `n` or `nn` frames | `d` and `dd` frames
---   | --- | ---
train | 15894 | 15455
dev   | 24023 |  8306
test  | 20458 | 11401

The baseline always predicts 1 for perfectly dissatisfied. Results using the
test set,

```NONE
min(yPred)=-0.370, max(yPred)=1.082
thresholdMin=-0.25, thresholdMax=1.10, thresholdStep=0.05
    threshold    precisionLinear    precisionBaseline
    _________    _______________    _________________

      -0.25          0.35715             0.35786     
       -0.2          0.35637             0.35786     
      -0.15          0.35705             0.35786     
       -0.1          0.35707             0.35786     
      -0.05          0.35753             0.35786     
          0          0.35645             0.35786     
       0.05          0.35468             0.35786     
        0.1          0.35716             0.35786     
       0.15          0.36362             0.35786     
        0.2          0.37118             0.35786     
       0.25          0.38731             0.35786     
        0.3          0.40919             0.35786     
       0.35          0.43307             0.35786     
        0.4          0.46776             0.35786     
       0.45          0.51799             0.35786     
        0.5          0.57667             0.35786     
       0.55          0.63784             0.35786     
        0.6          0.70028             0.35786     
       0.65          0.75994             0.35786     
        0.7          0.80437             0.35786     
       0.75          0.82166             0.35786     
        0.8          0.87517             0.35786     
       0.85          0.94853             0.35786     
        0.9           0.9951             0.35786     
       0.95                1             0.35786     
          1                1                 NaN     
       1.05                1                 NaN
```

The learned coefficients are saved to
`coefficients.txt`.

```NONE
Coefficients in descending order with format:
coefficient, value, abbreviation
17 | 1.223681 | se cr -1600 -800
30 | 0.996185 | se cr  +800  +1600
29 | 0.517663 | se cr  +400  +800
18 | 0.506640 | se cr -800 -400
16 | 0.161338 | se vo  +1600  +3200
...
57 | -0.281625 | se th  +400  +800
31 | -0.381581 | se tl -1600 -800
45 | -0.449197 | se th -1600 -800
44 | -0.451788 | se tl  +800  +1600
58 | -0.935403 | se th  +800  +1600
```

A histogram of the regressor's output shows frames that are predicted as 1 or
above are more likely to be dissatisfied than neutral. Those predictions are
more likely to be correct, so the threshold (used when converting floats back
into labels) can be set to favor precision.
![regressor output couple cp features](images/regressor-output-couple-cp.png)

### Failure analysis

The code finds which frames in the compare set (dev set or
test set, but using dev set for now) had the largest misclassification, or
largest difference between `yPred` and `yCompare`. Then clips are created for
these frames, but only if the frame has not already been included in a clip. The
misclassification happens at the middle of the clip, i.e. the rest is included
for context. As an example, here's the output for the second clip,

```NONE
clip14094  timeSeconds=7.06  filename=20210122-jl-5fa2e888f2ec2d41c1faf2d1-tire-y-y.wav
      predicted=1.15  actual=0.00
```

Meaning frame #14094 from the compare set was misclassified, predicted as 1.15 when
actually 0, and the frame corresponds to 7.06 seconds into
`20210122-jl-5fa2e888f2ec2d41c1faf2d1-tire-y-y`.

The code generates two clips for each of these. The first one will be named
`clip14094-1seconds.wav` and the second `clip14094-2seconds`. The number of clips and
the size of the context can be adjusted.

To run from MATLAB: `>> linearRegression`

### Other models

A k-nearest neighbor classifier with number of neighbors 5 and rest of default
parameters.

To run from MATLAB: `>> kNNframeLevel`

A logistic regressor.

To run from MATLAB: `>> logisticRegression`

## Utterance-level model

Predict on utterances using the linear regressor's frame-level
predictions. For each utterance in the compare set (dev or test), predicts the mean of the
predictions on the frames belonging to that utterance. The baseline always predicts 1 for perfectly dissatisfied. Results using the
test set,

```NONE
min(yPred)=-0.016, max(yPred)=0.704
thresholdMin=-0.25, thresholdMax=1.10, thresholdStep=0.05
    threshold    precisionUtterance    precisionBaseline    recallUtterance    recallBaseline    scoreUtterance    scoreBaseline
    _________    __________________    _________________    _______________    ______________    ______________    _____________

      -0.25           0.31707               0.31707                   1              1              0.48148           0.48148   
       -0.2           0.31707               0.31707                   1              1              0.48148           0.48148   
      -0.15           0.31707               0.31707                   1              1              0.48148           0.48148   
       -0.1           0.31707               0.31707                   1              1              0.48148           0.48148   
      -0.05           0.31707               0.31707                   1              1              0.48148           0.48148   
          0               0.3               0.31707             0.92308              1              0.45283           0.48148   
       0.05           0.28205               0.31707             0.84615              1              0.42308           0.48148   
        0.1            0.2973               0.31707             0.84615              1                 0.44           0.48148   
       0.15           0.30556               0.31707             0.84615              1              0.44898           0.48148   
        0.2           0.32353               0.31707             0.84615              1              0.46809           0.48148   
       0.25           0.36667               0.31707             0.84615              1              0.51163           0.48148   
        0.3           0.41667               0.31707             0.76923              1              0.54054           0.48148   
       0.35            0.4375               0.31707             0.53846              1              0.48276           0.48148   
        0.4           0.57143               0.31707             0.30769              1                  0.4           0.48148   
       0.45           0.66667               0.31707             0.30769              1              0.42105           0.48148   
        0.5               0.8               0.31707             0.30769              1              0.44444           0.48148   
       0.55               0.8               0.31707             0.30769              1              0.44444           0.48148   
        0.6               0.8               0.31707             0.30769              1              0.44444           0.48148   
       0.65                 1               0.31707            0.076923              1              0.14286           0.48148   
        0.7                 1               0.31707            0.076923              1              0.14286           0.48148   
       0.75               NaN               0.31707                   0              1                    0           0.48148   
        0.8               NaN               0.31707                   0              1                    0           0.48148   
       0.85               NaN               0.31707                   0              1                    0           0.48148   
        0.9               NaN               0.31707                   0              1                    0           0.48148   
       0.95               NaN               0.31707                   0              1                    0           0.48148   
          1               NaN                   NaN                   0              0                    0                 0   
       1.05               NaN                   NaN                   0              0                    0                 0
```

To run from MATLAB: `>> utteranceLevel`

## Dialog-level k-NN model

A k-nearest neighbor classifier. Number of neighbors is 5 and rest of default
parameters. X and y are downsampled so that each frame is 100ms apart. The MAE
is **NUM** and F1 score **NUM**. The baseline predicts the majority class (neutral);
its MAE is **NUM** and F1 score **NUM**.

To run from MATLAB: `>> kNNdialogLevel`

## Histograms

Save a histogram for each feature in the train and dev set. Save histograms
to `frame-level/histograms`. Here's an example,

![feature-histogram-example](images/feature-histogram-example.png)

The rest of the histograms are in [frame-level/histograms](frame-level/histograms). The histograms are normalized so that bar heights add to 1. `feat01` through
`feat16` (volume) have bimodal distributions likely because quiet frames like
those at the start and end of utterances make up the first mode and the average
speaking volume makes up the second mode. A silent frame is more likely to be
neutral, possibly because neutral utterances tend to be shorter and the more
utterances the more silence is introduced at the start and end of those
utterances. `feat17` through `feat30` (creakiness) have skewed distributions likely
because there is little evidence for creakiness and so the distribution skews
right. `feat69` through `feat78` (wide pitch) distributions show that frames above a
threshold (around 0.8, depending on the window) are more likely to be
dissatisfied, and frames below the threshold are more likely to be neutral.
Shock might explain some wideness, for example someone saying "What? I thought
you said..."

The code also generates a histogram for the linear regressor's output on the dev
set. (The image is above, in the linear regression section. The code should be
separated at some point.)

To run from MATLAB: `>> generateHistograms`

## t-tests

The first t-test is for features between neutral frames (N) and dissatisfied
frames (D) from the
train and dev set. Output (replace output),

The second t-test is between the linear regressor's predictions for N and
predictions D. The test result is **NUM** (rejects null hypothesis if value is 1).

To run from MATLAB: `>> tTests`
