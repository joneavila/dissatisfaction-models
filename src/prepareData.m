%% prepare the data
useTestSet = false;

trackListTrain = gettracklist('train-frame.tl');
trackListDev = gettracklist('dev-frame.tl');
trackListTest = gettracklist('test-frame.tl');

featureSpec = getfeaturespec('.\mono-extended.fss');

useAllAnnotators = false;

% [Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, frameUtterancesTrain] = ...
%     getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
% [Xdev, yDev, frameTrackNumsDev, frameTimesDev, frameUtterancesDev] = ...
%     getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);
% [Xtest, yTest, frameTrackNumsTest, frameTimesTest, frameUtterancesTest] = ...
%     getXYfromTrackList(trackListTest, featureSpec, useAllAnnotators);
%% drop neutral frames (or dissatisfied) frames to balance the data set

rng(20210419); % set seed for reproducibility

idxNeutral = find(yTrain == 0);
idxDissatisfied = find(yTrain == 1);

numNeutral = length(idxNeutral);
numDissatisfied = length(idxDissatisfied);

if numNeutral > numDissatisfied
    selections = randsample(numNeutral, numNeutral - numDissatisfied);
    idxRemove = idxNeutral(selections);
elseif numDissatisfied > numNeutral
    selections = randsample(numDissatisfied, numDissatisfied - numNeutral);
    idxRemove = idxDissatisfied(selections);
end

frameTimesTrain(idxRemove) = [];
frameTrackNumsTrain(idxRemove) = [];
frameUtterancesTrain(idxRemove) = [];
Xtrain(idxRemove, :) = [];
yTrain(idxRemove) = [];
%% Copy dev or test set as 'compare' set
% So that the rest of the code can be used for either set
if useTestSet
    Xcompare = Xtest;
    yCompare = yTest;
    frameTrackNumsCompare = frameTrackNumsTest;
    frameTimesCompare = frameTimesTest;
    frameUtterancesCompare = frameUtterancesTest;
    trackListCompare = trackListTest;
else
    Xcompare = Xdev;
    yCompare = yDev;
    frameTrackNumsCompare = frameTrackNumsDev;
    frameTimesCompare = frameTimesDev;
    frameUtterancesCompare = frameUtterancesDev;
    trackListCompare = trackListDev;
end
%% normalize data

% normalize train data
[Xtrain, centeringValues, scalingValues] = normalize(Xtrain);

% normalize compare (dev or test) data using the same centering values 
% and scaling values used to normalize the train data
Xcompare = normalize(Xcompare, 'center', centeringValues, 'scale', scalingValues);