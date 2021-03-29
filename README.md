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

## Feature specification file

[It is mono.fss with added 'cp' feature.]

## Frame-level models

The frame-level models share a train, dev, and test set
(`frame-level/train.tl`, `frame-level/dev.tl`, and `frame-level/train.tl`,
respectively).

Customer utterances were labeled as `d`, `dd`, `n`, `nn`, `o`, and `?` by three
annotators following guidelines [here]. To predict dissatisfaction on a scale
from 0 to 1 where 0 is neutral and 1 is dissatisfied, `n` and `nn` are read as
0, `d` and `dd` are read as 1, and all other labels are ignored. Predictions
are on single frames of 10ms. The data is not balanced; there are many more
neutral labels than dissatisfied labels. [A statistic would be nice.]

### Frame-level k-NN model

A k-nearest neighbor classifier using MATLAB's `fitcknn` function. Reads labels
from annotator `ja`. Trains with train set and predicts on dev set. The F-score
is 0.328 and mean absolute error (MAE) is **0.523**.

To run from MATLAB: `>>kNNframeLevel`

### Frame-level linear regression model and utterance-level model

A linear regressor using MATLAB's `fitlm` function. Reads labels from annotator
`ja`. Trains with train set and predicts on dev set. The baseline predicts the
majority class (in this case 0 for neutral). The frame-level MAE is **0.452**. The baseline MAE is **0.257**. The learned coefficients are saved
to `coefficients.txt`. Here is a preview of the file,

```NONE
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

The frame-level linear regression model is also used to predict on utterances.
The utterance-level model predicts the mean of its frame-level predictions. The
baseline predicts the mode of its frame-level predictions.
mode of its frame-level predictions. The utterance-level MAE is **0.344**. The
baseline MAE is **0.440**. Output for each
dialog,

```NONE
predicting on 20210115-aa-5f2fad64d1609e000b157ba5-magician-y-y.wav
    utterancePred    utterancePredRound    utteranceActual
    _____________    __________________    _______________

        0.5466               1                    0       
       0.28539               0                    0       
        0.4921               0                    0       
       0.19063               0                    0       
       0.44349               0                    0       
       0.66648               1                    1       
       0.69928               1                    1       
       0.78552               1                    1       
       0.50941               1                    0       
       0.58747               1                    1       
       0.76767               1                    1       
       0.65332               1                    1       
       0.66585               1                    1       
       0.36921               0                    0  
