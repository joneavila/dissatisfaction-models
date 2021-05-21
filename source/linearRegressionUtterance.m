% utteranceLevel.m 

%% train regressor
prepareData;
regressor = fitlm(XtrainFrame, yTrainFrame);

%% predict on each utterance in the compare set
tracklistCompare = tracklistDevFrame;
yPred = [];
yActual = [];

nTracks = size(tracklistCompare, 2);
for trackNum = 1:nTracks
    
    track = tracklistCompare{trackNum};
    fprintf('[%d/%d]predicting on %s\n', trackNum, nTracks, ...
        track.filename)
    
    % get the annotation table, assuming dilaog and annotation files share
    % the same name
    [~, name, ~] = fileparts(track.filename);
    annotationFilename = append(name, '.txt');
    annotationPathRelative = append('annotations\', annotationFilename);
    useFilter = true;
    annotationTable = readElanAnnotation(annotationPathRelative, useFilter);
    
    % load the monster, else compute it and save it for future runs
    dataDir = append(pwd, '\data\monsters\');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir)
    end
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
    [~, name, ~] = fileparts(track.filename);
    saveFilename = append(dataDir, name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch 
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(saveFilename, 'monster');
    end
    
    % normalize X (monster) using the same centering values and scaling 
    % values used to normalize the data used for training
    monster = normalize(monster, 'center', ...
    centeringValuesFrame, 'scale', scalingValuesFrame);
    
    % for each utterance (row in annotation table) let the regressor 
    % predict on each frame of the utterance then make the average of 
    % those predictions the final prediction
    nUtterances = size(annotationTable, 1);
    utterancePred = zeros([nUtterances 1]);
    for rowNum = 1:nUtterances
        row = annotationTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        utterance = monster(frameStart:frameEnd, :);
        utterancePredictions = predict(regressor, utterance);
        utterancePred(rowNum) = mean(utterancePredictions);
    end
    
    utteranceActual = arrayfun(@labelToFloat, annotationTable.label);
    
    % display utterance info in a table
    disp(table(utterancePred, utteranceActual));

    % appending is ugly but isn't too slow here
    yPred = [yPred; utterancePred];
    yActual = [yActual; utteranceActual];
    
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
