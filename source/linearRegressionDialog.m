% logisticRegressionDialog.m

%% train the first regressor
prepareData;
firstRegressor = fitlm(XtrainDialog, yTrainDialog);

%% get the summary features for the second regressor's data
[XsummaryTrain, yActualTrain] = getSummaryXy(tracklistTrainDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor);
[XsummaryCompare, yActualCompare] = getSummaryXy(tracklistDevDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor);
% [XsummaryCompare, yActualCompare] = getSummaryXy(trackListTestDialog, ...
%     centeringValuesDialog, scalingValuesDialog, firstRegressor);

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

function [Xsummary, yActual] = getSummaryXy(tracklist, ...
    normalizeCenteringValues, normalizeScalingValues, firstRegressor)

    featureSpec = getfeaturespec('.\source\mono.fss');
    nTracks = size(tracklist, 2);

    numSummaryFeatures = 5;
    Xsummary = zeros([nTracks numSummaryFeatures]);
    yActual = zeros(size(tracklist));
    
    dataDir = append(pwd, '\data\monsters\');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir)
    end

    for trackNum = 1:nTracks
        
        track = tracklist{trackNum};
        filename = track.filename;
        fprintf('[%d/%d] %s... ', trackNum, nTracks, track.filename);
        
        % get the annotation path, assuming they share the same name
        [~, name, ~] = fileparts(filename);
        annFilename = append(name, ".txt");
        annotationPath = append('annotations\', annFilename);
        
        % skip this dialog if the annotation file does not exist
        if ~exist(annotationPath, 'file')
            fprintf('annotation file not found\n');
            continue
        end

        % get the X for that dialog
        % try to load the precomputed data, else compute it and save it for 
        % future runs
        customerSide = 'l';
        
        trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
        [~, name, ~] = fileparts(filename);
        saveFilename = append(dataDir, name, '.mat');
        try
            monster = load(saveFilename);
            monster = monster.monster;
        catch 
            [~, monster] = makeTrackMonster(trackSpec, featureSpec);
            save(saveFilename, 'monster');
        end

        % normalize X (monster) using the same centering values and scaling 
        % values used to normalize the data used for training the 
        % frame-level model
        monster = normalize(monster, 'center', ...
            normalizeCenteringValues, 'scale', normalizeScalingValues);
        
        % trim out-of-character frames from start and end of dialog
        useFilter = false;
        annotationTable = readElanAnnotation(annotationPath, useFilter);
        numRows = size(annotationTable, 1);
        for rowNum = 1:numRows % find the first non-out-of-character
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumStart = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        for rowNum = numRows:-1:1 % find the last non-out-of-character
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumEnd = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        monster = monster(frameNumStart:frameNumEnd, :);

        % get the known Y for that dialog
        % from call-log.xlsx, load the 'filename' and 'label' columns
        opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
            'H2:I203', 'VariableNamesRange', 'H1:I1');
        callTable = readtable('call-log.xlsx', opts);
        matchingIdx = strcmp(callTable.filename, track.filename);
        actualLabel = callTable(matchingIdx, :).label{1};
        actualFloat = labelToFloat(actualLabel);

        yActual(trackNum) = actualFloat;

        % predict on X using the linear regressor
        % take the average of the predictions and make it the final one
        dialogPred = predict(firstRegressor, monster);

        % feature 1 - number of frames in dialogPred above the best 
        % threshold (the threshold with best F_0.25 score, found in 
        % linearRegressionFrame.m) divided by the number of total frames
        % feature 2 - min of dialogPred
        % feature 3 - max of dialogPred
        % feature 4 - average of dialogPred
        % feature 5 - range of dialogPred 
        % feature 6 - standard deviation of dialogPred
        bestThreshold = 0.555;
        Xsummary(trackNum, 1) = nnz(dialogPred > bestThreshold) / ...
            length(dialogPred);
        Xsummary(trackNum, 2) = min(dialogPred);
        Xsummary(trackNum, 3) = max(dialogPred);
        Xsummary(trackNum, 4) = mean(dialogPred);
        Xsummary(trackNum, 5) = range(dialogPred);
        Xsummary(trackNum, 6) = std(dialogPred);
        
        % TODO update to overlay annotations
        % plot dialogPred over time
        plotDirectory = append(pwd, "\time-pred-plots\");
        if ~exist(plotDirectory, 'dir')
            mkdir(plotDirectory)
        end
        
        figWidth = 1920;
        figHeight = 1080;
        fig = figure('visible', 'off', 'position', ...
            [0, 0, figWidth, figHeight]);
        x = (1:length(dialogPred)) * milliseconds(10);
        y = dialogPred;
        plot(x, y);
        % hold on
        % plot(x, dialogActual);
        % legend('dialogPred','dialogActual')
        title(sprintf('%s\n', filename));
        xlabel('time (seconds)');
        ylabel('dissatisfaction');
        ylim([-0.25 1.25]) % fix the y-axis range
        exportgraphics(gca, sprintf('%s/%s.jpg', plotDirectory, name));
        
        fprintf('done\n');
        
    end

end