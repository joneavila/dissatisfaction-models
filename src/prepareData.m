% prepareData.m

%% config
useTestSet = false;
useAllAnnotators = false;

%% load precomputed data if found, else compute it
trackListTrain = gettracklist('train-frame.tl');
trackListDev = gettracklist('dev-frame.tl');
trackListTest = gettracklist('test-frame.tl');

featureSpec = getfeaturespec('.\mono-extended.fss');

% load the train data if found, else compute it
if ~exist('Xtrain', 'var') || ~exist('yTrain', 'var') || ...
        ~exist('frameTrackNumsTrain', 'var') || ...
        ~exist('frameTimesTrain', 'var') || ...
        ~exist('frameUtterNumsTrain', 'var')
    [Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, ...
        frameUtterNumsTrain] = getXYfromTrackList(trackListTrain, ...
        featureSpec, useAllAnnotators);
end

% load the compare data (dev or test data, depending on the value of 
% useTestSet), else compute it
if ~exist('Xcompare', 'var') || ~exist('yCompare', 'var') || ...
        ~exist('frameTrackNumsCompare', 'var') || ...
        ~exist('frameTimesCompare', 'var') || ...
        ~exist('frameUtterNumsCompare', 'var')
    if useTestSet
        [Xcompare, yCompare, frameTrackNumsCompare, frameTimesCompare, ...
            frameUtterNumsCompare] = getXYfromTrackList(trackListTest, ...
            featureSpec, useAllAnnotators);
    else
        [Xcompare, yCompare, frameTrackNumsCompare, frameTimesCompare, ...
            frameUtterNumsCompare] = getXYfromTrackList(trackListDev, ...
            featureSpec, useAllAnnotators);
    end
end

%% drop neutral (or dissatisfied) frames in the train data to balance it

% set seed for reproducibility
rng(20210419);

idxNeutral = find(yTrain == 0);
idxDissatisfied = find(yTrain == 1);

numNeutral = length(idxNeutral);
numDissatisfied = length(idxDissatisfied);
numDifference = abs(numNeutral - numDissatisfied);

if numDifference
    if numNeutral > numDissatisfied
        idxToDrop = randsample(idxNeutral, numDifference);
    elseif numDissatisfied > numNeutral
        idxToDrop = randsample(numDissatisfied, numDifference);
    end
    frameTimesTrain(idxToDrop) = [];
    frameTrackNumsTrain(idxToDrop) = [];
    frameUtterNumsTrain(idxToDrop) = [];
    Xtrain(idxToDrop, :) = [];
    yTrain(idxToDrop) = [];
end
%% normalize data

% normalize train data
[Xtrain, normalizeCenteringValues, normalizeScalingValues] = ...
    normalize(Xtrain);

% normalize compare data using the same centering values and scaling values
% used to normalize the train data
Xcompare = normalize(Xcompare, 'center', normalizeCenteringValues, ...
    'scale', normalizeScalingValues);

%% clear unnecessary variables
clear useTestSet useAllAnnotators
clear trackListTrain trackListDev trackListTest
clear idxNeutral idxDissatisfied numNeutral numDissatisfied
clear selections idxToDrop