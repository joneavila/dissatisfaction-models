% linearRegressionFrame.m
% A frame-level linear regression model.

% configuration
useTestSet = true; % to set the "compare" set as either the dev or test set
beta = 0.25; % to calculate F-score

prepareDataFrame;

% train regressor
regressor = fitlm(XtrainFrame, yTrainFrame);

% depending on useTestSet, the "compare" set is either the dev or test set
if useTestSet
    XcompareFrame = XtestFrame; %#ok<*UNRCH>
    yCompareFrame = yTestFrame;
else
    XcompareFrame = XdevFrame;
    yCompareFrame = yDevFrame;
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
    % for now there is only the extra time feature to worry about
    % (see prepareDataFrame.m description)
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

%% try different thresholds to find the best F-score
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

% %% failure analysis
% 
% % config
% clipSizeSeconds = 6;
% numClipsToCreate = 20;
% ignoreSizeSeconds = 2;
% 
% sortDirections = ["descend" "ascend"];
% 
% yDifference = abs(yCompare - yPred);
% 
% for sortDirNum = 1:size(sortDirections, 2)
%     
%     % sort yDifference following sort direction
%     sortDirection = sortDirections(sortDirNum);    
%     [~, sortIndex] = sort(yDifference, sortDirection);
%     
%     clipDir = sprintf('%s\\clips-extended-time-%s', pwd, sortDirection);
%     [status, msg, msgID] = mkdir(clipDir);
%     
%     outputFilename = append(clipDir, '\output.txt');  % need to add rest of path
%     fileID = fopen(outputFilename, 'w');
%     
%     fprintf(fileID, 'sortDirection=%s\n\n', sortDirection);
% 
%     framesToIgnore = zeros(size(yDifference));
%     
%     % create clips until numClipsCreated is reached or all frames have been
%     % probed
%     numClipsCreated = 0;
%     for frameProbingNum = 1:length(sortIndex)
%         
%         if numClipsCreated >= numClipsToCreate
%             break;
%         end
% 
%         frameNumCompare = sortIndex(frameProbingNum);
% 
%         % ignore this frame if it has already been included in a clip
%         if framesToIgnore(frameNumCompare)
%             continue;
%         end
% 
%         frameTime = frameTimesCompare(frameNumCompare);
%         trackNum = frameTrackNumsCompare(frameNumCompare);
%         track = trackListCompare{trackNum};
%         [audioData, sampleRate] = audioread(track.filename);
% 
%         timeStart = frameTime - seconds(clipSizeSeconds/2);
%         timeEnd = frameTime + seconds(clipSizeSeconds/2);
%         idxStart = round(seconds(timeStart) * sampleRate);
%         idxEnd = round(seconds(timeEnd) * sampleRate);
%         newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, frameNumCompare, clipSizeSeconds);
%         clipData = audioData(idxStart:idxEnd);
%         audiowrite(newFilename, clipData, sampleRate);
% 
% 
%         fprintf(fileID, 'clip%d  timeSeconds=%.2f  filename=%s\n', ...
%             frameNumCompare, seconds(frameTime), track.filename);
%         fprintf(fileID, '\tpredicted=%.2f  actual=%.2f\n', yPred(frameNumCompare), yCompare(frameNumCompare));
%         
%         numClipsCreated = numClipsCreated + 1;
% 
%         % zero out the 
%         % check if any other frame number is within this frame's utterance
%         clipSizeFrames = seconds(ignoreSizeSeconds) / milliseconds(10); % monster frames are 10ms
%         frameNumCompareStart = frameNumCompare - clipSizeFrames / 2;
%         frameNumCompareEnd = frameNumCompare + clipSizeFrames / 2;
%         
%         % adjust compare start and compare end if out of bounds
%         if frameNumCompareStart < 1
%             frameNumCompareStart = 1;
%         end
%         if frameNumCompareEnd > length(yDifference)
%             frameNumCompareEnd = length(yDifference);
%         end
% 
%         for frameNumProbe = frameNumCompareStart:frameNumCompareEnd
%             % if this frame is in the same track and utterance as the 
%             % original, mark the frame to ignore it
%             if frameTrackNumsCompare(frameNumProbe) ~= frameTrackNumsCompare(frameNumCompare)
%                 continue;
%             end
%             if frameUtterancesCompare(frameNumProbe) ~= frameUtterancesCompare(frameNumCompare)
%                 continue;
%             end
%             framesToIgnore(frameNumProbe) = 1;
%         end
%     end
%     
%     fclose(fileID);
%     fprintf('Output written to %s\n', outputFilename);
% end