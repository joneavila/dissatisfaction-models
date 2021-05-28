% linearRegressionFrame.m

%% config
useTestSet = true; %#ok<*UNRCH>

%% train regressor
prepareData;
linearRegressor = fitlm(XtrainFrame, yTrainFrame);

if useTestSet
    XcompareFrame = XtestFrame;
    yCompareFrame = yTestFrame;
else
    XcompareFrame = XdevFrame;
    yCompareFrame = yDevFrame;
end

%% print out coefficient info
coefficients = linearRegressor.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf('Coefficients in descending order with format:\n');
fprintf('coefficient number, value, feature abbreviation\n');
for i = 1:length(coefficients)
    coeffNum = coeffSortedIdx(i);
    coeffValue = coefficientSorted(i);
    coeffAbbrev = featureSpec(coeffNum).abbrev;
    fprintf('%2d | %f | %s\n', coeffNum, coeffValue, coeffAbbrev);
end

%%  predict on the compare set
yPred = predict(linearRegressor, XcompareFrame);

% the baseline always predicts dissatisfied (1 for positive class)
yBaseline = ones(size(yPred));
%% try different thresholds to find the best Fscore when beta is 0.25

% Output as of May 5, 2021:
%  beta=0.25, bestThreshold=0.555, bestLinearFscore=0.31, ...
%  baselineFscoreAtBestThreshold=0.27

% Output as of May 20, 2021:
% beta=0.25, bestThreshold=1.115, bestLinearFscore=0.38, ...
% baselineFscoreAtBestThreshold=0.36

thresholdMin = min(yPred);
thresholdMax = max(yPred);
thresholdNum = 1000;
thresholdStep = (thresholdMax - thresholdMin) / thresholdNum;

beta = 0.25;

bestFscore = 0;
baselineFscore = 0;
bestThreshold = 0;

for threshold = thresholdMin:thresholdStep:thresholdMax
    yPredAfterThreshold = yPred >= threshold;
    [scoreModel, ~, ~] = fScore(yCompareFrame, yPredAfterThreshold, 1, 0, beta);
    if scoreModel >= bestFscore
        bestFscore = scoreModel;
        bestThreshold = threshold;
        [scoreBaseline, ~, ~] = fScore(yCompareFrame, yBaseline, 1, 0, beta);
        baselineFscore = scoreBaseline;
    end
end

% print stats
fprintf('regressorRsquared=%.2f\n', linearRegressor.Rsquared.adjusted);
mse = @(actual, pred) (mean((actual - pred) .^ 2));
regressorMSE = mse(yCompareFrame, yPred);
baselineMSE = mse(yCompareFrame, yBaseline);

fprintf('beta=%.2f, dissThreshold=%.3f\n', beta, bestThreshold);
fprintf('regressorFscore=%.2f, regressorMSE=%.2f\n', bestFscore, regressorMSE);
fprintf('baselineFscore=%.2f, baselineMSE=%.2f\n', baselineFscore, baselineMSE);

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