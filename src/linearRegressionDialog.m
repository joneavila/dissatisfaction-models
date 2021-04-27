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
    label = callTable(matchingIdx, :).label{1};
    if strcmp(label, 'successful')
        yActual(trackNum) = 0;
    elseif strcmp(label, 'doomed_1') || strcmp(label, 'doomed_2')
        yActual(trackNum) = 1;
    else
        error('unknown label in call table')
    end
    
    % predict on X using the linear regressor
    a = monster.monster;
    dialogPred = predict(model, a);
    
    % take the average of the predictions and make it the final one
    yPred(trackNum) = mean(dialogPred, 'omitnan');
    
end

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