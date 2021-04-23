% Frame-level k-NN
%% prepare the data
prepareData;

%% train
model = fitcknn(Xtrain, yTrain);

%% predict on the dev set
yPred = predict(model, Xdev);
%% fscore
% TODO update the fscore function to handle integers
threshold = 0.5;
yCompareLabel = arrayfun(@(x) floatToLabel(x, threshold), yCompare, ...
    'UniformOutput', false);
yPredLabel = arrayfun(@(x) floatToLabel(x, threshold), yPred, ...
    'UniformOutput', false);
classPositive = 'doomed';
classNegative = 'successful';
[score, precision, recall] = fScore(yCompareLabel, yPredLabel, ...
    classPositive, classNegative);
fprintf('f1score=%.3f, precision=%.3f, recall=%.3f\n', score, precision, recall);
%% more stats
mae = @(A, B) (mean(abs(A - B)));
mse = @(A, B) (mean((A - B) .^ 2));
fprintf('k-NN MAE = %f\n', mae(yPred, yCompare));
fprintf('k-NN MSE = %f\n', mse(yPred, yCompare));
