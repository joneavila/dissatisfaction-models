% linearRegression.m Linear regression model

featureSpec = getfeaturespec('.\mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");

[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec);

% train regressor
model = fitlm(Xtrain, yTrain);

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
    fprintf(fileID, '%2d | %f | %s\n', coeff, coeffValue, featureSpec(coeff).abbrev);
end
fclose(fileID);
fprintf('Coefficients saved to %s\n', outputFilename);

mae = @(A, B) (mean(abs(A - B)));

% let the regressor predict on the dev set
yPred = predict(model, Xdev);

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);

disp('Frame-level:');
fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));

%% predict on each utterance using frame-level predictions
% the baseline looks at the frames in an utterance and predicts the
% majority class
yUtterancePred = [];
yUtteranceActual = [];
yUtteranceBaseline = [];

for trackNum = 1:size(trackListTrain, 2)
    
    track = trackListTrain{trackNum};
    fprintf("predicting on %s\n", track.filename)
    
    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(track.filename);
    annotationFilename = append(name, ".txt");
    
    % get the annotation table set up (just using one annotator here)
    annotationPathRelative = append('ja-annotations\', annotationFilename);
    annotationTable = readElanAnnotation(annotationPathRelative, true);
    
    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, track.directory);
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
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
        utterancePredictions = predict(model, utterance);
        utterancePred(rowNum) = mean(utterancePredictions);
        yUtteranceBaseline = mode(utterancePredictions);
    end
    
    utterancePredRound = round(utterancePred); % threshold is 0.5
    utteranceActual = arrayfun(@labelToFloat, annotationTable.label);
    
    % display utterance info in a table
    disp(table(utterancePred, utterancePredRound, utteranceActual));

    % appending is ugly but isn't too slow here
    yUtterancePred = [yUtterancePred; utterancePred];
    yUtteranceActual = [yUtteranceActual; utteranceActual];
    
end

disp('Utterance-level:');
fprintf('Utterance MAE = %f\n', mae(yUtteranceActual, yUtterancePred));
fprintf('Baseline MAE = %f\n', mae(yUtteranceActual, yUtteranceBaseline));