% kNNdialogLevel.m

% add necessary files to path
addpath(genpath('calls'));
addpath(genpath('midlevel-master'));

dirWorking = append(pwd, "\");

% get feature spec (mono.fss)
featureSpec = getfeaturespec(append(dirWorking, "mono.fss"));

% get the track lists
trackListTrain = gettracklist(append(dirWorking, "dialog-level\train.tl"));
trackListDev = gettracklist(append(dirWorking, "dialog-level\dev.tl"));

% from call-log.xlsx, load the 'filename' and 'label' columns
opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', 'H2:I203', 'VariableNamesRange', 'H1:I1');
callTable = readtable('call-log.xlsx', opts); % TODO fix table format
%%
nFramesSkip = 10;
[monsterTrain, labelsTrain, trackListTrain] = getXY(trackListTrain, featureSpec, callTable, nFramesSkip);
[monsterDev, labelsDev, trackListDev] = getXY(trackListDev, featureSpec, callTable, nFramesSkip);

% train the model with X (monster) and Y (labels)
model = fitcknn(monsterTrain, labelsTrain);

k = 3;
model.NumNeighbors = k;

% predict on each of the dialogs in the dev set
for trackNum = 1:length(trackListDev)
    
    filename = trackListDev{1, trackNum}.filename;
    nFrames = trackListDev{1, trackNum}.nFrames;
    
    nFramesProcessed = 1;
    
    % for each frame, make a prediction
    startFrame = nFramesProcessed;
    endFrame = startFrame + nFrames;
    frames = monsterDev(startFrame:endFrame, :);
    labelsAsFloats = predict(model, frames);
     
    % the final prediction is the average label assigned to the frames
    predictionFloat = mean(labelsAsFloats);
    
    % store the float (predicted) by adding new field 'floatPredicted'
    trackListDev{1, trackNum}.floatPredicted = predictionFloat;
    
    threshold = 0.5;
    if predictionFloat <= threshold
        predictionLabel = 'doomed';
    else
        predictionLabel = 'successful';
    end
    
    % store the label (predicted) by adding new field 'labelPredicted'
    trackListDev{1, trackNum}.labelPredicted = predictionLabel;
    
    nFramesProcessed = nFramesProcessed + nFrames;

    % display predictions
    disp(filename)
    disp(['   ', num2str(predictionFloat), ' ', predictionLabel])
    
end
%%
% count tp, fp, fn, and tn
% positive class is 'successful', negative class is 'doomed'
tp = 0;
fp = 0;
fn = 0;
tn = 0;
for trackNum = 1:length(trackListDev)
    labelPredicted = trackListDev{1, trackNum}.labelPredicted;
    labelActual = trackListDev{1, trackNum}.labelActual;
    if strcmp(labelPredicted, 'successful')
        if strcmp(labelActual, 'successful')
            tp = tp + 1; % predicted as 'successful', actually 'sucessful'
        elseif strcmp(labelActual, 'doomed')
            fp = fp + 1; % predicted as 'successful', actually 'doomed'
        end
    elseif strcmp(labelPredicted, 'doomed')
        if strcmp(labelActual, 'successful')
            fn = fn + 1; % predicted as 'doomed', actually 'successful'
        elseif strcmp(labelActual, 'doomed')
            tn = tn + 1; % predicted as 'doomed', actually 'doomed'
        end
    end
end
total = tp + fp + fn + tn;
if total < length(trackListDev)
    error('(tp + fp + fn + tn) is less than the number of tracks')
end
%%
% calculate f score
precision = tp / (tp + fp);
recall = tp / (tp + fn);
beta = 1; % f1 if b=1
fScore = ((beta^2 + 1) * precision * recall) / (beta^2 * precision + recall);
disp(['F-score = ', num2str(fScore)]);
%%
% calculate mean absolute error
floatsActual = zeros([length(trackListDev), 1]);
floatsPredicted = zeros([length(trackListDev), 1]);
for trackNum = 1:length(trackListDev)
    floatsActual(trackNum) = trackListDev{1, trackNum}.floatActual;
    floatsPredicted(trackNum) = trackListDev{1, trackNum}.floatPredicted;
end
mae = sum(abs(floatsPredicted - floatsActual)) / length(trackListDev);
disp(['Mean Absolute Error = ', num2str(mae)]);

function [monster, labels, trackList] = getXY(trackList, featureSpec, callTable, nFramesSkip)

    monster = makeMultiTrackMonster(trackList, featureSpec);
    
    % keep only every nFramesSkip frame so that frames are further apart
    % if nFramesSkip=10, then frames are 100ms apart
    monster = monster(1:nFramesSkip:end, :);

    % for storing label of each frame in 'monster'
    labels = zeros([size(monster, 1), 1]);
    
    nFramesProcessed = 1;
    
    for trackNum = 1:length(trackList)  % for each track
        
        dialogFilename = trackList{1, trackNum}.filename;
        
        % calculate the duration in ms
        [audioData, sampleRate] = audioread(dialogFilename);
        durationMs = length(audioData) / sampleRate * 1000;
    
        % use the duration to approximate the number of frames, rounding down to closest 10 place
        FRAME_DURATION_MS = 10;
        nFramesFull = (durationMs - mod(durationMs, 10)) / FRAME_DURATION_MS;
        nFrames = round(nFramesFull / nFramesSkip); % adjust for skipped frames
        
        % store the number of frames to reference later by adding new field 'nFrames'
        trackList{1, trackNum}.nFrames = nFrames;
    
        % find the label for the dialog
        callTableMatching = callTable(strcmp(callTable.filename, {dialogFilename}), :);
        label = callTableMatching{1,'label'}{1};
        
        % if label is 'successful' label 1, else use 0
        if strcmp(label, 'successful')
            labelAsFloat = 1;
        elseif strcmp(label, 'doomed_1') || strcmp(label, 'doomed_2')
            labelAsFloat = 0;
        else
            error('unknown label in call table')
        end
        
        % store the label (actual) to reference later by adding new field 'labelActual'
        if strcmp(label, 'doomed_1') || strcmp(label, 'doomed_2')
            label = 'doomed';
        end
        trackList{1, trackNum}.labelActual = label;
        
        % store the float (actual) to reference later by adding new field
        % 'floatActual'
        trackList{1, trackNum}.floatActual = labelAsFloat;
        
        % fill in the portion of 'monster' with the label as float
        startFrame = nFramesProcessed;
        endFrame = startFrame + nFrames;
        labels(startFrame:endFrame) = labelAsFloat;
        
        nFramesProcessed = nFramesProcessed + nFrames;
    end
    
    % monster and labels do not always have the same length, but only for fraction of a second
    % this is because the code above is approximating the location of each
    % TODO re write this function to avoid this problem
    frameDifference = height(monster) - nFramesProcessed;
    disp(frameDifference);
    
    if (size(monster, 1) > size(labels, 1))
        monster = monster(1:size(labels, 1),:);
    else
        labels = labels(1:size(monster, 1),:);
    end
end
