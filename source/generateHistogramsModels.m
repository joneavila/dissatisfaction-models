% generateHistogramsModels.m
% save a histogram for the various models' predictions on neutral frames
% versus dissatisfied frames

%% prepare data
prepareData;

% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = Xtrain(yTrain==0, :);
trainDissatisfied = Xtrain(yTrain==1, :);

devNeutral = Xdev(yDev==0, :);
devDissatisfied = Xdev(yDev==1, :);

% t-test will compare neutral and dissatisfied
N = [trainNeutral; devNeutral];
D = [trainDissatisfied; devDissatisfied];

%% linear regression

% predict on train set
linearRegressor = fitlm(Xtrain, yTrain);
predN = predict(linearRegressor, trainNeutral);
predD = predict(linearRegressor, trainDissatisfied);
genHistogramForModel(predN, predD, 'linear regression train');

% predict on dev set
predN = predict(linearRegressor, devNeutral);
predD = predict(linearRegressor, devDissatisfied);
genHistogramForModel(predN, predD, 'linear regression dev');

%% logistic regression

% predict on train set
coeffEstimates = mnrfit(Xtrain, yTrain+1);
pihat = mnrval(coeffEstimates, trainNeutral);
predN = pihat(:, 2);
pihat = mnrval(coeffEstimates, trainDissatisfied);
predD = pihat(:, 2);
genHistogramForModel(predN, predD, 'logistic regression train');

% predict on dev set
pihat = mnrval(coeffEstimates, devNeutral);
predN = pihat(:, 2);
pihat = mnrval(coeffEstimates, devDissatisfied);
predD = pihat(:, 2);
genHistogramForModel(predN, predD, 'logistic regression dev');

%% k-NN

% predict on train set
kNNmodel = fitcknn(Xtrain, yTrain);
predN = predict(kNNmodel, trainNeutral);
predD = predict(kNNmodel, trainDissatisfied);
genHistogramForModel(predN, predD, 'kNN train'); % TODO fix display bug

% predict on dev set
predN = predict(kNNmodel, devNeutral);
predD = predict(kNNmodel, devDissatisfied);
genHistogramForModel(predN, predD, 'kNN dev');