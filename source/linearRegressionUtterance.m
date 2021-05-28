% utteranceLevel.m

%% config
useTestSet = true; %#ok<*UNRCH>

%% train regressor
prepareData;
regressor = fitlm(XtrainFrame, yTrainFrame);

%% predict on each utterance in the compare set
if useTestSet
    timesCompare = timesTestFrame;
    tracklistCompare = tracklistTestFrame;
    trackNumsCompare = trackNumsTestFrame;
    utterNumsCompare = utterNumsTestFrame;
    Xcompare = XtestFrame;
    yCompare = yTestFrame;
else
    % ...
end

numTracks = trackNumsCompare(end);

yPred = [];
yActual = [];

for trackNum = 1:numTracks
    
    track = tracklistCompare{trackNum};
    fprintf('[%d/%d]predicting on %s\n', trackNum, trackNum, ...
        track.filename)
    
    trackDataIdx = trackNumsCompare == trackNum;
    
    Xtrack = Xcompare(trackDataIdx, :);
    yTrack = yCompare(trackDataIdx);
    utterNumsTrack = utterNumsCompare(trackDataIdx);
    
    numUtter = utterNumsTrack(end);
 
    % for each utterance, let the regressor 
    % predict on each frame of the utterance then make the average of 
    % those predictions the final prediction
    
    for utterNum = 1:numUtter
        
        utterDataIdx = utterNumsTrack == utterNum;
        Xutter = Xtrack(utterDataIdx, :);
        yUtter = yTrack(utterDataIdx);
        
        utterPred = mean(predict(regressor, Xutter));
        utterActual = yUtter(end);
       
        % appending is ugly but isn't too slow here
        yPred = [yPred; utterPred];
        yActual = [yActual; utterActual];
    end

end
%% baseline
% this baseline always predicts 1 for perfectly dissatisfied and should be
% compared with using precision
yBaseline = ones(size(yActual));
%% try different dissatisfaction thresholds to find the best F-score
% when beta is 0.25
mse = @(actual, pred) (mean((actual - pred) .^ 2));

thresholdMin = 0;
thresholdMax = 1;
thresholdNum = 500;
thresholdStep = (thresholdMax - thresholdMin) / (thresholdNum - 1);
thresholds = thresholdMin:thresholdStep:thresholdMax;
beta = 0.25;

varTypes = ["double", "double", "double", "double", "double"];
varNames = {'threshold', 'mse', 'fscore', 'precision', 'recall'};
sz = [thresholdNum, length(varNames)];
resultTable = table('Size', sz, 'VariableTypes', varTypes, ...
    'VariableNames', varNames);

fprintf('beta=%.2f, min(yPred)=%.2f, max(yPred)=%.2f, mean(yPred)=%.2f\n', ...
    beta, min(yPred), max(yPred), mean(yPred));

for thresholdNum = 1:length(thresholds)
    threshold = thresholds(thresholdNum);
    yPredAfterThreshold = yPred >= threshold;
    [score, precision, recall] = fScore(yActual, ...
        yPredAfterThreshold, 1, 0, beta);
    resultTable{thresholdNum, 1} = threshold;
    resultTable{thresholdNum, 2} = mse(yPredAfterThreshold, yActual);
    resultTable{thresholdNum, 3} = score;
    resultTable{thresholdNum, 4} = precision;
    resultTable{thresholdNum, 5} = recall;
end

% print regressor stats
[regressorFscore, scoreIdx] = max(resultTable{:, 3});
bestThreshold = resultTable{scoreIdx, 1};
fprintf('dissThreshold=%.3f\n', bestThreshold);
regressorPrecision = resultTable{scoreIdx, 4};
regressorRecall = resultTable{scoreIdx, 5};
regressorMSE = mse(yPred, yActual);
fprintf('regressorFscore=%.2f, regressorPrecision=%.2f, regressorRecall=%.2f, regressorMSE=%.2f\n', ...
    regressorFscore, regressorPrecision, regressorRecall, regressorMSE);

% print baseline stats
yBaselineAfterThreshold = yBaseline >= bestThreshold;
baselineMSE = mse(yBaselineAfterThreshold, yActual);
[baselineFscore, baselinePrecision, baselineRecall] = ...
    fScore(yActual, yBaselineAfterThreshold, 1, 0, beta);
fprintf('baselineFscore=%.2f, baselinePrecision=%.2f, baselineRecall=%.2f, baselineMSE=%.2f\n', ...
    baselineFscore, baselinePrecision, baselineRecall, baselineMSE);
