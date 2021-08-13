% linearRegressionFrame.m
% A frame-level linear regression model.

% configuration
useTestSet = true; % to set the "compare" set as either the dev or test set
beta = 0.25; % to calculate F-score

loadDataFrame;

% train regressor
regressor = fitlm(XtrainFrame, yTrainFrame);

% depending on useTestSet, the "compare" set is either the dev or test set
if useTestSet
    XcompareFrame = XtestFrame; %#ok<*UNRCH>
    yCompareFrame = yTestFrame;
    trackNumsCompareFrame = trackNumsTestFrame;
    tracklistCompareFrame = tracklistTestFrame;
    frameTimesCompareFrame = frameTimesTestFrame;
    utterNumsCompareFrame = utterNumsTestFrame;
else
    XcompareFrame = XdevFrame;
    yCompareFrame = yDevFrame;
    trackNumsCompareFrame = trackNumsDevFrame;
    tracklistCompareFrame = tracklistDevFrame;
    frameTimesCompareFrame = frameTimesDevFrame;
    utterNumsCompareFrame = utterNumsDevFrame;
end

%% print coefficient info
coeffs = regressor.Coefficients.Estimate;
coeffs(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coeffs, 'descend');
fprintf('Coefficients sorted by value, descending order with format:\n');
fprintf('coefficient number, value, feature abbreviation\n');
for i = 1:length(coeffs)
    coeffNum = coeffSortedIdx(i);
    coeffValue = coefficientSorted(i);
    
    % there may be more features than specified in featureSpec
    % (for now there is only the extra time feature)
    if coeffNum <= length(featureSpec)
        coeffAbbrev = featureSpec(coeffNum).abbrev;
    else
        coeffAbbrev = 'NA (not specified in featureSpec)'; 
    end
    
    fprintf('%3d | %+f | %s\n', coeffNum, coeffValue, coeffAbbrev);
end

%%  predict on the compare set
yPred = predict(regressor, XcompareFrame);

% the baseline always predicts dissatisfied (assume 1 for dissatisfied)
yBaseline = ones(size(yPred));

%% try different dissatisfaction thresholds to find the best F-score
mse = @(actual, pred) (mean((actual - pred) .^ 2));

% try thresholdNum thresholds between thresholdMin and thresholdMax
thresholdMin = 0;
thresholdMax = 1;
thresholdNum = 500;
thresholds = linspace(thresholdMin, thresholdMax, thresholdNum);

% create a table to store results
varTypes = {'double', 'double', 'double', 'double', 'double'};
varNames = {'threshold', 'mse', 'fscore', 'precision', 'recall'};
sz = [thresholdNum, length(varNames)];
resultTable = table('Size', sz, 'VariableTypes', varTypes, ...
    'VariableNames', varNames);

% populate results table
for thresholdNum = 1:length(thresholds)
    threshold = thresholds(thresholdNum);
    yPredAfterThreshold = yPred >= threshold;
    [score, precision, recall] = fScore(yCompareFrame, ...
        yPredAfterThreshold, 1, 0, beta);
    resultTable{thresholdNum, 1} = threshold;
    resultTable{thresholdNum, 2} = mse(yPredAfterThreshold, yCompareFrame);
    resultTable{thresholdNum, 3} = score;
    resultTable{thresholdNum, 4} = precision;
    resultTable{thresholdNum, 5} = recall;
end

% print yPred stats
fprintf('min(yPred)=%.2f, max(yPred)=%.2f, mean(yPred)=%.2f\n', ...
    min(yPred), max(yPred), mean(yPred));

% print threshold stats
[maxScore, maxScoreIdx] = max(resultTable{:, 3});
bestThreshold = resultTable{maxScoreIdx, 1};
fprintf('dissThreshold=%.3f\n', bestThreshold);

% print regressor stats
fprintf('regressorRsquared=%.2f\n', regressor.Rsquared.adjusted);
regressorPrecision = resultTable{maxScoreIdx, 4};
regressorRecall = resultTable{maxScoreIdx, 5};
regressorMSE = resultTable{maxScoreIdx, 2};
fprintf('regressorFscore=%.2f, regressorPrecision=%.2f, regressorRecall=%.2f, regressorMSE=%.2f\n', ...
    maxScore, regressorPrecision, regressorRecall, regressorMSE);

