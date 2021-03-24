% visualize.m - save a histogram of each feature, use the train and dev set

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

dirWorking = append(pwd, "\");

% get feature spec (mono.fss)
featureSpec = getfeaturespec('mono.fss');

% get the track lists
trackListTrain = gettracklist("train.tl");
trackListDev = gettracklist("dev.tl");

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
N = [trainNeutral; devNeutral];
D = [trainDissatisfied; devDissatisfied];
%%
% save a histogram for each feature

% config
nBins = 30;
barColor = '#E1BEE7';

imageDir = append(pwd, "\frame-level\images\");
status = mkdir(imageDir);
if ~status
    error("Error creating image directory");
end

for featureNum = 1:size(featureSpec, 2)
    f = figure('Visible', 'off');
    h = histogram(N(:, featureNum), nBins);
    h.FaceColor = barColor;
    feature = featureSpec(featureNum);
    titleText = sprintf('feat%02d %s', featureNum, feature.abbrev);
    subtitleText = sprintf('neutral train+dev, nBins=%d', nBins);
    title(titleText, subtitleText);
    ylabel('Number in bin');
    xlabel('Bin');
    saveas(f, append(imageDir, titleText, ".png"));
    clf;
end
disp("done");

