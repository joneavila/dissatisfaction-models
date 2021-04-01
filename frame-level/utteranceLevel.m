% utteranceLevel.m 
% Predict utterances using linear regressor's frame-level predictions. For 
% each utterance in the compare set, this model predicts the mean of the 
% predictions on the frames in that utterance. The baseline predicts the 
% most common annotation for all frames in the train set.

%% prepare the data 
useTestSet = true;

trackListTrain = gettracklist('.\frame-level\train.tl');
trackListDev = gettracklist('.\frame-level\dev.tl');
trackListTest = gettracklist('.\frame-level\test.tl');

featureSpec = getfeaturespec('.\mono.fss');

useAllAnnotators = false;

% [Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, frameUtterancesTrain] = ...
%     getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
% [Xdev, yDev, frameTrackNumsDev, frameTimesDev, frameUtterancesDev] = ...
%     getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);
% [Xtest, yTest, frameTrackNumsTest, frameTimesTest, frameUtterancesTest] = ...
%     getXYfromTrackList(trackListTest, featureSpec, useAllAnnotators);

if useTestSet
    Xcompare = Xtest;
    yCompare = yTest;
    frameTrackNumsCompare = frameTrackNumsTest;
    frameTimesCompare = frameTimesTest;
    frameUtterancesCompare = frameUtterancesTest;
    trackListCompare = trackListTest;
else
    Xcompare = Xdev;
    yCompare = yDev;
    frameTrackNumsCompare = frameTrackNumsDev;
    frameTimesCompare = frameTimesDev;
    frameUtterancesCompare = frameUtterancesDev;
    trackListCompare = trackListDev;
end

%% train
model = fitlm(Xtrain, yTrain);

%% predict on each utterance in the compare set
yPred = [];
yActual = [];

nTracks = size(trackListCompare, 2);
for trackNum = 1:nTracks
    
    track = trackListCompare{trackNum};
    fprintf("predicting on %s\n", track.filename)
    
    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(track.filename);
    annotationFilename = append(name, ".txt");
    
    % get the annotation table set up (just using one annotator here)
    annotationPathRelative = append('annotations\ja-annotations\', annotationFilename);
    annotationTable = readElanAnnotation(annotationPathRelative, true);
    
    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, track.directory);
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    % for each utterance (row in annotation table) let the regressor 
    % predict on each frame of the utterance then make the average of 
    % those predictions the final prediction
    nUtterances = size(annotationTable, 1);
    utterancePred = zeros([nUtterances 1]);
    for rowNum = 1:nUtterances
        row = annotationTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        utterance = monster(frameStart:frameEnd, :);
        utterancePredictions = predict(model, utterance);
        utterancePred(rowNum) = mean(utterancePredictions);
    end
    
    utteranceActual = arrayfun(@labelToFloat, annotationTable.label);
    
    % display utterance info in a table
    disp(table(utterancePred, utteranceActual));

    % appending is ugly but isn't too slow here
    yPred = [yPred; utterancePred];
    yActual = [yActual; utteranceActual];
    
end
%% baseline
% this baseline always predicts 1 for perfectly dissatisfied and should be
% compared with using precision
yBaseline = ones(size(yActual));
%% print f1 score and more for different thresholds
thresholdMin = -0.25;
thresholdMax = 1.1;
thresholdStep = 0.05;

fprintf('min(yPred)=%.3f, max(yPred)=%.3f\n', min(yPred), max(yPred));
fprintf('thresholdMin=%.2f, thresholdMax=%.2f, thresholdStep=%.2f\n', ...
    thresholdMin, thresholdMax, thresholdStep);

thresholdCompare = 0.5;
yActualLabel = arrayfun(@(x) floatToLabel(x, thresholdCompare), yActual, ...
    'UniformOutput', false);

nSteps = (thresholdMax - thresholdMin) / thresholdStep;
threshold = zeros([nSteps 1]);
precisionUtterance = zeros([nSteps 1]);
precisionBaseline = zeros([nSteps 1]);
recallUtterance = zeros([nSteps 1]);
recallBaseline = zeros([nSteps 1]);
scoreUtterance = zeros([nSteps 1]);
scoreBaseline = zeros([nSteps 1]);

thresholdSel = thresholdMin;
for i = 1:nSteps
    thresholdSel = round(thresholdSel, 2);
    yPredLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), yPred, ...
        'UniformOutput', false);
    yBaselineLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), ...
        yBaseline, 'UniformOutput', false);
    [scoLinear, precLinear, recLinear] = fScore(yActualLabel, ...
        yPredLabel, 'doomed', 'successful');
    [scoBaseline, precBaseline, recBaseline] = fScore(yActualLabel, ...
        yBaselineLabel, 'doomed', 'successful');
    threshold(i) = thresholdSel;
    precisionUtterance(i) = precLinear;
    precisionBaseline(i) = precBaseline;
    
    recallUtterance(i) = recLinear;
    recallBaseline(i) = recBaseline;
    
    scoreUtterance(i) = scoLinear;
    scoreBaseline(i) = scoBaseline;
    
    thresholdSel = thresholdSel + thresholdStep;
end
disp(table(threshold, precisionUtterance, precisionBaseline, recallUtterance, ...
    recallBaseline, scoreUtterance, scoreBaseline));
%%
% mae = @(A, B) (mean(abs(A - B)));
% disp('Utterance-level:');
% fprintf('Utterance MAE = %f\n', mae(yUtteranceActual, yUtterancePred));
% fprintf('Baseline MAE = %f\n', mae(yUtteranceActual, yUtteranceBaseline));