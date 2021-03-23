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
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, dirWorking, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, dirWorking, featureSpec);

%%
% train
model = fitlm(Xtrain, yTrain);
%%
% print coefficient info
coefficients = model.Coefficients.Estimate;

[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
nCoeffPrint = 5;
fprintf('Sorted coefficients in descending order. First %d coefficients:\n', nCoeffPrint);
for nCoeff = 1:nCoeffPrint
    coeff = coeffSortedIdx(nCoeff);
    coeffValue = coefficientSorted(nCoeff);
    fprintf('\tCoefficient %d with value %f\n', coeff, coeffValue);
end

% predict on the dev set
yPred = predict(model, Xdev);

% calculate mean absolute error
mae = mean(abs(yPred - yDev));
disp(['Mean Absolute Error = ', num2str(mae)]);