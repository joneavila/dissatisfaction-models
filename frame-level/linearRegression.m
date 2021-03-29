% linearRegression.m Linear regression model

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
fprintf('Coefficients saved to %s\n', outputFilename);

mae = @(A, B) (mean(abs(A - B)));

% let the regressor predict on the dev set
yPred = predict(model, Xdev);

% the baseline predicts the majority class (the data is not balanced)
yBaseline = ones([size(Xdev, 1), 1]) * mode(yTrain);

disp('Frame-level:');
fprintf('Regressor MAE = %f\n', mae(yDev, yPred));
fprintf('Baseline MAE = %f\n', mae(yDev, yBaseline));

