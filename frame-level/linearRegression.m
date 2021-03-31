% linearRegression.m Frame-level linear regression model

%% prepare the data
useTestSet = false;

trackListTrain = gettracklist('.\frame-level\train.tl');
trackListDev = gettracklist('.\frame-level\dev.tl');
trackListTest = gettracklist('.\frame-level\test.tl');

featureSpec = getfeaturespec('.\mono-simple.fss');

useAllAnnotators = false;

[Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, frameUtterancesTrain] = ...
    getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
[Xdev, yDev, frameTrackNumsDev, frameTimesDev, frameUtterancesDev] = ...
    getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);
[Xtest, yTest, frameTrackNumsTest, frameTimesTest, frameUtterancesTest] = ...
    getXYfromTrackList(trackListTest, featureSpec, useAllAnnotators);

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
%% train regressor
model = fitlm(Xtrain, yTrain);

%% save coefficient info to a text file
outputFilename = 'coefficients.txt';
fileID = fopen(outputFilename, 'w');
coefficients = model.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf(fileID, 'Coefficients in descending order with format:\n');
fprintf(fileID, 'coefficient, value, abbreviation\n');
for coeffNum = 1:length(coefficients)
    coeff = coeffSortedIdx(coeffNum);
    coeffValue = coefficientSorted(coeffNum);
    fprintf(fileID, '%2d | %f | %s\n', coeff, coeffValue, ...
        featureSpec(coeff).abbrev);
end
fclose(fileID);
fprintf('Coefficients saved to %s\\%s\n', pwd, outputFilename);

%%  predict on the compare set
yPred = predict(model, Xcompare);

% the baseline always predicts dissatisfied (positive class)
yBaseline = ones([size(Xcompare, 1), 1]);
%% print f1 score and more for different thresholds
thresholdMin = -0.25;
thresholdMax = 1.1;
thresholdStep = 0.05;

fprintf('min(yPred)=%.3f, max(yPred)=%.3f\n', min(yPred), max(yPred));
fprintf('thresholdMin=%.2f, thresholdMax=%.2f, thresholdStep=%.2f\n', ...
    thresholdMin, thresholdMax, thresholdStep);

thresholdCompare = 0.5;
yCompareLabel = arrayfun(@(x) floatToLabel(x, thresholdCompare), yCompare, ...
    'UniformOutput', false);

nSteps = (thresholdMax - thresholdMin) / thresholdStep;
threshold = zeros([nSteps 1]);
precisionLinear = zeros([nSteps 1]);
precisionBaseline = zeros([nSteps 1]);
recallLinear = zeros([nSteps 1]);
recallBaseline = zeros([nSteps 1]);
scoreLinear = zeros([nSteps 1]);
scoreBaseline = zeros([nSteps 1]);

thresholdSel = thresholdMin;
for i = 1:nSteps
    thresholdSel = round(thresholdSel, 2);
    yPredLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), yPred, ...
        'UniformOutput', false);
    yBaselineLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), ...
        yBaseline, 'UniformOutput', false);
    [scoLinear, precLinear, recLinear] = fScore(yCompareLabel, ...
        yPredLabel, 'doomed', 'successful');
    [scoBaseline, precBaseline, recBaseline] = fScore(yCompareLabel, ...
        yBaselineLabel, 'doomed', 'successful');
    threshold(i) = thresholdSel;
    precisionLinear(i) = precLinear;
    precisionBaseline(i) = precBaseline;
    
    recallLinear(i) = recLinear;
    recallBaseline(i) = recBaseline;
    
    scoreLinear(i) = scoLinear;
    scoreBaseline(i) = scoBaseline;
    
    
    thresholdSel = thresholdSel + thresholdStep;
end
disp(table(threshold, precisionLinear, precisionBaseline, recallLinear, ...
    recallBaseline, scoreLinear, scoreBaseline));
%% failure analysis

% config
clipSizesSeconds = [1 2];
numFramesToProbe = 500;

yDifference = abs(yCompare - yPred);
[yDifferenceSorted, sortIndex] = sort(yDifference, 'descend');

clipDir = sprintf('%s\\clips', pwd);
[status, msg, msgID] = mkdir(clipDir);

framesToIgnore = zeros(size(yDifference));

for i = 1:numFramesToProbe
    
    frameNumCompare = sortIndex(i);
    
    % ignore this frame if it has already been included in a clip
    if framesToIgnore(frameNumCompare)
        continue;
    end
    
    frameTime = frameTimesCompare(frameNumCompare);
    trackNum = frameTrackNumsCompare(frameNumCompare);
    track = trackListCompare{trackNum};
    [audioData, sampleRate] = audioread(track.filename);
    
    for j = 1:length(clipSizesSeconds)
        clipSizeSeconds = clipSizesSeconds(j);
        timeStart = frameTime - seconds(clipSizeSeconds/2);
        timeEnd = frameTime + seconds(clipSizeSeconds/2);
        idxStart = round(seconds(timeStart) * sampleRate);
        idxEnd = round(seconds(timeEnd) * sampleRate);
        newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, i, j);
        clipData = audioData(idxStart:idxEnd);
        audiowrite(newFilename, clipData, sampleRate);
    end
    
    fprintf('clip%d | time=%s | trackFilename=%s\n', ...
        i, char(frameTime), track.filename);
    
    % zero out the 
    % check if any other frame number is within this frame's utterance
    ignoreSizeSeconds = 1;
    clipSizeFrames = seconds(ignoreSizeSeconds) / milliseconds(10); % monster frames are 10ms
    frameNumCompareStart = frameNumCompare - clipSizeFrames / 2;
    frameNumCompareEnd = frameNumCompare + clipSizeFrames / 2;
    
    for frameNumProbe = frameNumCompareStart:frameNumCompareEnd
        % check if this frame is in the same track as the original
        if frameTrackNumsCompare(frameNumProbe) ~= frameTrackNumsCompare(frameNumCompare)
            continue;
        end
        
        % check if this frame is in the same utterance as the original
        if frameUtterancesCompare(frameNumProbe) ~= frameUtterancesCompare(frameNumCompare)
            continue;
        end
        
        % if both are true, mark the frame to zero it out
        framesToIgnore(frameNumProbe) = 1;
    end

end

%%
% mae = @(A, B) (mean(abs(A - B)));
% fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
% fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));