```

To run from MATLAB: `>>linearRegression`

## Dialog-level k-NN model

A k-nearest neighbor classifier using MATLAB's `fitcknn` function. The MAE is
0.0502. The F1 score is 0. [The baseline has not been written yet.]

To run from MATLAB: `>>kNNdialogLevel`

## Feature histograms

Save a histogram for each feature in the train and dev set. Save histograms
to `frame-level/images`. Here's an example,

![Histogram for Feature 15 "se vo +800 +1600" neutral train+dev, nBins=30](images/histogram.png)

The feature specification file lays out what features and what windows to use.
[An example.] For `mono.fss` in particular, window sizes become larger the
further away they are from t=0. The distributions follow
our expectations. The histograms are normalized so that bar heights add to 1.
For example, feat01 through feat16 (volume)
have bimodal distributions likely because quiet frames at the start and end of
utterances make up the first mode and the average volume makes up the second
mode. As another example, feat17 through feat30 (creakiness) have skewed
distributions likely because there is little evidence for creakiness and so the
distribution skews right. [Do they show that neutral and dissatisfied are significantly
different?]

To run from MATLAB: `>> generateHistograms`

## t-tests

The first t-test is for features between neutral frames (N) and dissatisfied
frames (D) from the
train and dev set. Output,

```NONE
     feature abbreviation      rejects null?      p-value  
    _______________________    _____________    ___________

    {'se vo -3200 -1600'  }        true          5.5622e-73
    {'se vo -1600 -800'   }        true          5.4532e-13
    {'se vo -800 -400'    }        true            0.030496
    {'se vo -400 -300'    }        true          2.1228e-09
    {'se vo -300 -200'    }        true          3.1676e-14
    {'se vo -200 -100'    }        true          5.4054e-19
    {'se vo -100 -50'     }        true          1.7655e-26
    {'se vo -50  +0'      }        true          8.5117e-29
    {'se vo  +0  +50'     }        true          8.0859e-31
    {'se vo  +50  +100'   }        true          1.1324e-30
    {'se vo  +100  +200'  }        true          8.2284e-23
    {'se vo  +200  +300'  }        true          6.3098e-15
    {'se vo  +300  +400'  }        true          3.5569e-09
    {'se vo  +400  +800'  }        false            0.10561
    {'se vo  +800  +1600' }        true          6.8368e-15
    {'se vo  +1600  +3200'}        true          1.4088e-54
    {'se cr -1600 -800'   }        true                   0
    {'se cr -800 -400'    }        true         8.1608e-234
    {'se cr -400 -300'    }        true          6.7051e-68
    {'se cr -300 -200'    }        true          3.6657e-67
    {'se cr -200 -100'    }        true          4.3382e-65
    {'se cr -100 -50'     }        true          2.2744e-40
    {'se cr -50  +0'      }        true          1.4552e-39
    {'se cr  +0  +50'     }        true          4.2149e-39
    {'se cr  +50  +100'   }        true          5.7944e-39
    {'se cr  +100  +200'  }        true          2.5197e-62
    {'se cr  +200  +300'  }        true          9.7084e-69
    {'se cr  +300  +400'  }        true          3.4148e-78
    {'se cr  +400  +800'  }        true         9.4629e-219
    {'se cr  +800  +1600' }        true                   0
    {'se tl -1600 -800'   }        true         3.9895e-185
    {'se tl -800 -400'    }        true          3.0009e-86
    {'se tl -400 -300'    }        true          8.9309e-38
    {'se tl -300 -200'    }        true          2.8801e-30
    {'se tl -200 -100'    }        true          1.3516e-23
    {'se tl -100 -50'     }        true          4.9229e-17
    {'se tl -50  +0'      }        true          2.0642e-15
    {'se tl  +0  +50'     }        true          1.3243e-14
    {'se tl  +50  +100'   }        true           1.304e-14
    {'se tl  +100  +200'  }        true          4.4012e-18
    {'se tl  +200  +300'  }        true          2.5697e-19
    {'se tl  +300  +400'  }        true          3.9487e-22
    {'se tl  +400  +800'  }        true          1.3545e-56
    {'se tl  +800  +1600' }        true         2.8582e-144
    {'se th -1600 -800'   }        true          7.5565e-10
    {'se th -800 -400'    }        false            0.56837
    {'se th -400 -300'    }        true          1.4626e-05
    {'se th -300 -200'    }        true          1.2966e-06
    {'se th -200 -100'    }        true          4.0619e-07
    {'se th -100 -50'     }        true          3.5999e-07
    {'se th -50  +0'      }        true           9.428e-08
    {'se th  +0  +50'     }        true          2.7614e-08
    {'se th  +50  +100'   }        true          1.7925e-08
    {'se th  +100  +200'  }        true          3.9816e-09
    {'se th  +200  +300'  }        true          1.2863e-06
    {'se th  +300  +400'  }        true          0.00021014
    {'se th  +400  +800'  }        true          0.00051015
    {'se th  +800  +1600' }        false            0.95353
    {'se np -1600 -800'   }        true          1.1142e-28
    {'se np -800 -400'    }        true           1.448e-57
    {'se np -400 -300'    }        true          1.0685e-26
    {'se np -300 -200'    }        true          5.8502e-29
    {'se np -200  +0'     }        true          8.9558e-62
    {'se np  +0  +200'    }        true          7.4006e-66
    {'se np  +200  +300'  }        true          3.8425e-32
    {'se np  +300  +400'  }        true          2.1939e-27
    {'se np  +400  +800'  }        true          7.6168e-47
    {'se np  +800  +1600' }        true          3.3942e-17
    {'se wp -1600 -800'   }        true                   0
    {'se wp -800 -400'    }        true         6.3689e-197
    {'se wp -400 -300'    }        true          1.7196e-39
    {'se wp -300 -200'    }        true          3.2623e-35
    {'se wp -200  +0'     }        true          1.2199e-45
    {'se wp  +0  +200'    }        true          1.5947e-40
    {'se wp  +200  +300'  }        true          7.8107e-29
    {'se wp  +300  +400'  }        true          1.0979e-32
    {'se wp  +400  +800'  }        true         2.1769e-152
    {'se wp  +800  +1600' }        true                   0
    {'se sr -1600 -800'   }        true         1.5646e-302
    {'se sr -800 -400'    }        true         2.2131e-181
    {'se sr -400 -200'    }        true         6.9178e-140
    {'se sr -200 -100'    }        true         1.7948e-161
    {'se sr -100  +0'     }        true         2.4495e-160
    {'se sr  +0  +100'    }        true         1.2612e-166
    {'se sr  +100  +200'  }        true         1.7564e-186
    {'se sr  +200  +400'  }        true         1.0144e-166
    {'se sr  +400  +800'  }        true         4.3446e-176
    {'se sr  +800  +1600' }        true         7.0244e-240
```

The second t-test is between the linear regressor's predictions for N and
predictions D. The test result is **1** (rejects null hypothesis).

To run from MATLAB: `>> tTests`
