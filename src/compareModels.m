% compareModels.m
% Compare the linear and logsitic regression models when training and
% predicting on the train set and dev set
% This script requires you to save the models' predictions with the names 
% below and load them before running
% This code will be deleted at some point

comparisonTableTrain = table(yPredLinearOnTraining, ...
    yPredLogisticOnTraining, yTrain);

comparisonTableDev = table(yPredLinearOnDev, yPredLogisticOnDev, yDev);

mse = @(actual, pred) (mean((actual - pred) .^ 2));

fprintf('Linear regressor MSE on training   = %f\n', mse(yTrain, yPredLinearOnTraining));
fprintf('Logistic regressor MSE on training = %f\n', mse(yTrain, yPredLogisticOnTraining));

fprintf('Linear regressor MSE on dev   = %f\n', mse(yDev, yPredLinearOnDev));
fprintf('Logistic regressor MSE on dev = %f\n', mse(yDev, yPredLogisticOnDev));