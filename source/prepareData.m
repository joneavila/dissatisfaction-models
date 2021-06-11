% prepareData.m
%% config
useTimeFeature = true; %#ok<*UNRCH>

%% load feature spec
featureSpec = getfeaturespec('.\source\mono.fss');

% add the time feature to the feature specficiation (for the rest of the
% code to work smoothly)
if useTimeFeature
    timeFeatureNum = length(featureSpec) + 1;
    timeFeature.featname = 'tid';
    timeFeature.startms = 0;
    timeFeature.endms = 0;
    timeFeature.duration = 0;
    timeFeature.side = 'self';
    timeFeature.plotcolor = 0;
    timeFeature.abbrev = 'time into dialog';
    featureSpec(timeFeatureNum) = timeFeature;
end

%% load precomputed frame-level data if found, else compute it
if useTimeFeature
    dataDir = append(pwd, '\data\frame-with-time'); 
else
    dataDir = append(pwd, '\data\frame-without-time');
end
if ~exist(dataDir, 'dir')
    mkdir(dataDir)
end

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
    
    if useTimeFeature
        % include timesTrainFrame as a feature
        XtrainFrame(:, timeFeatureNum) = seconds(timesTrainFrame);
    end
    
    
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
    
    if useTimeFeature
        % include timesDevFrame as a feature
        XdevFrame(:, timeFeatureNum) = seconds(timesDevFrame);
    end
    
    for i = 1:length(filenamesDevFrame)
        saveFilename = append(dataDir, '\', filenamesDevFrame(i), '.mat');
        save(saveFilename, filenamesDevFrame(i));
    end
end

% load the test data, else compute it and save it for future runs
filenamesTestFrame = ["timesTestFrame" "trackNumsTestFrame" ...
    "utterNumsTestFrame" "XtestFrame" "yTestFrame"];
loadedAll = true;
for i = 1:length(filenamesTestFrame)
    saveFilename = append(dataDir, '\', filenamesTestFrame(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XtestFrame, yTestFrame, trackNumsTestFrame, timesTestFrame, ...
        utterNumsTestFrame] = getXYfromTrackList(tracklistTestFrame, ...
        featureSpec);
    
    if useTimeFeature
        % include timesTestFrame as a feature
        XtestFrame(:, timeFeatureNum) = seconds(timesTestFrame);
    end
    
    for i = 1:length(filenamesTestFrame)
        saveFilename = append(dataDir, '\', filenamesTestFrame(i), '.mat');
        save(saveFilename, filenamesTestFrame(i));
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
XtestFrame = normalize(XtestFrame, 'center', centeringValuesFrame, ...
    'scale', scalingValuesFrame);

%% load precomputed dialog-level train data if found, else compute it
disp('loading dialog-level data');
tracklistTrainDialog = gettracklist('tracklists-dialog\train.tl');
tracklistDevDialog = gettracklist('tracklists-dialog\dev.tl');
tracklistTestDialog = gettracklist('tracklists-dialog\test.tl');

if useTimeFeature
    dataDir = append(pwd, '\data\dialog-with-time'); 
else
    dataDir = append(pwd, '\data\dialog-without-time');
end
if ~exist(dataDir, 'dir')
    mkdir(dataDir)
end

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
    
    if useTimeFeature
        % include timesDevFrame as a feature
        XtrainDialog(:, timeFeatureNum) = seconds(timesTrainDialog);
    end
    
    for i = 1:length(filenamesTrainDialog)
        saveFilename = append(dataDir, '\', filenamesTrainDialog(i), '.mat');
        save(saveFilename, filenamesTrainDialog(i));
    end
end

% load precomupted dev data, else compute it and save it for future runs
filenamesDevDialog = ["timesDevDialog" "trackNumsDevDialog" ...
    "utterNumsDevDialog" "XdevDialog" "yDevDialog"];
loadedAll = true;
for i = 1:length(filenamesDevDialog)
    saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XdevDialog, yDevDialog, trackNumsDevDialog, timesDevDialog, ...
        utterNumsDevDialog] = getXYfromTrackList(tracklistDevDialog, ...
        featureSpec);
    
    if useTimeFeature
        % include timesDevFrame as a feature
        XdevDialog(:, timeFeatureNum) = seconds(timesDevDialog);
    end
    
    for i = 1:length(filenamesDevDialog)
        saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
        save(saveFilename, filenamesDevDialog(i));
    end
end

% load precomupted test data, else compute it and save it for future runs
filenamesTestDialog = ["timesTestDialog" "trackNumsTestDialog" ...
    "utterNumsTestDialog" "XtestDialog" "yTestDialog"];
loadedAll = true;
for i = 1:length(filenamesTestDialog)
    saveFilename = append(dataDir, '\', filenamesTestDialog(i), '.mat');
    try
        load(saveFilename);
    catch
        loadedAll = false;
        break
    end
end
if ~loadedAll
    [XtestDialog, yTestDialog, trackNumsTestDialog, timesTestDialog, ...
        utterNumsTestDialog] = getXYfromTrackList(tracklistTestDialog, ...
        featureSpec);
    
    if useTimeFeature
        % include timesTestFrame as a feature
        XtestDialog(:, timeFeatureNum) = seconds(timesTestDialog);
    end
    
    for i = 1:length(filenamesTestDialog)
        saveFilename = append(dataDir, '\', filenamesTestDialog(i), '.mat');
        save(saveFilename, filenamesTestDialog(i));
    end
end

if useTimeFeature
    dataDir = append(pwd, '\data\monsters-with-time'); 
else
    dataDir = append(pwd, '\data\monsters-without-time');
end
if ~exist(dataDir, 'dir')
    mkdir(dataDir)
end

%  load precomupted dialog-level train data, else compute it and save it for future runs
numTracks = length(tracklistTrainDialog);
for trackNum = 1:numTracks
    track = tracklistTrainDialog{trackNum};
    fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
    [~, name, ~] = fileparts(track.filename);
    saveFilename = append(dataDir, '\', name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        if useTimeFeature
            matchingTimes = [1:1:size(monster,1)]';
            matchingTimes = arrayfun(@(frameNum) ...
                frameNumToTime(frameNum), matchingTimes);
            monster = [monster seconds(matchingTimes)];
        end
        save(saveFilename, 'monster');
    end
end    

% load precomupted dialog-level test data, else compute it and save it for future runs
tracklistTestDialog = gettracklist('tracklists-dialog\test.tl');
numTracks = length(tracklistTestDialog);
for trackNum = 1:numTracks
    track = tracklistTestDialog{trackNum};
    fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
    [~, name, ~] = fileparts(track.filename);
    saveFilename = append(dataDir, '\', name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        if useTimeFeature
            matchingTimes = [1:1:size(monster,1)]';
            matchingTimes = arrayfun(@(frameNum) ...
                frameNumToTime(frameNum), matchingTimes);
            monster = [monster seconds(matchingTimes)];
        end
        save(saveFilename, 'monster');
    end
end    

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