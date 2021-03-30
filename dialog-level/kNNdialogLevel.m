% kNNdialogLevel.m Dialog-level k-nearest neighbor model

featureSpec = getfeaturespec('.\mono.fss');
trackListTrain = gettracklist('.\dialog-level\train.tl');
trackListDev = gettracklist('.\dialog-level\dev.tl');

[Xtrain, yTrain, trackListTrain] = getXY(trackListTrain, featureSpec);
[Xdev, yDev, trackListDev] = getXY(trackListDev, featureSpec);
%%
% train the model with X (monster) and Y (labels)
model = fitcknn(Xtrain, yTrain, 'NumNeighbors', 5);
%%
% predict on each of the dialogs in the dev set
% the final prediction is the average label assigned to the frames
nTracks = size(trackListDev, 2);
yPred = zeros([nTracks, 1]);
yActual = zeros([nTracks, 1]);
nFramesProcessed = 0;
for trackNum = 1:nTracks  
    track = trackListDev{trackNum};
    fprintf('[%d/%d] Predicting on %s\n', trackNum, nTracks, track.filename);
    
    startFrame = nFramesProcessed + 1;
    endFrame = startFrame + track.nFrames - 1;
    Xdialog = Xdev(startFrame:endFrame, :);
    
    yPred(trackNum) = mean(predict(model, Xdialog));
    yActual(trackNum) = yDev(startFrame);
    
    nFramesProcessed = nFramesProcessed + track.nFrames;
end
%%
% calculate mean absolute error
mae = mean(abs(yPred - yActual));
fprintf('k-NN MAE = %f\n', mae);

% calculate f-score
yActualLabels = arrayfun(@floatToString, yActual, 'UniformOutput', false);
yPredLabels = arrayfun(@floatToString, yPred, 'UniformOutput', false);
score = fScore(yActualLabels, yPredLabels, 'doomed', 'successful');
fprintf('F-score = %f\n', score);

% display results in a table
trackListDevStruct = [trackListDev{:,:}];
filenames = {trackListDevStruct(:).filename};
resultsTable = table(filenames', yPred, yPredLabels, yActual, yActualLabels);
resultsTable.Properties.VariableNames = ...
    ["filename", "yPred", "yPredLabel", "yActual", "yActualLabel"];
display(resultsTable);

%% baseline
yBaseline = zeros([nTracks, 1]);

mae = mean(abs(yBaseline - yActual));
fprintf('Baseline MAE = %f\n', mae);

yBaselineLabels = arrayfun(@floatToString, yBaseline, 'UniformOutput', false);
score = fScore(yActualLabels, yBaselineLabels, 'doomed', 'successful');
fprintf('F-score = %f\n', score);

function [X, y, trackListExtended] = getXY(trackList, featureSpec)
% X is just monster. y is label for each frame (same label for each frame
% in a dialog).

    X = [];
    y = [];
    trackListExtended = trackList;    
      
    % from call-log.xlsx, load the 'filename' and 'label' columns
    opts = spreadsheetImportOptions('NumVariables', 2, ...
        'DataRange', 'H2:I203', 'VariableNamesRange', 'H1:I1');
    callTable = readtable('call-log.xlsx', opts);

    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        fprintf('[%d/%d] %s\n', trackNum, nTracks, track.filename);
        
        % get the monster
        customerSide = 'l';
        trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
        [~, Xdialog] = makeTrackMonster(trackSpec, featureSpec);
        
        % keep only every nFramesSkip frame so that frames are further apart
        % if nFramesSkip=10, then frames are 100ms apart
        nFramesSkip = 10;
        Xdialog = Xdialog(1:nFramesSkip:end, :);
        
        % store the number of frames to reference later by adding new field 'nFrames'
        track.nFrames = size(Xdialog, 1);
    
        matchingIdx = strcmp(callTable.filename, track.filename);
        label = callTable(matchingIdx, :).label{1};
        
        if strcmp(label, 'successful')
            track.labelActual = 'successful';
            track.floatActual = 0;
        elseif strcmp(label, 'doomed_1') || strcmp(label, 'doomed_2')
            track.labelActual = 'doomed';
            track.floatActual = 1;
        else
            error('unknown label in call table')
        end

        yDialog = ones(size(Xdialog, 1), 1) * track.floatActual;
        
        X = [X; Xdialog];
        y = [y; yDialog];
        
        trackListExtended(trackNum) = {track};
       
    end

end

function labelString = floatToString(labelFloat)
    threshold = 0.5;
    if (labelFloat < threshold)
        labelString = 'successful';
    else
        labelString = 'doomed';
    end
end