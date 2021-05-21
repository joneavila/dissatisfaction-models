% prepareData.m
% TODO add code to compute the test data
% TODO add code to normalize test test

featureSpec = getfeaturespec('.\source\mono.fss');

dataDir = append(pwd, '\data');
if ~exist(dataDir, 'dir')
    mkdir(dataDir)
end

%% load precomputed frame-level data if found, else compute it
disp('loading frame-level data');
tracklistTrainFrame = gettracklist('tracklists-frame\train.tl');
tracklistDevFrame = gettracklist('tracklists-frame\dev.tl');
tracklistTestFrame = gettracklist('tracklists-frame\test.tl');

% load precomupted train data, else compute it and save it for future runs
filenamesTrainFrame = ["timesTrainFrame" "trackNumsTrainFrame" ...
    "utterNumsTrainFrame" "XtrainFrame" "yTrainFrame"];
loadedAll = true;
for i = 1:length(filenamesTrainFrame)
    saveFilename = append(dataDir, '\', filenamesTrainFrame(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XtrainFrame, yTrainFrame, trackNumsTrainFrame, timesTrainFrame, ...
        utterNumsTrainFrame] = getXYfromTrackList(tracklistTrainFrame, ...
        featureSpec);
    for i = 1:length(filenamesTrainFrame)
        saveFilename = append(dataDir, '\', filenamesTrainFrame(i), '.mat');
        save(saveFilename, filenamesTrainFrame(i));
    end
end

% load the dev data, else compute it and save it for future runs
filenamesDevFrame = ["timesDevFrame" "trackNumsDevFrame" ...
    "utterNumsDevFrame" "XdevFrame" "yDevFrame"];
loadedAll = true;
for i = 1:length(filenamesDevFrame)
    saveFilename = append(dataDir, '\', filenamesDevFrame(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XdevFrame, yDevFrame, trackNumsDevFrame, timesDevFrame, ...
        utterNumsDevFrame] = getXYfromTrackList(tracklistDevFrame, ...
        featureSpec);
    for i = 1:length(filenamesDevFrame)
        saveFilename = append(dataDir, '\', filenamesDevFrame(i), '.mat');
        save(saveFilename, filenamesDevFrame(i));
    end
end

%% drop neutral (or dissatisfied) frames in the frame-level train data to balance it
rng(20210419); % set seed for reproducibility

idxNeutral = find(yTrainFrame == 0);
idxDissatisfied = find(yTrainFrame == 1);

numNeutral = length(idxNeutral);
numDissatisfied = length(idxDissatisfied);
numDifference = abs(numNeutral - numDissatisfied);

if numDifference
    if numNeutral > numDissatisfied
        idxToDrop = randsample(idxNeutral, numDifference);
    elseif numDissatisfied > numNeutral
        idxToDrop = randsample(numDissatisfied, numDifference);
    end
    timesTrainFrame(idxToDrop) = [];
    trackNumsTrainFrame(idxToDrop) = [];
    utterNumsTrainFrame(idxToDrop) = [];
    XtrainFrame(idxToDrop, :) = [];
    yTrainFrame(idxToDrop) = [];
end

%% normalize frame-level data

% normalize train data
[XtrainFrame, centeringValuesFrame, scalingValuesFrame] = ...
    normalize(XtrainFrame);

% normalize dev and test data using the same centering values and scaling 
% values used to normalize the train data
XdevFrame = normalize(XdevFrame, 'center', centeringValuesFrame, ...
    'scale', scalingValuesFrame);

%% load precomputed dialog-level train data if found, else compute it
disp('loading dialog-level data');
tracklistTrainDialog = gettracklist('tracklists-dialog\train.tl');
tracklistDevDialog = gettracklist('tracklists-dialog\dev.tl');

% load precomupted train data, else compute it and save it for future runs
filenamesTrainDialog = ["timesTrainDialog" "trackNumsTrainDialog" ...
    "utterNumsTrainDialog" "XtrainDialog" "yTrainDialog"];
loadedAll = true;
for i = 1:length(filenamesTrainDialog)
    saveFilename = append(dataDir, '\', filenamesTrainDialog(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XtrainDialog, yTrainDialog, trackNumsTrainDialog, timesTrainDialog, ...
        utterNumsTrainDialog] = getXYfromTrackList(tracklistTrainDialog, ...
        featureSpec);
    for i = 1:length(filenamesTrainDialog)
        saveFilename = append(dataDir, '\', filenamesTrainDialog(i), '.mat');
        save(saveFilename, filenamesTrainDialog(i));
    end
end

% % load precomupted dev data, else compute it and save it for future runs
% filenamesDevDialog = ["timesDevDialog" "trackNumsDevDialog" ...
%     "utterNumsDevDialog" "XdevDialog" "yDevDialog"];
% loadedAll = true;
% for i = 1:length(filenamesDevDialog)
%     saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
%     try
%         load(saveFilename);
%     catch
%         loadedAll = false;
%         break
%     end
% end
% if ~loadedAll
%     [XdevDialog, yDevDialog, trackNumsDevDialog, timesDevDialog, ...
%         utterNumsDevDialog] = getXYfromTrackList(tracklistDevDialog, ...
%         featureSpec);
%     for i = 1:length(filenamesDevDialog)
%         saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
%         save(saveFilename, filenamesDevDialog(i));
%     end
% end

%% normalize dialog-level data
% just to get the centering values and scaling values

% normalize train data
[XtrainDialog, centeringValuesDialog, scalingValuesDialog] = ...
    normalize(XtrainDialog);

%% clear unnecessary variables
clear dataDir
clear filenamesDevFrame filenamesTrainDialog filenamesTrainFrame
clear i idxDissatisfied idxNeutral idxToDrop
clear loadedAll
clear numDifference numDissatisfied numNeutral
clear saveFilename