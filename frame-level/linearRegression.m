% linearRegression.m Frame-level linear regression model

featureSpec = getfeaturespec('.\mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");

useAllAnnotators = false;
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);

%% train regressor
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
fprintf('Coefficients saved to %s\\%s\n', pwd, outputFilename);

mae = @(A, B) (mean(abs(A - B)));

%%
% let the regressor predict on the dev set
%% TODO loop and print table with threshold values
yPred = predict(model, Xdev);

thresholdMin = -0.25;
thresholdMax = 1.55;
thresholdStep = 0.05;

fprintf('min(yPred)=%.3f, max(yPred)=%.3f\n', min(yPred), max(yPred));
fprintf('thresholdMin=%.2f, thresholdMax=%.2f, thresholdStep=%.2f\n', thresholdMin, thresholdMax, thresholdStep);
fprintf('negative class ("successful") if <= threshold, else positive class ("doomed")\n');
yDevLabel = arrayfun(@(x) floatToLabel(x, 0.5), yDev, 'UniformOutput', false);

nSteps = (thresholdMax - thresholdMin) / thresholdStep;
thresholds = zeros([nSteps 1]);
precisions = zeros([nSteps 1]);
recalls = zeros([nSteps 1]);
f1scores = zeros([nSteps 1]);

threshold = thresholdMin;
for i = 1:nSteps
    threshold = round(threshold, 2);
    yPredLabel = arrayfun(@(x) floatToLabel(x, threshold), yPred, 'UniformOutput', false);
    [score, precision, recall] = fScore(yDevLabel, yPredLabel, 'doomed', 'successful');
    thresholds(i) = threshold;
    precisions(i) = precision;
    recalls(i) = recall;
    f1scores(i) = score;
    threshold = threshold + thresholdStep;
end
disp(table(thresholds, precisions, recalls, f1scores));
%%

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);

disp('Frame-level:');
fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));
