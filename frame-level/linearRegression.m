% Linear regression

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

directory = 'C:\Users\nullv\OneDrive\Documents\GitHub\dissatisfaction-models\';

% get feature spec (mono.fss)
featureSpec = getfeaturespec(append(directory, "mono.fss"));


% get the track lists
trackListTrain = gettracklist(append(directory, "frame-level\train.tl"));
trackListDev = gettracklist(append(directory, "frame-level\dev.tl"));

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, directory, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, directory, featureSpec);

%%
linearModel = fitlm(Xtrain, yTrain);

coefficients = linearModel.Coefficients.Estimate;

[coefficientSorted, coeffSortedIdx] = sort(coefficients, 'descend');
nCoeffPrint = 5;
fprintf('Sorted coefficients in descending order. First %d coefficients:\n', nCoeffPrint);
for nCoeff = 1:nCoeffPrint
    coeff = coeffSortedIdx(nCoeff);
    coeffValue = coefficientSorted(nCoeff);
    fprintf('\tCoefficient %d with value %f\n', coeff, coeffValue);
end