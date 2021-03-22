# Models for detecting dissatisfaction in dialog

## Repo contents

- `dialog-level` - dialog-level k-NN model
- `frame-level` - frame-level k-NN model
- `linear-regression` - linear regression model
- `mono.fss` feature specification file with X features, used in previous work *here*

## Set up

1. Download The UTEP Corpus of Dissatisfaction in Spoken Dialog at <https://github.com/joneavila/utep-dissatisfaction-corpus>. Place the `calls` folder and `call-log.xlsx` in the root of this project.
1. Download Midlevel Prosodic Features Toolkit at <https://github.com/nigelgward/midlevel>. Place the `midlevel-master` folder in the root of this project.
1. Download annotations `ja-annotations` and place the folder in the root of this project. This is necessary for the frame-level model only.

## Frame-level k-NN model

Predictions are on single frames (10ms). Reads labels from annotator `ja`. Utterances were labeled as `d`, `dd`, `n`, `nn`, `o`, and `?` (for more, see annotation guidelines). To predict disappointment on a scale from 0 to 1, `n` or `nn` are treated as 0 and `d` or `dd` are treated as 1

To run, open `knn-models` in MATLAB and run `kNNframeLevel.m`.

## Linear regression model

Reads labels from annotator `ja`. Output:

```MATLAB
Sorted coefficients in descending order. First 5 coefficients:
 Coefficient 18 with value 1.031855
 Coefficient 31 with value 0.760532
 Coefficient 19 with value 0.426020
 Coefficient 30 with value 0.424840
 Coefficient 17 with value 0.154492
```

Corresponding features from `mono.fss`:

1. `cr  -800 to  -400 self` (creaky, feature 18)
1. `tl -1600 to  -800 self` (pitch lowness, feature 31)
1. `cr  -400 to  -300 self` (creaky, feature 19)
1. `cr   800 to  1600 self` (creaky, feature 30)
1. `cr -1600 to  -800 self` (creaky, feature 17)

To run, open `knn-models` in MATLAB and run `linearRegression.m`.

## Dialog-level k-NN model

This code needs some tweaking after I moved some files around.

To run, open `knn-models` in MATLAB and run `kNNdialogLevel.m`.