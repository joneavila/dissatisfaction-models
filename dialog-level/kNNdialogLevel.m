% kNNdialogLevel.m Dialog-level k-nearest neighbor model

featureSpec = getfeaturespec("mono.fss");

trackListTrain = gettracklist(".\dialog-level\train.tl");
trackListDev = gettracklist(".\dialog-level\dev.tl");

[Xtrain, yTrain, trackListTrain] = getXY(trackListTrain, featureSpec);
[Xdev, yDev, trackListDev] = getXY(trackListDev, featureSpec);

% train the model with X (monster) and Y (labels)
model = fitcknn(Xtrain, yTrain);

% predict on each of the dialogs in the dev set, use default k
nFramesProcessed = 0;
nTracks = size(trackListDev, 2);
yPred = zeros([nTracks, 1]);
yActual = zeros([nTracks, 1]);
for trackNum = 1:nTracks
    
    track = trackListDev{1, trackNum};
    fprintf('Predicting on %s\n', track.filename);
    
    % for each frame, make a prediction
    startFrame = nFramesProcessed + 1;
    endFrame = startFrame + track.nFrames - 1;
    dialogFrames = Xdev(startFrame:endFrame, :);
    
    % the final prediction is the average label assigned to the frames
    dialogPred = predict(model, dialogFrames);
    yPred(trackNum) = mean(dialogPred);
    
    yActual(trackNum) = yDev(startFrame);
    
    nFramesProcessed = nFramesProcessed + track.nFrames;
end

% calculate mean absolute error
mae = mean(abs(yPred - yActual));
fprintf('Mean Absolute Error = %f\n', mae);

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

function labelString = floatToString(labelFloat)
    threshold = 0.5;
    if (labelFloat < threshold)
        labelString = 'successful';
    else
        labelString = 'doomed';
    end
end