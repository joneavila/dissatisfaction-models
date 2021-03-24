% tTest

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

dirWorking = append(pwd, "\");

% get feature spec (mono.fss)
featureSpec = getfeaturespec('mono.fss');

% get the track lists
trackListTrain = gettracklist("train.tl");
trackListDev = gettracklist("dev.tl");
trackListTest = gettracklist("test.tl");

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, dirWorking, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, dirWorking, featureSpec);

%%
% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = Xtrain(yTrain==0, :);
trainDissatisfied = Xtrain(yTrain==1, :);

devNeutral = Xdev(yDev==0, :);
devDissatisfied = Xdev(yDev==1, :);

% t-test will compare neutral and dissatisfied
X = [trainNeutral; devNeutral];
Y = [trainDissatisfied; devDissatisfied];

% resize 'neutral' or 'dissatisfied' so they match in size
% note: this means X and Y might have a different number of speakers
if size(X, 1) > size(Y, 1)
    X = X(1:size(Y, 1), :);
elseif size(Y, 1) > size(X, 1)
    Y = Y(1:size(X, 1), :);
end
%%
% ttest2 documentation: https://www.mathworks.com/help/stats/ttest2.html
% "h = ttest2(x,y) returns a test decision for the null hypothesis that 
% the data in vectors x and y comes from independent random samples from 
% normal distributions with equal means and equal but unknown variances, 
% using the two-sample t-test. The alternative hypothesis is that the data 
% in x and y comes from populations with unequal means. The result h is 1 
% if the test rejects the null hypothesis at the 5% significance level, 
% and 0 otherwise."

% conduct the test assuming that X and Y are from normal distributions 
% (mean expectation is 0 and standard deviation is 1) with unknown and 
% unequal variances 
hypothesesTestResults = ttest2(X, Y, 'Vartype', 'unequal');
rejectsNull = find(hypothesesTestResults);

disp('The following features reject the null hypothesis:');
for i = 1:length(rejectsNull)
    feature = featureSpec(i);
    fprintf('#%d %s\n', i, feature.abbrev);
end
