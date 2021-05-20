% prepareData.m

%% load precomputed data if found, else compute it
trackListTrain = gettracklist('tracklists-frame\train.tl');
trackListDev = gettracklist('tracklists-frame\dev.tl');
trackListTest = gettracklist('tracklists-frame\test.tl');

featureSpec = getfeaturespec('.\source\mono.fss');

dataDirectory = append(pwd, '\data\frame-level');
if ~exist(dataDirectory, 'dir')
    mkdir(dataDirectory)
end

% load the train data, else compute it and save it for future runs
filenamesTrain = ["frameTimesTrain" "frameTrackNumsTrain" ...
    "frameUtterNumsTrain" "Xtrain" "yTrain"];
loadedAll = true;
for i = 1:length(filenamesTrain)
    saveFilename = append(dataDirectory, '\', filenamesTrain(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, ...
        frameUtterNumsTrain] = getXYfromTrackList(trackListTrain, ...
        featureSpec);
    for i = 1:length(filenamesTrain)
        saveFilename = append(dataDirectory, '\', filenamesTrain(i), '.mat');
        save(saveFilename, filenamesTrain(i));
    end
end

% load the dev data, else compute it and save it for future runs
filenamesDev = ["frameTimesDev" "frameTrackNumsDev" ...
    "frameUtterNumsDev" "Xdev" "yDev"];
loadedAll = true;
for i = 1:length(filenamesDev)
    saveFilename = append(dataDirectory, '\', filenamesDev(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [Xdev, yDev, frameTrackNumsDev, frameTimesDev, ...
        frameUtterNumsDev] = getXYfromTrackList(trackListDev, ...
        featureSpec);
    for i = 1:length(filenamesDev)
        saveFilename = append(dataDirectory, '\', filenamesDev(i), '.mat');
        save(saveFilename, filenamesDev(i));
    end
end

% TODO add code to normalize test test

%% drop neutral (or dissatisfied) frames in the train data to balance it
rng(20210419); % set seed for reproducibility

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

% normalize dev and test data using the same centering values and scaling 
% values used to normalize the train data
Xdev = normalize(Xdev, 'center', normalizeCenteringValues, ...
    'scale', normalizeScalingValues);

%% clear unnecessary variables
clear useTestSet useAllAnnotators
clear trackListTrain trackListDev trackListTest
clear idxNeutral idxDissatisfied numNeutral numDissatisfied
clear selections idxToDrop saveFilename dataDirectory
clear filenamesDev filenamesTrain
clear loadedAll i