% print baseline stats
yBaselineAfterThreshold = yBaseline >= bestThreshold;
baselineMSE = mse(yBaselineAfterThreshold, yCompareFrame);
[baselineFscore, baselinePrecision, baselineRecall] = ...
    fScore(yCompareFrame, yBaselineAfterThreshold, 1, 0, beta);
fprintf('baselineFscore=%.2f, baselinePrecision=%.2f, baselineRecall=%.2f, baselineMSE=%.2f\n', ...
    baselineFscore, baselinePrecision, baselineRecall, baselineMSE);

%% failure analysis

% configuration
clipSizeSeconds = 6;
nClipsToCreatePerDirection = 30;
ignoreSizeSeconds = 2;

yDifference = abs(yCompareFrame - yPred);

sortDirections = ["descend" "ascend"];
for sortDirNum = 1:size(sortDirections, 2)
    
    % sort yDifference in sortDirection
    sortDirection = sortDirections(sortDirNum);    
    [~, sortIndex] = sort(yDifference, sortDirection);
    
    % create the directory for this direction's clips
    clipDir = sprintf('%s/failure-analysis/clips-%s', pwd, sortDirection);
    [status, msg, msgID] = mkdir(clipDir);
    
    % create an output file to write clip details to
    outputFilename = append(clipDir, '/clip-details.txt');
    fileID = fopen(outputFilename, 'w');
    
    % write sort direction to file
    fprintf(fileID, 'sortDirection=%s\n\n', sortDirection);

    framesToIgnore = zeros(size(yDifference));
    
    % create clips until numClipsCreated is reached or 
    % all frames have been probed
    numClipsCreated = 0;
    for i = 1:length(sortIndex)
        
        if numClipsCreated >= nClipsToCreatePerDirection
            break;
        end

        frameNumToProbe = sortIndex(i);

        % ignore this frame if it has already been included in a clip
        % (within ignoreSizeSeconds of an existing clip)
        if framesToIgnore(frameNumToProbe)
            continue;
        end
        
        frameTime = frameTimesCompareFrame(frameNumToProbe);
        
        trackNum = trackNumsCompareFrame(frameNumToProbe);
        track = tracklistCompareFrame{trackNum};
        [audioData, sampleRate] = audioread(track.filename);

        % write the clip to file, clipSizeSeconds with probing frame in the
        % middle
        timeStart = frameTime - (clipSizeSeconds/2);
        timeEnd = frameTime + (clipSizeSeconds/2);
        idxStart = round(seconds(seconds(timeStart) * sampleRate));
        idxEnd = round(seconds(seconds(timeEnd) * sampleRate));
        newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, ...
            frameNumToProbe, clipSizeSeconds);
        clipData = audioData(idxStart:idxEnd);
        audiowrite(newFilename, clipData, sampleRate);

        fprintf(fileID, 'clip%d  timeSeconds=%.2f  filename=%s\n', ...
            frameNumToProbe, frameTime, track.filename);
        fprintf(fileID, '\tpredicted=%.2f  actual=%.2f\n', ...
            yPred(frameNumToProbe), yCompareFrame(frameNumToProbe));
        
        numClipsCreated = numClipsCreated + 1;

        % zero out the 
        % check if any other frame number is within this frame's utterance
        % monster frames are 10ms
        clipSizeFrames = seconds(ignoreSizeSeconds) / milliseconds(10);
        frameNumCompareStart = frameNumToProbe - clipSizeFrames / 2;
        frameNumCompareEnd = frameNumToProbe + clipSizeFrames / 2;
        
        % adjust compare start and compare end if out of bounds
        if frameNumCompareStart < 1
            frameNumCompareStart = 1;
        end
        if frameNumCompareEnd > length(yDifference)
            frameNumCompareEnd = length(yDifference);
        end

        for i = frameNumCompareStart:frameNumCompareEnd
            % if this frame is in the same track and utterance as the 
            % original, mark the frame to ignore it
            if trackNumsCompareFrame(i) ~= ...
                    trackNumsCompareFrame(frameNumToProbe)
                continue;
            end
            if utterNumsCompareFrame(i) ~= ...
                    utterNumsCompareFrame(frameNumToProbe)
                continue;
            end
            framesToIgnore(i) = 1;
        end
    end
    
    fclose(fileID);
    fprintf('Output written to %s\n', outputFilename);
end