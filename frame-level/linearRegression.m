% linearRegression.m Frame-level linear regression model

%% prepare the data
useTestSet = false;

trackListTrain = gettracklist('.\frame-level\train.tl');
trackListDev = gettracklist('.\frame-level\dev.tl');
trackListTest = gettracklist('.\frame-level\test.tl');

% Note: For results in the SIGDIAL paper, use mono.fss instead.
featureSpec = getfeaturespec('.\mono-extended.fss');

useAllAnnotators = false;

% [Xtrain, yTrain, frameTrackNumsTrain, frameTimesTrain, frameUtterancesTrain] = ...
%     getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
% [Xdev, yDev, frameTrackNumsDev, frameTimesDev, frameUtterancesDev] = ...
%     getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);
% [Xtest, yTest, frameTrackNumsTest, frameTimesTest, frameUtterancesTest] = ...
%     getXYfromTrackList(trackListTest, featureSpec, useAllAnnotators);
%% downsample neutral frames to balance neutral and dissatisfied frames

% drop from these five (5): frameTimesTrain, frameTrackNumsTrain,
% frameUtterancesTrain, Xtrain, and yTrain

% set seed
rng(2021);

flagsNeutral = yTrain == 0;
flagsDissatisfied = yTrain == 1;

idxNeutral = find(flagsNeutral);
idxDissatisfied = find(flagsDissatisfied);

numNeutral = length(idxNeutral);
numDissatisfied = length(idxDissatisfied);
numDifference = numNeutral - numDissatisfied;

selections = randsample(numNeutral, numDifference); % hardcoded (I know that there are more diss than neutral)


idxRemove = idxNeutral(selections);

frameTimesTrain(idxRemove) = [];
frameTrackNumsTrain(idxRemove) = [];
frameUtterancesTrain(idxRemove) = [];
Xtrain(idxRemove, :) = [];
yTrain(idxRemove) = [];
%%
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
%% normalize data

% normalize train data
[Xtrain, centeringValues, scalingValues] = normalize(Xtrain);

% normalize compare (dev or test) data using the same centering values 
% and scaling values used to perform the normalization of the train data
Xcompare = normalize(Xcompare, 'center', centeringValues, 'scale', scalingValues);

%% train regressor
model = fitlm(Xtrain, yTrain);

%% save coefficient info to a text file
outputFilename = append(pwd, '/frame-level/coefficients-extended.txt');
fileID = fopen(outputFilename, 'w');
coefficients = model.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf(fileID, 'Coefficients in descending order with format:\n');
fprintf(fileID, 'coefficient number, value, abbreviation\n');
for i = 1:length(coefficients)
    coeffNum = coeffSortedIdx(i);
    coeffValue = coefficientSorted(i);
    coeffAbbrev = featureSpec(coeffNum).abbrev;
    fprintf(fileID, '%2d | %f | %s\n', coeffNum, coeffValue, coeffAbbrev);
end
fclose(fileID);
fprintf('Coefficients saved to %s\\%s\n', pwd, outputFilename);

%%  predict on the compare set
yPred = predict(model, Xcompare);

% the baseline always predicts dissatisfied (positive class)
yBaseline = ones([size(Xcompare, 1), 1]);
%% print f1 score and more for different thresholds
thresholdMin = -0.25;
thresholdMax = 1.5;
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

%% print stats
mae = @(A, B) (mean(abs(A - B)));
fprintf('Regressor MAE = %f\n', mae(yCompare, yPred));
fprintf('Baseline MAE = %f\n\n', mae(yCompare, yBaseline));

mse = @(actual, pred) (mean((actual - pred) .^ 2));
fprintf('Regressor MSE = %f\n', model.MSE);
fprintf('Baseline MSE = %f\n\n', mse(yCompare, yBaseline));

fprintf('Regressor R-squared = %f\n', model.Rsquared.adjusted);
%% failure analysis

% config
clipSizesSeconds = [1 2];
numClipsToCreate = 20;
ignoreSizeSeconds = 2;
sortDirections = ["descend" "ascend"];

yDifference = abs(yCompare - yPred);

for sortDirNum = 1:size(sortDirections, 2)
    
    % sort yDifference following sort direction
    sortDirection = sortDirections(sortDirNum);    
    [~, sortIndex] = sort(yDifference, sortDirection);
    
    clipDir = sprintf('%s\\clips-extended-%s', pwd, sortDirection);
    [status, msg, msgID] = mkdir(clipDir);
    
    outputFilename = append(clipDir, '\output.txt');  % need to add rest of path
    fileID = fopen(outputFilename, 'w');
    
    fprintf(fileID, 'sortDirection=%s\n\n', sortDirection);

    framesToIgnore = zeros(size(yDifference));
    
    % create clips until numClipsCreated is reached or all frames have been
    % probed
    numClipsCreated = 0;
    for frameProbingNum = 1:length(sortIndex)
        
        if numClipsCreated >= numClipsToCreate
            break;
        end

        frameNumCompare = sortIndex(frameProbingNum);

        % ignore this frame if it has already been included in a clip
        if framesToIgnore(frameNumCompare)
            continue;
        end

        frameTime = frameTimesCompare(frameNumCompare);
        trackNum = frameTrackNumsCompare(frameNumCompare);
        track = trackListCompare{trackNum};
        [audioData, sampleRate] = audioread(track.filename);

        for clipSizeIdx = 1:length(clipSizesSeconds)
            clipSizeSeconds = clipSizesSeconds(clipSizeIdx);
            timeStart = frameTime - seconds(clipSizeSeconds/2);
            timeEnd = frameTime + seconds(clipSizeSeconds/2);
            idxStart = round(seconds(timeStart) * sampleRate);
            idxEnd = round(seconds(timeEnd) * sampleRate);
            newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, frameNumCompare, clipSizeSeconds);
            clipData = audioData(idxStart:idxEnd);
            audiowrite(newFilename, clipData, sampleRate);
        end

        fprintf(fileID, 'clip%d  timeSeconds=%.2f  filename=%s\n', ...
            frameNumCompare, seconds(frameTime), track.filename);
        fprintf(fileID, '\tpredicted=%.2f  actual=%.2f\n', yPred(frameNumCompare), yCompare(frameNumCompare));
        
        numClipsCreated = numClipsCreated + 1;

        % zero out the 
        % check if any other frame number is within this frame's utterance
        clipSizeFrames = seconds(ignoreSizeSeconds) / milliseconds(10); % monster frames are 10ms
        frameNumCompareStart = frameNumCompare - clipSizeFrames / 2;
        frameNumCompareEnd = frameNumCompare + clipSizeFrames / 2;
        
        % adjust compare start and compare end if out of bounds
        if frameNumCompareStart < 1
            frameNumCompareStart = 1;
        end
        if frameNumCompareEnd > length(yDifference)
            frameNumCompareEnd = length(yDifference);
        end

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
    
    fclose(fileID);
    fprintf('Output written to %s\n', outputFilename);
end