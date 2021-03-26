% tTest.m

featureSpec = getfeaturespec('mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");

[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec);

% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = Xtrain(yTrain==0, :);
trainDissatisfied = Xtrain(yTrain==1, :);
devNeutral = Xdev(yDev==0, :);
devDissatisfied = Xdev(yDev==1, :);

% test will compare neutral frames to dissatisfied frames
N = [trainNeutral; devNeutral];
D = [trainDissatisfied; devDissatisfied];

% resize either matrix so they match in size
% note: this means X and Y may have a different number of speakers
if size(N, 1) > size(D, 1)
    N = N(1:size(D, 1), :);
elseif size(D, 1) > size(N, 1)
    D = D(1:size(N, 1), :);
end

% ttest2 documentation: https://www.mathworks.com/help/stats/ttest2.html

% "h = ttest2(x,y) returns a test decision for the null hypothesis that 
% the data in vectors x and y comes from independent random samples from 
% normal distributions with equal means and equal but unknown variances, 
% using the two-sample t-test. The alternative hypothesis is that the data 
% in x and y comes from populations with unequal means. The result h is 1 
% if the test rejects the null hypothesis at the 5% significance level, 
% and 0 otherwise."

% "Conduct test using the assumption that x and y are from normal 
% distributions with unknown and unequal variances."
[hypothesesTestResults, pValue, confidenceInterval, stats] = ...
    ttest2(N, D, 'Vartype', 'unequal');
rejectsNull = hypothesesTestResults == 1;
featureAbbrev = {featureSpec.abbrev};

% "p is the probability of observing a test statistic as extreme as, or 
% more extreme than, the observed value under the null hypothesis. Small 
% values of p cast doubt on the validity of the null hypothesis."

resultsTable = table(featureAbbrev', rejectsNull', pValue');
resultsTable.Properties.VariableNames = ...
    ["feature abbreviation", "rejects null?", "p-value"];
display(resultsTable);
