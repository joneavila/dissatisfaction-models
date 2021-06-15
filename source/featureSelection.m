% featureSelection.m

prepareData;

% train first regressor
firstRegressor = fitlm(XtrainDialog, yTrainDialog);

% get summary features for the second regressor
[XsummaryTrain, yTrain] = getSummaryXYfromTracklist(tracklistTrainDialog, ...
    centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);
[XsummaryDev, yDev] = getSummaryXYfromTracklist(tracklistDevDialog, ...
centeringValuesDialog, scalingValuesDialog, firstRegressor, useTimeFeature);

% features in same order as getSummaryXYfromTracklist.m
featureNames = ["ratio", "min", "max", "average", "range", "std"];

varNames = ["comboString", "F-score", "precision", "recall"];
sz = [0 length(varNames)];
varTypes = ["string", "double", "double", "double"];
resultTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

numFeatures = size(XsummaryTrain, 2);
featureSet = 1:numFeatures;

for featureSubsetSize = 1:numFeatures
    C = nchoosek(featureSet, featureSubsetSize);
    
    for i = 1:size(C, 1)
        combination = C(i,:);
        
        % create combination string to refer to in result table
        featureNamesInCombo = featureNames(combination);
        comboString = strjoin(featureNamesInCombo, '+');
        
        % get subset of the data
        Xtrain = XsummaryTrain(:,combination);
        Xdev = XsummaryDev(:,combination);
        
        % train
        secondRegressor = fitlm(Xtrain, yTrain);
        
        % predict
        yPred = predict(secondRegressor, Xdev);
        
        % get result
        threshold = 0.5;
        beta = 0.25;
        yPredAfterThreshold = yPred >= threshold;
        [score, precision, recall] = fScore(yDev, yPredAfterThreshold, ...
            1, 0, beta);
        
        % add result to table
        rowToAdd = {comboString, score, precision, recall};
        resultTable = [resultTable; rowToAdd];
         
    end
    
    % sort table
    sortColumn = 2;
    direction = 'descend';
    resultTableSorted = sortrows(resultTable, sortColumn, direction);
  
end