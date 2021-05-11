% logisticRegressionDialog.m
%% prepare the data used in the frame-level model
% primarily to get normalizeCenteringValues and normalizeScalingValues to
% normalize the dialog-level dev data accordingly
prepareData;

% clear any unecessary variables left over from the script
clear frameTimesCompare frameTimesTrain
clear frameTrackNumsCompare frameTrackNumsTrain
clear frameUtterNumsCompare frameUtterNumsTrain
clear numDifference
clear Xcompare Xtrain yCompare yTrain

%% load the saved linear model
load('linearRegressor.mat', 'linearRegressor');

%% predict on the dev set

trackListTrain = gettracklist('train-dialog.tl');
trackListDev = gettracklist('dev-dialog.tl');
trackListTest = gettracklist('test-dialog.tl');

featureSpec = getfeaturespec('.\mono-extended.fss');

plotDirectory = append(pwd, "\src\time-pred-plots\");
mkdir(plotDirectory);

% from call-log.xlsx, load the 'filename' and 'label' columns
opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
    'H2:I203', 'VariableNamesRange', 'H1:I1');
callTable = readtable('call-log.xlsx', opts);

predN = []; % for storing predictions on neutral dialogs
predD = []; % for storing predictions on dissatisifed dialogs

volFeatNum = 8;
volFeat = featureSpec(volFeatNum);
volFeatAbbrev = volFeat.abbrev;
fprintf('Feature number %d is "%s"\n', volFeatNum, volFeatAbbrev);

nTracks = size(trackListDev, 2);
yPred = zeros(size(trackListDev));
yActual = zeros(size(trackListDev));
for trackNum = 1:nTracks
    
    track = trackListDev{trackNum};
    fprintf('[%d/%d] %s\n', trackNum, nTracks, track.filename);
    
    % get the X for that dialog
    % try to load the precomputed data, else compute it and save it for 
    % future runs
    customerSide = 'l';
    filename = track.filename;
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, name, ~] = fileparts(filename);
    saveFilename = append(pwd, '\data\dialog-level-linear\', name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch 
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(saveFilename, 'monster');
    end
    
    % replace NaNs with zero
    numNan = length(find(isnan(monster)));
    monster(isnan(monster)) = 0;
    fprintf('\t%d NaNs replaced with zero\n', numNan);
    
    % normalize X (monster) using the same centering values and scaling 
    % values used to normalize the data used for training the frame-level
    % model
    monster = normalize(monster, 'center', normalizeCenteringValues, ...
    'scale', normalizeScalingValues);

    % discard frames where volume is below threshold
    numFramesTotal = size(monster, 1);
    volThresh = 0.99;
    framesBelowVolThreshIndx = find(monster(:,volFeatNum) < volThresh);
    numFramesBelowVolThresh = length(framesBelowVolThreshIndx);
    fprintf('\t%d out of %d frames below volThresh=%.2f\n', ...
        numFramesBelowVolThresh, numFramesTotal, volThresh);
    % monster(framesBelowVolThreshIndx, :) = [];
    
    % get the known Y for that dialog
    matchingIdx = strcmp(callTable.filename, track.filename);
    actualLabel = callTable(matchingIdx, :).label{1};
    actualFloat = labelToFloat(actualLabel);
    
    yActual(trackNum) = actualFloat;
    
    % predict on X using the linear regressor
    % take the average of the predictions and make it the final one
    dialogPred = predict(linearRegressor, monster);
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
    
    dialogActual = ones(size(dialogPred)) * actualFloat;
    
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
    figWidth = 1920;
    figHeight = 1080;
    fig = figure('visible', 'off', 'position', [0,0,figWidth,figHeight]);
    x = (1:length(dialogPred)) * milliseconds(10);
    y = dialogPred;
    plot(x, y);
    hold on
    plot(x, dialogActual);
    legend('dialogPred','dialogActual')
    title(sprintf('%s\n', filename));
    xlabel('time (seconds)');
    ylabel('dissatisfaction');
    ylim([-0.25 1.25]) % fix the y-axis range
    exportgraphics(gca, sprintf('%s/%s.jpg', plotDirectory, name));
    
end

%% generate histogram for predictions on neutral vs dissatisfied dialogs
modelName = 'dialog-level (linear regression) dev (tweak)';
genHistogramForModel(predN, predD, modelName)

%% try different thresholds

% the baseline predicts the average of the train set
% since the data is balanced, should be exactly 0.5
yBaseline = ones(size(yActual));

thresholdMin = -1.5;
thresholdMax = 1.5;
thresholdNum = 500;
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
    
%     [fscoreModel, precModel, recallModel] = fScore(yActual, ...
%         yPredAfterThreshold, 1, 0, beta);
    
%     fprintf('\tthreshold=%.2f fscore=%.2f prec=%.2f recall=%2.f mse=%.2f\n', ...
%         threshold, fscoreModel, precModel, recallModel, thresholdMse);
end

fprintf('\nbest MSE=%.2f at threshold=%.2f\n', bestMse, bestThreshold);

fprintf('regressor at best threshold\n');
yPredAfterThreshold = yPred >= bestThreshold;
[fscoreModel, precModel, recallModel] = fScore(yActual, ...
    yPredAfterThreshold, 1, 0, beta);
fprintf('\tfscore=%.2f prec=%.2f recall=%.2f \n', ...
    fscoreModel, precModel, recallModel);

fprintf('baseline (always predict 1)\n');
[fscoreBaseline, precBaseline, recallBaseline] = fScore(yActual, ...
    yBaseline, 1, 0, beta);
fprintf('\tfscore=%.2f prec=%.2f recall=%.2f \n', ...
    fscoreBaseline, precBaseline, recallBaseline);