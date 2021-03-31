% linearRegression.m Frame-level linear regression model

%% prepare the data
trackListTrain = gettracklist('.\frame-level\train.tl');
trackListDev = gettracklist('.\frame-level\dev.tl');
trackListTest = gettracklist('.\frame-level\test.tl');

featureSpec = getfeaturespec('.\mono2.fss'); % TODO use final spec file

useAllAnnotators = false;

[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec, ...
    useAllAnnotators);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec, ...
    useAllAnnotators);
[Xtest, yTest] = getXYfromTrackList(trackListTest, featureSpec, ...
    useAllAnnotators);
%% train regressor
model = fitlm(Xtrain, yTrain);

%% save coefficient info to a text file
outputFilename = 'coefficients.txt';
fileID = fopen(outputFilename, 'w');
coefficients = model.Coefficients.Estimate;
coefficients(1) = []; % discard the first coefficient (intercept)
[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
fprintf(fileID, 'Coefficients in descending order with format:\n');
fprintf(fileID, 'coefficient, value, abbreviation\n');
for coeffNum = 1:length(coefficients)
    coeff = coeffSortedIdx(coeffNum);
    coeffValue = coefficientSorted(coeffNum);
    fprintf(fileID, '%2d | %f | %s\n', coeff, coeffValue, ...
        featureSpec(coeff).abbrev);
end
fclose(fileID);
fprintf('Coefficients saved to %s\\%s\n', pwd, outputFilename);

%%  predict on the dev set
yPred = predict(model, Xdev);

% the baseline always predicts dissatisfied (positive class)
yBaseline = ones([size(Xdev, 1), 1]);
%% print f1 score and more for different thresholds
thresholdMin = -0.25;
thresholdMax = 1.55;
thresholdStep = 0.05;

fprintf('min(yPred)=%.3f, max(yPred)=%.3f\n', min(yPred), max(yPred));
fprintf('thresholdMin=%.2f, thresholdMax=%.2f, thresholdStep=%.2f\n', thresholdMin, thresholdMax, thresholdStep);
fprintf('negative class ("successful") if <= threshold, else positive class ("doomed")\n');

thresholdDev = 0.5;
yDevLabel = arrayfun(@(x) floatToLabel(x, thresholdDev), yDev, 'UniformOutput', false);

nSteps = (thresholdMax - thresholdMin) / thresholdStep;
threshold = zeros([nSteps 1]);
precisionLinear = zeros([nSteps 1]);
precisionBaseline = zeros([nSteps 1]);

thresholdSel = thresholdMin;
for i = 1:nSteps
    thresholdSel = round(thresholdSel, 2);
    yPredLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), yPred, 'UniformOutput', false);
    yBaselineLabel = arrayfun(@(x) floatToLabel(x, thresholdSel), yBaseline, 'UniformOutput', false);
    [~, precLinear, ~] = fScore(yDevLabel, yPredLabel, 'doomed', 'successful');
    [~, precBaseline, ~] = fScore(yDevLabel, yBaselineLabel, 'doomed', 'successful');
    threshold(i) = thresholdSel;
    precisionLinear(i) = precLinear;
    precisionBaseline(i) = precBaseline;
    thresholdSel = thresholdSel + thresholdStep;
end
disp(table(threshold, precisionLinear, precisionBaseline));
%%
% mae = @(A, B) (mean(abs(A - B)));
% fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
% fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));