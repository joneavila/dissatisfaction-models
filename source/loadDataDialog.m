% prepareDataDialog.m

dataDir = append(pwd, '/data/dialog-level');

featureSpec = getfeaturespec('./source/mono-old.fss');

tracklistTrainDialog = gettracklist('tracklists-dialog/train.tl');
tracklistDevDialog = gettracklist('tracklists-dialog/dev.tl');
tracklistTestDialog = gettracklist('tracklists-dialog/test.tl');

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
    %% compute train data
    [XtrainDialog, yTrainDialog, trackNumsTrainDialog, ...
        utterNumsTrainDialog] = getXYfromTrackList(tracklistTrainDialog, ...
        featureSpec);
    save(append(dataDir, '/train.mat'), 'XtrainDialog', 'yTrainDialog', ...
        'trackNumsTrainDialog', 'utterNumsTrainDialog');

%     % compute dev data
%     
%     [XdevDialog, yDevDialog, trackNumsDevDialog, ...
%         utterNumsDevDialog] = getXYfromTrackList(tracklistDevDialog, ...
%         featureSpec);
%     
%     % save dev data
%     save(append(dataDir, '/test.mat'), 'XdevDialog', ...
%         'yDevDialog', 'trackNumsDevDialog', ...
%         'utterNumsDevDialog');

    %% compute test data
    [XtestDialog, yTestDialog, trackNumsTestDialog, ...
        utterNumsTestDialog] = getXYfromTrackList(tracklistTestDialog, ...
        featureSpec);
    save(append(dataDir, '/test.mat'), 'XtestDialog', 'yTestDialog', ...
        'trackNumsTestDialog', 'utterNumsTestDialog');

    %% normalize train data
    % to get the centering values and scaling values for later
    [XtrainDialog, centeringValuesDialog, scalingValuesDialog] = ...
        normalize(XtrainDialog); 
    
    %% compute monsters
    % computeMonsters(tracklistTrainDialog, centeringValuesDialog, ...
    %     scalingValuesDialog, featureSpec, dataDir);
    % computeMonsters(tracklistDevDialog);
    computeMonsters(tracklistTestDialog, centeringValuesDialog, ...
        scalingValuesDialog, featureSpec, dataDir);
    
end

function computeMonsters(tracklist, normalizeCenteringValues, ...
    normalizeScalingValues, featureSpec, dataDir)
    numTracks = length(tracklist);
    for trackNum = 1:numTracks
        
        track = tracklist{trackNum};
        fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
        customerSide = 'l';
        trackSpec = makeTrackspec(customerSide, track.filename, './calls/');
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        
        % add time feature
        % TODO avoid call to frameNumToTime
        matchingTimes = [1:1:size(monster,1)]';
        matchingTimes = arrayfun(@(frameNum) ...
            frameNumToTime(frameNum), matchingTimes);
        monster(:,end+1) = seconds(matchingTimes);
        
        % normalize using centering values and scaling values
        % from normalizing train data
        monster = normalize(monster, 'center', ...
            normalizeCenteringValues, 'scale', normalizeScalingValues);
    
        [~, name, ~] = fileparts(track.filename);
        saveFilename = append(dataDir, '/', name, '.mat');
        
        save(saveFilename, 'monster');

    end   
end

%% clear unnecessary variables
% clear dataDir
% clear filenamesDevFrame filenamesTrainDialog filenamesTrainFrame
% clear i idxDissatisfied idxNeutral idxToDrop
% clear loadedAll
% clear numDifference numDissatisfied numNeutral
% clear saveFilename