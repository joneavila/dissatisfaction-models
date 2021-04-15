% logisticRegression.m logisticRegression model

featureSpec = getfeaturespec('.\mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");
%%
useAllAnnotators = false;
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);

%% train regressor

% add 1 so that the 0 and 1 annotations all become positive and it works with the mnrfit function
coeffEstimates = mnrfit(Xtrain, yTrain+1);

% mnrval returns the predicted probabilities (0..1) for each class
pihat = mnrval(coeffEstimates, Xdev);
yPred = pihat(:, 2); % so just get the probabilities for dissatisfied class

mae = @(A, B) (mean(abs(A - B)));

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);

fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));