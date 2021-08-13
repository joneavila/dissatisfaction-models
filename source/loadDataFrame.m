% prepareDataFrame.m
% Loads data for frame-level models.

dataDir = append(pwd, '/data/frame-level');

featureSpec = getfeaturespec('./source/mono.fss');

tracklistTrainFrame = gettracklist('tracklists-frame/train.tl');
tracklistDevFrame = gettracklist('tracklists-frame/dev.tl');
tracklistTestFrame = gettracklist('tracklists-frame/test.tl');

% create the data directory if it doesn't exist
if ~exist(dataDir, 'dir')
    mkdir(dataDir) 
end

% count the number of .mat files in the data directory
files = dir(append(dataDir, '/*.mat'));
numFiles = size(files, 1);

% load all .mat files if any are found, else recompute all data and save
% them for future runs 
if numFiles
    for i = 1:numFiles
        load(append(dataDir, '/', files(i).name))
    end
else
    
    % compute train data
    [XtrainFrame, yTrainFrame, trackNumsTrainFrame, ...
        utterNumsTrainFrame, frameTimesTrainFrame] = ...
        getXYfromTrackList(tracklistTrainFrame, featureSpec);
    
    % compute dev data
    [XdevFrame, yDevFrame, trackNumsDevFrame, ...
        utterNumsDevFrame, frameTimesDevFrame] = ...
        getXYfromTrackList(tracklistDevFrame, featureSpec);

    % compute test data
    [XtestFrame, yTestFrame, trackNumsTestFrame, ...
        utterNumsTestFrame, frameTimesTestFrame] = ...
        getXYfromTrackList(tracklistTestFrame, featureSpec);

    %% balance train data
    rng(20210419); % set seed for reproducibility

    idxNeutral = find(yTrainFrame == 0); % assume 0 for neutral
    idxDissatisfied = find(yTrainFrame == 1); % assume 1 for dissatisfied

    numNeutral = length(idxNeutral);
    numDissatisfied = length(idxDissatisfied);
    numDifference = abs(numNeutral - numDissatisfied);

    if numDifference
        if numNeutral > numDissatisfied
            idxToDrop = randsample(idxNeutral, numDifference);
        elseif numDissatisfied > numNeutral
            idxToDrop = randsample(numDissatisfied, numDifference);
        end
        trackNumsTrainFrame(idxToDrop) = [];
        utterNumsTrainFrame(idxToDrop) = [];
        XtrainFrame(idxToDrop, :) = [];
        yTrainFrame(idxToDrop) = [];
    end

    %% normalize
    % normalize training data
    [XtrainFrame, centeringValuesFrame, scalingValuesFrame] = ...
        normalize(XtrainFrame);

    % normalize dev and test data using the same centering values and scaling 
    % values used to normalize the train data
    XdevFrame = normalize(XdevFrame, 'center', centeringValuesFrame, ...
        'scale', scalingValuesFrame);
    XtestFrame = normalize(XtestFrame, 'center', centeringValuesFrame, ...
        'scale', scalingValuesFrame);

    %% save variables
    save(append(dataDir, '/train.mat'), 'XtrainFrame', ...
        'yTrainFrame', 'trackNumsTrainFrame', ...
        'utterNumsTrainFrame', 'frameTimesTrainFrame');
    save(append(dataDir, '/dev.mat'), 'XdevFrame', ...
        'yDevFrame', 'trackNumsDevFrame', ...
        'utterNumsDevFrame', 'frameTimesDevFrame');
    save(append(dataDir, '/test.mat'), 'XtestFrame', ...
        'yTestFrame', 'trackNumsTestFrame', ...
        'utterNumsTestFrame', 'frameTimesTestFrame');
end

% clear unnecessary variables here