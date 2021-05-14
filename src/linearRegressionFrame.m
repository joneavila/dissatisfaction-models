% linearRegressionFrame.m Frame-level linear regression model

%% train regressor
prepareData;
linearRegressor = fitlm(Xtrain, yTrain);

%% save the model to use in the dialog-level model later
modelFilename = 'linearRegressor.mat';
save(modelFilename, 'linearRegressor');
fprintf('Saved trained linear regressor as %s\n', modelFilename);

%% print out coefficient info
coefficients = linearRegressor.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf('Coefficients in descending order with format:\n');
fprintf('coefficient number, value, abbreviation\n');
for i = 1:length(coefficients)
    coeffNum = coeffSortedIdx(i);
    coeffValue = coefficientSorted(i);
    coeffAbbrev = featureSpec(coeffNum).abbrev;
    fprintf('%2d | %f | %s\n', coeffNum, coeffValue, coeffAbbrev);
end

%%  predict on the compare set
yPred = predict(linearRegressor, Xcompare);

% the baseline always predicts dissatisfied (1 for positive class)
yBaseline = ones(size(yPred));
%% print f1 score and more for different thresholds

% Output as of May 5, 2021:
%  beta=0.25, bestThreshold=0.555, bestLinearFscore=0.31, ...
%  baselineFscoreAtBestThreshold=0.27

thresholdMin = min(yPred);
thresholdMax = max(yPred);
thresholdNum = 500; % change this back to 500
thresholdStep = (thresholdMax - thresholdMin) / thresholdNum;

beta = 0.25;

bestLinearFscore = 0;
baselineFscoreAtBestThreshold = 0;
bestThreshold = 0;

for threshold = thresholdMin:thresholdStep:thresholdMax
    yPredAfterThreshold = yPred >= threshold;
    [scoreModel, ~, ~] = fScore(yCompare, yPredAfterThreshold, 1, 0, beta);
    if scoreModel >= bestLinearFscore
        bestLinearFscore = scoreModel;
        bestThreshold = threshold;
        [scoreBaseline, ~, ~] = fScore(yCompare, yBaseline, 1, 0, beta);
        baselineFscoreAtBestThreshold = scoreBaseline;
    end
end

fprintf('beta=%.2f, bestThreshold=%.3f, bestLinearFscore=%.2f, baselineFscoreAtBestThreshold=%.2f\n', ...
    beta, bestThreshold, bestLinearFscore, baselineFscoreAtBestThreshold);

%% print stats

% Output as of April 27, 2021:
%  Regressor MAE = 0.433054
%  Baseline MAE = 0.743079
%  Linear regressor MSE = 0.250489
%  Baseline MSE = 0.743079
%  Regressor R-squared = 0.347917

mae = @(A, B) (mean(abs(A - B)));
fprintf('Regressor MAE = %f\n', mae(yCompare, yPred));
fprintf('Baseline MAE = %f\n\n', mae(yCompare, yBaseline));

mse = @(actual, pred) (mean((actual - pred) .^ 2));
fprintf('Linear regressor MSE = %f\n', mse(yCompare, yPred));
fprintf('Baseline MSE = %f\n\n', mse(yCompare, yBaseline));

fprintf('Regressor R-squared = %f\n', linearRegressor.Rsquared.adjusted);

%% failure analysis

% config
clipSizeSeconds = 6;
numClipsToCreate = 20;
ignoreSizeSeconds = 2;

sortDirections = ["descend" "ascend"];

yDifference = abs(yCompare - yPred);

for sortDirNum = 1:size(sortDirections, 2)
    
    % sort yDifference following sort direction
    sortDirection = sortDirections(sortDirNum);    
    [~, sortIndex] = sort(yDifference, sortDirection);
    
    clipDir = sprintf('%s\\clips-extended-time-%s', pwd, sortDirection);
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

        timeStart = frameTime - seconds(clipSizeSeconds/2);
        timeEnd = frameTime + seconds(clipSizeSeconds/2);
        idxStart = round(seconds(timeStart) * sampleRate);
        idxEnd = round(seconds(timeEnd) * sampleRate);
        newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, frameNumCompare, clipSizeSeconds);
        clipData = audioData(idxStart:idxEnd);
        audiowrite(newFilename, clipData, sampleRate);


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
            % if this frame is in the same track and utterance as the 
            % original, mark the frame to ignore it
            if frameTrackNumsCompare(frameNumProbe) ~= frameTrackNumsCompare(frameNumCompare)
                continue;
            end
            if frameUtterancesCompare(frameNumProbe) ~= frameUtterancesCompare(frameNumCompare)
                continue;
            end
            framesToIgnore(frameNumProbe) = 1;
        end
    end
    
    fclose(fileID);
    fprintf('Output written to %s\n', outputFilename);
end