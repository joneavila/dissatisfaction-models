# Models for detecting dissatisfaction in dialog

## Set up

1. Download The UTEP Corpus of Dissatisfaction in Spoken Dialog at
   <https://github.com/joneavila/utep-dissatisfaction-corpus>. Place the `calls`
   folder and `call-log.xlsx` in the root of this project.
1. Download Midlevel Prosodic Features Toolkit at
   <https://github.com/nigelgward/midlevel>. Place the `midlevel-master` folder
   in the root of this project.
1. Download annotations `ja-annotations` and place the folder in the root of
   this project. This is necessary for the frame-level model only.
1. Clone this repo or download it as a ZIP and extract. Open the
   `dissatisfaction-models` in MATLAB and add the folder and its subfolders to
   Path.

## Frame-level models

The frame-level models share a train, dev, and test set
(`frame-level/train.tl`, `frame-level/dev.tl`, and `frame-level/train.tl`,
respectively).
Customer utterances were labeled as `d`, `dd`, `n`, `nn`, `o`, and `?` by three
annotators following guidelines [here]. To predict dissatisfaction on a scale from 0 to 1 where 0 is
neutral and 1 is dissatisfied, `n` and `nn` are read as 0, `d` and `dd` are read
as 1, and all other labels are ignored. Predictions are on single frames of 10ms. The data is not balanced; there are many more neutral labels than dissatisfied labels. [A statistic would be nice.]

### Frame-level k-NN model

A k-nearest neighbor classifier using MATLAB's `fitcknn` function. Reads labels from annotator `ja`. Trains with train set and predicts on dev set. The F-score is 0.328 and mean absolute error is 0.523.

To run from MATLAB: `>>kNNframeLevel`

### Frame-level linear regression model

A linear regressor using MATLAB's `fitlm` function. Reads labels from annotator `ja`. Trains with train set and predicts on dev set. The baseline predicts the majority class (in this case 0 for neutral). The regressor's mean absolute error (MAE) is
0.452. The baseline's MAE is 0.257. The learned coefficients are saved to `coefficients.txt`, 

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

To run from MATLAB: `>>linearRegression`

## Dialog-level model (k-NN model)

[Description of model.] The mean absolute error is 0.0502. (The F-score is NaN due to a bug.)

To run from MATLAB: `>>kNNdialogLevel`

## Feature histograms

Save a histogram for each feature used in the train and dev set. Save histograms
to `frame-level/images`. Here's an example,

![Histogram for Feature 15 "se vo +800 +1600" neutral train+dev, nBins=30](images/histogram.png)

The feature specification file lays out what features and what windows to use. [An example.] For `mono.fss` in particular, window sizes become larger the further away they are from t=0. Features of the same feature but different window have similar distributions. For example, feat01 through feat16 (volume) have bimodal distributions likely because quiet frames at the start and end of utterances make up the first mode and the average volume makes up the second mode. As another example, feat17 through feat30 (creakiness) have skewed distributions likely because there is little evidence for creakiness and so the distribution skews right. The distributions for the remaining features follow our expectations. [Do they show that neutral and dissatisfied are significantly different?]

To run from MATLAB: `>>generateHistograms`

## t-tests

Displays which features are significantly different between neutral frames and
dissatisfied frames. Output,

```MATLAB
The following features reject the null hypothesis:
#1 se vo -3200 -1600
#2 se vo -1600 -800
#3 se vo -800 -400
#4 se vo -400 -300
#5 se vo -300 -200
#6 se vo -200 -100
#7 se vo -100 -50
#8 se vo -50  +0
#9 se vo  +0  +50
#10 se vo  +50  +100
#11 se vo  +100  +200
#12 se vo  +200  +300
#13 se vo  +300  +400
#15 se vo  +800  +1600
#16 se vo  +1600  +3200
#17 se cr -1600 -800
#18 se cr -800 -400
#19 se cr -400 -300
#20 se cr -300 -200
#21 se cr -200 -100
#22 se cr -100 -50
#23 se cr -50  +0
#24 se cr  +0  +50
#25 se cr  +50  +100
#26 se cr  +100  +200
#27 se cr  +200  +300
#28 se cr  +300  +400
#29 se cr  +400  +800
#30 se cr  +800  +1600
#31 se tl -1600 -800
#32 se tl -800 -400
#33 se tl -400 -300
#34 se tl -300 -200
#35 se tl -200 -100
#36 se tl -100 -50
#37 se tl -50  +0
#38 se tl  +0  +50
#39 se tl  +50  +100
#40 se tl  +100  +200
#41 se tl  +200  +300
#42 se tl  +300  +400
#43 se tl  +400  +800
#44 se tl  +800  +1600
#45 se th -1600 -800
#47 se th -400 -300
#48 se th -300 -200
#49 se th -200 -100
#50 se th -100 -50
#51 se th -50  +0
#52 se th  +0  +50
#53 se th  +50  +100
#54 se th  +100  +200
#55 se th  +200  +300
#56 se th  +300  +400
#57 se th  +400  +800
#59 se np -1600 -800
#60 se np -800 -400
#61 se np -400 -300
#62 se np -300 -200
#63 se np -200  +0
#64 se np  +0  +200
#65 se np  +200  +300
#66 se np  +300  +400
#67 se np  +400  +800
#68 se np  +800  +1600
#69 se wp -1600 -800
#70 se wp -800 -400
#71 se wp -400 -300
#72 se wp -300 -200
#73 se wp -200  +0
#74 se wp  +0  +200
#75 se wp  +200  +300
#76 se wp  +300  +400
#77 se wp  +400  +800
#78 se wp  +800  +1600
#79 se sr -1600 -800
#80 se sr -800 -400
#81 se sr -400 -200
#82 se sr -200 -100
#83 se sr -100  +0
#84 se sr  +0  +100
#85 se sr  +100  +200
#86 se sr  +200  +400
#87 se sr  +400  +800
#88 se sr  +800  +1600
The following features do not reject the null hypothesis:
#14 se vo  +400  +800
#46 se th -800 -400
#58 se th  +800  +1600
```

To run from MATLAB: `>> tTest`
