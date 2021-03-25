% Linear regression model

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

dirWorking = append(pwd, "\");

% get feature spec (mono.fss)
featureSpec = getfeaturespec(append(dirWorking, "mono.fss"));

% get the track lists
trackListTrain = gettracklist(append(dirWorking, "frame-level\train.tl"));
trackListDev = gettracklist(append(dirWorking, "frame-level\dev.tl"));

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec);

%%
% train
model = fitlm(Xtrain, yTrain);
%%
% save coefficient info to a text file
outputFilename = 'coefficients.txt';
fileID = fopen(outputFilename, 'w');
coefficients = model.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf(fileID,'Sorted coefficients in descending order with format: coefficient, value, abbreviation\n');
for coeffNum = 1:length(coefficients)
    coeff = coeffSortedIdx(coeffNum);
    coeffValue = coefficientSorted(coeffNum);
    spec = featureSpec(coeff);
    fprintf(fileID, '%2d | %f | %s\n', coeff, coeffValue, spec.abbrev);
end
fclose(fileID);
fprintf('Coefficient info saved to %s\n', outputFilename);

% function for mean absolute error
mae = @(A, B) (mean(abs(A - B)));

% let the regressor predict on the dev set
yPred = predict(model, Xdev);
regressorMae = mae(yDev, yPred);
disp(['Regressor MAE = ', num2str(regressorMae)]);

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);
baselineMae = mae(yDev, yBaseline);
disp(['Baseline MAE = ', num2str(baselineMae)]);

%%
% utterance-level prediction from frame-level predictions
% read it into a table

predictions = [];
predictionsRounded = [];
actuals = [];

for trackNum = 1:size(trackListTrain, 2)
    
    track = trackListTrain{trackNum};
    
    fprintf("predicting on %s\n", track.filename)
    
    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(track.filename);
    annotationFilename = append(name, ".txt");
    
    % get the annotation table set up (just using one annotator here)
    annotationPath = append(dirWorking, 'ja-annotations\', annotationFilename);
    annotationTable = readElanAnnotation(annotationPath, true);
    
    % get the monster
    customerSide = 'l';
    dialogDirectory = convertStringsToChars(append(dirWorking, "calls\"));
    trackSpec = makeTrackspec(customerSide, track.filename, dialogDirectory);
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    nUtterances = size(annotationTable, 1);
    utterancePred = zeros([nUtterances 1]);
    
    % for each utterance (row in annotation table)
    for rowNum = 1:nUtterances
        
        row = annotationTable(rowNum, :);
        
        % get the utterance
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        utterance = monster(frameStart:frameEnd, :);
        
        % let the regressor predict on each frame of the utterance then
        % make the average of those predictions the final prediction
        utterancePred(rowNum) = mean(predict(model, utterance));
        
    end
    
    % Round predictions (so threshold is 0.5)
    utterancePredRound = round(utterancePred);
    
    utteranceActual = arrayfun(@(x) labelToFloat(x), annotationTable.label);
    
    % display predictions and actual in a table
    disp(table(utterancePred, utterancePredRound, utteranceActual));

    % appending is ugly
    predictions = [predictions; utterancePred];
    predictionsRounded = [predictionsRounded; utterancePredRound];
    actuals = [actuals; utteranceActual];
    
end

fprintf('Utterance MAE = %f\n', mae(actuals, predictions));