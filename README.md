# Models for detecting dissatisfaction in dialog

## Contents

- `dialog-level` - dialog-level k-NN model
- `frame-level` - frame-level k-NN model and linear regression model

## Set up

1. Download The UTEP Corpus of Dissatisfaction in Spoken Dialog at <https://github.com/joneavila/utep-dissatisfaction-corpus>. Place the `calls` folder and `call-log.xlsx` in the root of this project.
1. Download Midlevel Prosodic Features Toolkit at <https://github.com/nigelgward/midlevel>. Place the `midlevel-master` folder in the root of this project.
1. Download annotations `ja-annotations` and place the folder in the root of this project. This is necessary for the frame-level model only.
1. Clone this repo or download it as a ZIP and extract. Open the `dissatisfaction-models` in MATLAB and add the folder and its subfolders to Path.

## Frame-level k-NN model

Predictions are on single frames (10ms). Reads labels from annotator `ja`. Utterances were labeled as `d`, `dd`, `n`, `nn`, `o`, and `?` (for more, see annotation guidelines). To predict disappointment on a scale from 0 to 1, `n` or `nn` are read as 0 and `d` or `dd` are read as 1. To run from MATLAB,

```MATLAB
kNNframeLevel
```

## Linear regression model

Reads labels from annotator `ja`. Output:

```MATLAB
Sorted coefficients in descending order with format: coefficient, value, abbreviation
17 | 1.031855 | se cr -1600 -800
30 | 0.760532 | se cr  +800  +1600
18 | 0.426020 | se cr -800 -400
29 | 0.424840 | se cr  +400  +800
16 | 0.154492 | se vo  +1600  +3200
...
57 | -0.363121 | se th  +400  +800
44 | -0.431529 | se tl  +800  +1600
31 | -0.499117 | se tl -1600 -800
45 | -0.504644 | se th -1600 -800
58 | -0.955588 | se th  +800  +1600
```

```MATLAB
Mean Absolute Error = 0.45244
```

To run from MATLAB,

```MATLAB
linearRegression
```

## Dialog-level k-NN model

(This code needs some tweaking after I moved some files around.) To run from MATLAB,

```MATLAB
kNNdialogLevel
```

## T-test

A two-sample t-test to test the hypothesis that data from neutral frames and data from dissatisfied frames come from populations with unequal means, i.e. test whether each feature is significantly different between neutral frames and dissatisfied frames. To run from MATLAB,

```MATLAB
tTest
```
