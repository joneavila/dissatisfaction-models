% logisticRegression.m Frame-level linear regression model
%% prepare the data
prepareData;

%% train regressor

% add 1 to yTrain so that the 0 and 1 labels become positive (categorical)
coeffEstimates = mnrfit(Xtrain, yTrain + 1);

%% predict on the dev set

% pihat is the predicted probabilities (0..1) for each class
pihat = mnrval(coeffEstimates, Xdev);
yPred = pihat(:, 2); % probabilities of the dissatisfaction class (0..1)

%% baseline
% the baseline always predicts dissatisfied (positive class)
yBaseline = ones([size(Xcompare, 1), 1]);
%% print f1 score and more for different thresholds
thresholdMin = 0;
thresholdMax = 1;
thresholdStep = 0.05;

fprintf('thresholdMin=%.2f, thresholdMax=%.2f, thresholdStep=%.2f\n', ...
    thresholdMin, thresholdMax, thresholdStep);

thresholdCompare = 0.5;
yCompareLabel = arrayfun(@(x) floatToLabel(x, thresholdCompare), yCompare, ...
    'UniformOutput', false);

for threshold = thresholdMin:thresholdStep:thresholdMax
    yPredLabel = arrayfun(@(x) floatToLabel(x, threshold), yPred, ...
        'UniformOutput', false);
    yBaselineLabel = arrayfun(@(x) floatToLabel(x, threshold), ...
        yBaseline, 'UniformOutput', false);
    [scoRegressor, precRegressor, recRegressor] = fScore(yCompareLabel, ...
        yPredLabel, 'doomed', 'successful');
    [scoBaseline, precBaseline, recBaseline] = fScore(yCompareLabel, ...
        yBaselineLabel, 'doomed', 'successful');
    fprintf('threshold=%.2f\n', threshold);
    fprintf('\tprecision regressor=%.2f baseline=%.2f\n', precRegressor, precBaseline);
    fprintf('\trecall regressor=%.2f baseline=%.2f\n', recRegressor, recBaseline);
    fprintf('\tfscore regressor=%.2f baseline=%.2f\n', scoRegressor, scoBaseline);
end
%% print stats

mse = @(actual, pred) (mean((actual - pred) .^ 2));
% fprintf('Logistic regressor MSE = %f\n\n', mse(yCompare, yPred));
fprintf('Logistic regressor MSE = %f\n\n', mse(yTrain, yPred));