% prepareDataFrame.m

dataDir = append(pwd, '/data/frame-level');

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
        load(files(i).name)
    end
else
    featureSpec = getfeaturespec('./source/mono.fss');
    
    % compute train data
    tracklistTrainFrame = gettracklist('tracklists-frame/train.tl');
    [XtrainFrame, yTrainFrame, trackNumsTrainFrame, ...
        utterNumsTrainFrame] = getXYfromTrackList(tracklistTrainFrame, ...
        featureSpec);
    
    % compute dev data
    tracklistDevFrame = gettracklist('tracklists-frame/dev.tl');
    [XdevFrame, yDevFrame, trackNumsDevFrame, ...
        utterNumsDevFrame] = getXYfromTrackList(tracklistDevFrame, ...
        featureSpec);

    % compute test data
    tracklistTestFrame = gettracklist('tracklists-frame/test.tl');
    [XtestFrame, yTestFrame, trackNumsTestFrame, ...
        utterNumsTestFrame] = getXYfromTrackList(tracklistTestFrame, ...
        featureSpec);

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
        'utterNumsTrainFrame');
    save(append(dataDir, '/dev.mat'), 'XdevFrame', ...
        'yDevFrame', 'trackNumsDevFrame', ...
        'utterNumsDevFrame');
    save(append(dataDir, '/test.mat'), 'XtestFrame', ...
        'yTestFrame', 'trackNumsTestFrame', ...
        'utterNumsTestFrame');
end

% clear unnecessary variables here