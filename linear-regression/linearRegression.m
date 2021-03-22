% Linear regression

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

% get feature spec (mono.fss)
featureSpec = getfeaturespec('mono.fss');
directory = 'C:\Users\nullv\OneDrive\Documents\GitHub\knn-models\';

% get the track lists
trackListTrain = gettracklist("train.tl");
trackListDev = gettracklist("dev.tl");

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYforTrackforTrackList(trackListTrain, directory, featureSpec);
[Xdev, yDev] = getXYforTrackforTrackList(trackListDev, directory, featureSpec);

model = fitlm(Xtrain, yTrain);

%% 
coefficients = model.Coefficients.Estimate;

[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
nCoeffPrint = 5;
fprintf('Sorted coefficients in descending order. First %d coefficients:\n', nCoeffPrint);
for nCoeff = 1:nCoeffPrint
    coeff = coeffSortedIdx(nCoeff);
    coeffValue = coefficientSorted(nCoeff);
    fprintf('\tCoefficient %d with value %f\n', coeff, coeffValue);
end