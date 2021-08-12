% featureSelection.m
% Get results for dialog-level model using all combination of summary
% features listed below as featureNames.

prepareData;

% train first regressor, used to predict dissatisfaction from prosody
% features
firstRegressor = fitlm(XtrainDialog, yTrainDialog);

% get summary features for the second regressor, used to predict
% dissatisfaction from summary features
tracklistCombined = [tracklistTrainDialog tracklistDevDialog];
[Xcombined, yCombined] = getSummaryXYfromTracklist(tracklistCombined, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);

% features in same order as getSummaryXYfromTracklist.m
featureNames = ["ratio", "min", "max", "average", "range", "std"];

varNames = ["comboString", "F-score (average)"];
sz = [0 length(varNames)];
varTypes = ["string", "double"];
resultsTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

numTracks = size(Xcombined, 1);
numFeatures = size(Xcombined, 2);

% create a list (cell array) of feature index combinations
combinationsList = {};
featureSet = 1:numFeatures;
for featureSubsetSize = 1:numFeatures
    C = nchoosek(featureSet, featureSubsetSize);
    for i = 1:size(C, 1)
        combination = C(i,:);
        combinationsList(end+1) = {combination};
    end
end

% for each combination of summary features
%%
numCombinations = length(combinationsList);
for combinationNum = 1:numCombinations
    
    combination = combinationsList(combinationNum);
    combination = cell2mat(combination);
    
    % create a string to refer to the combination in result table
    featureNamesInCombo = featureNames(combination);
    comboString = strjoin(featureNamesInCombo, '+');
    
    fprintf('[%d/%d] %s\n', combinationNum, numCombinations, comboString);
    
    % for each dialog
    scores = zeros([numTracks 1]);
    for trackNum = 1:numTracks
    
        % select this dialog to predict on and
        % use the rest for training
        Xtrain = Xcombined;
        Xtrain(trackNum,:) = [];
        yTrain = yCombined;
        yTrain(trackNum) = [];
        Xdev = Xcombined(trackNum,:);
        yDev = yCombined(trackNum);
        
        % keep only the features in the combination
        Xtrain = Xtrain(:,combination);
        Xdev = Xdev(:,combination);
        
        % train the second regressor
        secondRegressor = fitlm(Xtrain, yTrain);
        
        % predict on the single dialog
        yPred = predict(secondRegressor, Xdev);
        
        threshold = 0.65;
        yPredAfterThreshold = yPred >= threshold;
        beta = 0.25;
        [score, precision, recall] = fScore(yDev, yPredAfterThreshold, 1, 0, beta);
        
        scores(trackNum) = score;

    end
    
    % add the mean F-score to the results table
    scoreAverage = mean(scores);
    rowToAdd = {comboString, scoreAverage};
    resultsTable = [resultsTable; rowToAdd];
    
end

% sort the table by F-score
resultsTable = sortrows(resultsTable, 2, 'descend');
