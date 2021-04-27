% Frame-level k-NN
%% prepare the data
prepareData;

%% train
model = fitcknn(Xtrain, yTrain);

%% predict on the compare (dev or test) set
yPred = predict(model, Xcompare);
%% fscore

% Output as of April 27, 2021
% beta=0.25, fscore=0.281, precision=0.273, recall=0.524

threshold = 0.5;
yCompareLabel = arrayfun(@(x) floatToLabel(x, threshold), yCompare, ...
    'UniformOutput', false);
yPredLabel = arrayfun(@(x) floatToLabel(x, threshold), yPred, ...
    'UniformOutput', false);
classPositive = 'doomed';
classNegative = 'successful';

beta = 0.25;
[score, precision, recall] = fScore(yCompareLabel, yPredLabel, ...
    classPositive, classNegative, beta);
fprintf('beta=%.2f, fscore=%.3f, precision=%.3f, recall=%.3f\n', beta, score, precision, recall);

%% more stats

% Output as of April 27, 2021
% k-NN MAE = 0.480002
% k-NN MSE = 0.480002

mae = @(A, B) (mean(abs(A - B)));
mse = @(A, B) (mean((A - B) .^ 2));
fprintf('k-NN MAE = %f\n', mae(yPred, yCompare));
fprintf('k-NN MSE = %f\n', mse(yPred, yCompare));
