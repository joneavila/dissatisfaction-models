% logisticRegressionDialog.m

%% config
useTestSet = false; %#ok<*UNRCH>

%% train the first regressor
prepareData;
firstRegressor = fitlm(XtrainDialog, yTrainDialog);

%% get the summary features for the second regressor's data
fprintf('Get summary features for train set\n');
[XsummaryTrain, yActualTrain] = getSummaryXYfromTracklist(tracklistTrainDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);

fprintf('Get summary features for compare set\n');
if useTestSet
    [XsummaryCompare, yActualCompare] = getSummaryXYfromTracklist(tracklistTestDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);
else
    [XsummaryCompare, yActualCompare] = getSummaryXYfromTracklist(tracklistDevDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);
end

%% calculate summary features correlations
X = [XsummaryTrain; XsummaryCompare];
y = [yActualTrain yActualCompare];
r1 = corr(X);
r2 = corr(X, y');

%% feature selection
XsummaryTrain = XsummaryTrain(:,[1 4 6]);
XsummaryCompare = XsummaryCompare(:,[1 4 6]);

%% train the second regressor
secondRegressor = fitlm(XsummaryTrain, yActualTrain);

%% predict on the compare data (dev set or test set)
yPred = predict(secondRegressor, XsummaryCompare);

% the baseline always predicts dissatisfied (1 for positive class)
yBaseline = ones(size(yPred));

%% try different dissatisfaction thresholds to find the best F-score
% when beta is 0.25
mse = @(actual, pred) (mean((actual - pred) .^ 2));

thresholdMin = 0;
thresholdMax = 1;
thresholdNum = 50;
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
    [score, precision, recall] = fScore(yActualCompare, ...
        yPredAfterThreshold, 1, 0, beta);
    resultTable{thresholdNum, 1} = threshold;
    resultTable{thresholdNum, 2} = mse(yPredAfterThreshold, yActualCompare');
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
regressorMSE = mse(yPred', yActualCompare);
fprintf('regressorFscore=%.2f, regressorPrecision=%.2f, regressorRecall=%.2f, regressorMSE=%.2f\n', ...
    regressorFscore, regressorPrecision, regressorRecall, regressorMSE);

% print baseline stats
yBaselineAfterThreshold = yBaseline >= bestThreshold;
baselineMSE = mse(yBaselineAfterThreshold, yActualCompare');
[baselineFscore, baselinePrecision, baselineRecall] = ...
    fScore(yActualCompare, yBaselineAfterThreshold, 1, 0, beta);
fprintf('baselineFscore=%.2f, baselinePrecision=%.2f, baselineRecall=%.2f, baselineMSE=%.2f\n', ...
    baselineFscore, baselinePrecision, baselineRecall, baselineMSE);

% %% plot histograms for summary features
% % for neutral versus dissatisfied dialogs in combined train and compare set
% 
% XsummaryCombined = [XsummaryTrain; XsummaryCompare];
% yActualCombined = [yActualTrain yActualCompare];
% 
% % separate XsummaryCombined into XsummaryCombNeutral and XsummaryCombDiss
% XsummaryCombNeutral = [];
% XsummaryCombDiss = [];
% for dialogNum = 1:length(yActualCombined)
%     label = yActualCombined(dialogNum);
%     if label == 0
%         XsummaryCombNeutral = [XsummaryCombNeutral; XsummaryCombined(dialogNum, :)];
%     elseif label == 1
%         XsummaryCombDiss = [XsummaryCombDiss; XsummaryCombined(dialogNum, :)];
%     else
%         error('unexpected label');
%     end
% end
% 
% % plot a histogram for each summary feature
% % NOTE: featureNames are hardcoded and need to match the order seen in the
% % getSummaryXy function at the bottom of this script
% featureNames = ["ratio" "min" "max" "average" "range" "std"];
% nBins = 32;
% barColorN = '#1e88e5'; 
% barColorD = '#fb8c00';
% 
% imageDir = append(pwd, "\histograms-summary-features\");
% if ~exist(imageDir, 'dir')
%     mkdir(imageDir)
% end
% 
% 
% for featureNum = 1:length(featureNames)
%     f = figure('Visible', 'off');
%     
%     % histogram for neutral
%     hN = histogram(XsummaryCombNeutral(:, featureNum), nBins);
%     hN.FaceColor = barColorN;
%     
%     hold on
%    
%     % histogram for dissatisfied
%     hD = histogram(XsummaryCombDiss(:, featureNum), nBins);
%     hD.FaceColor = barColorD;
%     
%     % normalize the histograms so that all bar heights add to 1
%     hN.Normalization = 'probability';
%     hD.Normalization = 'probability';
%     
%     % adjust bars so that both plots align
%     hN.BinWidth = hD.BinWidth;
%     hN.BinEdges = hD.BinEdges;
%     
%     % add titles, axes labels, and legend
%     featureName = featureNames(featureNum);
%     titleText = sprintf('feature %d (%s)', featureNum, featureName);
%     subtitleText = sprintf('train and dev data, %d bins, normalized bars', nBins);
%     title(titleText, subtitleText);
%     ylabel('Number in bin');
%     xlabel('Bin');
%     legend('neutral','dissatisfied')
%     
%     % save image
%     imageFilepath = append(imageDir, titleText, ".png");
%     saveas(f, imageFilepath);
%     fprintf('Saved image to %s\n', imageFilepath);
%     
%     clf;
% end