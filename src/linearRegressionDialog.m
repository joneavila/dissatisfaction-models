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

plotDirectory = append(pwd, "\src\time-pred-plots\");
mkdir(plotDirectory);

% from call-log.xlsx, load the 'filename' and 'label' columns
opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
    'H2:I203', 'VariableNamesRange', 'H1:I1');
callTable = readtable('call-log.xlsx', opts);

predN = []; % for storing predictions on neutral dialogs
predD = []; % for storing predictions on dissatisifed dialogs

for trackNum = 1:nTracks
    
    track = trackListDev{trackNum};
    fprintf('[%d/%d] %s\n', trackNum, nTracks, track.filename);
    
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
    dialogPred = predict(model, monster.monster);
    dialogPredMean = mean(dialogPred, 'omitnan');
    yPred(trackNum) = dialogPredMean;
    
    % add the predictions to predN or predD to print a histogram later
    if actualFloat == 0
        predN = [predN dialogPredMean];
    elseif actualFloat == 1
        predD = [predD dialogPredMean];
    else
        error('unknown float: %f\n', actualFloat);
    end
    
    % print min, max predictions and corresponding times
    [predMin, indMin] = min(dialogPred);
    [predMax, indMax] = max(dialogPred);
    predTimeSecondsMin = frameNumToTime(indMin);
    predTimeSecondsMax = frameNumToTime(indMax);
    fprintf('\tpredMean=%.2f\n', dialogPredMean);
    fprintf('\tpredMin=%.2f, predTimeMin="%s"\n', ...
        predMin, datestr(predTimeSecondsMin, 'MM:SS'));
    fprintf('\tpredMax=%.2f, predTimeMax="%s"\n', ...
        predMax, datestr(predTimeSecondsMax, 'MM:SS'));
    
    % plot predictions over time
    % dialogPred
    % add the total time to the title
    x = (1:length(dialogPred)) * milliseconds(10);
    y = dialogPred;
    plot(x, y);
    title(sprintf('%s\n', filename));
    xlabel('time (seconds)');
    ylabel('dissatisfaction');
    ax = gca;
    exportgraphics(ax, sprintf('%s/%s.jpg', plotDirectory, name));
    
end

%% generate histogram for predictions on neutral vs dissatisfied dialogs
modelName = 'dialog-level (linear regression) dev (tweak)';
genHistogramForModel(predN, predD, modelName)

%% try different thresholds

% the baseline predicts the average of the train set
% since the data is balanced, should be exactly 0.5
yBaseline = ones(size(yActual));

thresholdMin = min(yPred);
thresholdMax = max(yPred);
thresholdNum = 100;
thresholdStep = (thresholdMax - thresholdMin) / thresholdNum;
beta = 0.25;

bestMse = realmax;
bestThreshold = 0;

fprintf('beta=%.2f min(yPred)=%.2f max(yPred)=%2.f mean(yPred)=%.2f\n', ...
    beta, min(yPred), max(yPred), mean(yPred));

mse = @(actual, pred) (mean((actual - pred) .^ 2));

for threshold = thresholdMin:thresholdStep:thresholdMax
    
    yPredAfterThreshold = yPred >= threshold;
    thresholdMse = mse(yPredAfterThreshold, yActual);
    
    if thresholdMse < bestMse
        bestMse = thresholdMse;
        bestThreshold = threshold;
    end
   
    [fscoreModel, precModel, recallModel] = fScore(yActual, ...
        yPredAfterThreshold, 1, 0, beta);
    
    fprintf('\tthreshold=%.2f fscore=%.2f prec=%.2f recall=%2.f mse=%.2f\n', ...
        threshold, fscoreModel, precModel, recallModel, thresholdMse);
end

fprintf('\nbest MSE=%.2f at threshold=%.2f\n', bestMse, bestThreshold);

fprintf('regressor at best threshold\n');
yPredAfterThreshold = yPred >= bestThreshold;
[fscoreModel, precModel, recallModel] = fScore(yActual, ...
    yPredAfterThreshold, 1, 0, beta);
fprintf('\tfscore=%.2f prec=%.2f recall=%2.f \n', ...
    fscoreModel, precModel, recallModel);

fprintf('baseline (always predict 1)\n');
[fscoreBaseline, precBaseline, recallBaseline] = fScore(yActual, ...
    yBaseline, 1, 0, beta);
fprintf('\tfscore=%.2f prec=%.2f recall=%2.f \n', ...
    fscoreBaseline, precBaseline, recallBaseline);