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
    spec = featureSpec(coeff);
    fprintf(fileID, '%2d | %f | %s\n', coeff, coeffValue, spec.abbrev);
end
fclose(fileID);
fprintf('Coefficient info saved to %s\n', outputFilename);

% function for mean absolute error
mae = @(A, B) (mean(abs(A - B)));

% let the regressor predict on the dev set
yPred = predict(model, Xdev);
regressorMae = mae(yDev, yPred);
disp(['Regressor MAE = ', num2str(regressorMae)]);

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);
baselineMae = mae(yDev, yBaseline);
disp(['Baseline MAE = ', num2str(baselineMae)]);
