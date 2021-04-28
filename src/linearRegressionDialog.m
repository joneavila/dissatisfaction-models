% logisticRegressionDialog.m

%% load the linear regressor
% to train and save the linear regressor, run linearRegression.m
model = load('linearRegressor.mat');
model = model.model;

trackListTrain = gettracklist('train-dialog.tl');
trackListDev = gettracklist('dev-dialog.tl');
trackListTest = gettracklist('test-dialog.tl');

featureSpec = getfeaturespec('.\mono-extended.fss');

%% predict on the training set
nTracks = size(trackListDev, 2);
yPred = zeros(size(trackListDev));
yActual = zeros(size(trackListDev));

% from call-log.xlsx, load the 'filename' and 'label' columns
opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
    'H2:I203', 'VariableNamesRange', 'H1:I1');
callTable = readtable('call-log.xlsx', opts);

predN = []; % for storing predictions on neutral dialogs
predD = []; % for storing predictions on dissatisifed dialogs

for trackNum = 1:nTracks
    
    track = trackListDev{trackNum};
    fprintf('[%d/%d] Predicting on %s\n', trackNum, nTracks, track.filename);
    
    % get the X for that dialog
    % try to load the pre-computed monster, else compute it and save it
    % for future runs
    customerSide = 'l';
    filename = track.filename;
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, name, ~] = fileparts(filename);
    saveFilename = append(pwd, '\data\dialog-level-linear\', name, '.mat');
    try
        monster = load(saveFilename);
    catch 
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(saveFilename, 'monster');
    end
    
    % get the known Y for that dialog
    matchingIdx = strcmp(callTable.filename, track.filename);
    actualLabel = callTable(matchingIdx, :).label{1};
    actualFloat = labelToFloat(actualLabel);
    
    yActual(trackNum) = actualFloat;
    
    % predict on X using the linear regressor
    % take the average of the predictions and make it the final one
    dialogPred = mean(predict(model, monster.monster), 'omitnan');
    yPred(trackNum) = dialogPred;
    
    if actualFloat == 0
        predN = [predN dialogPred];
    elseif actualFloat == 1
        predD = [predD dialogPred];
    else
        error('unknown float: %f\n', actualFloat);
    end
    
end

%% generate histogram for predictions on neutral vs dissatisfied dialogs
modelName = 'dialog-level (linear regression) dev';
genHistogramForModel(predN, predD, modelName)

%% try different thresholds
thresholdMin = min(yPred);
thresholdMax = max(yPred);
thresholdNum = 1000;
thresholdStep = (thresholdMax - thresholdMin) / thresholdNum;

mse = @(actual, pred) (mean((actual - pred) .^ 2));

bestMse = realmax;
bestThreshold = 0;

for threshold = thresholdMin:thresholdStep:thresholdMax
    
    yPredAdjusted = yPred >= threshold;
    thresholdMse = mse(yPredAdjusted, yActual);
    
    if thresholdMse <= bestMse
        bestMse = thresholdMse;
        bestThreshold = threshold;
    end
    
end

fprintf('bestThreshold=%.2f, MSE=%.2f\n', bestThreshold, bestMse);