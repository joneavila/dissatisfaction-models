% calculateAgreement.m
% This script requires the Fleiss' kappa script found at:
%   https://www.mathworks.com/matlabcentral/fileexchange/15426-fleiss
%   Cardillo G. (2007)

%% Test the Fleiss' kappa script with an example.
% https://en.wikipedia.org/wiki/Fleiss%27_kappa#Worked_example
% In this example, k should equal 0.210.
x = [0 0 0 0 14; 
     0 2 6 4  2;
     0 0 3 5  6;
     0 3 9 2  0;
     2 2 8 1  1;
     7 7 0 0  0;
     3 2 6 3  0;
     2 5 3 2  2;
     6 5 2 1  0;
     0 2 2 3  7];
fleiss(x);

%% Calculate the agreement between model predictions and human labels.
prepareData;
model = fitlm(XtrainFrame, yTrainFrame);

% The negative class is 0, or neutral, and the positive class is 1, or 
% dissatisfied. 

% The model's ratings are its predictions on the dev set, after applying 
% the dissatisfaction threshold found in linearRegressionFrame.m (on the 
% dev set).
yPred = predict(model, XdevFrame);
dissThreshold = 0.953;
ratingsModel = yPred >= dissThreshold;

% The human's ratings are the annotations.
ratingsHuman = yDevFrame;

% "Each cell lists the number of raters who assigned the indicated (row) 
% subject to the indicated (column) category."
% There are two raters (model and human), tens of thousands of subjects
% (frames in the set), and two categories (neutral or dissatisfied).

classNeutral = 0;
classDiss = 1;
ratingsBoth = [ratingsModel ratingsHuman];
countsNeutral = sum(ratingsBoth == classNeutral, 2);
countsDiss = sum(ratingsBoth == classDiss, 2);
x = [countsNeutral countsDiss];

fleiss(x);