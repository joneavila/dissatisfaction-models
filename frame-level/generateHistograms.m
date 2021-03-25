% generateHistograms.m - save a histogram of each feature, use the train and dev set

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
nBins = 32;
barColorN = '#2196F3';
barColorD = '#FF9800';

imageDir = append(pwd, "\frame-level\images\");
status = mkdir(imageDir);
if ~status
    error("Error creating image directory");
end

for featureNum = 1:size(featureSpec, 2)
    
    f = figure('Visible', 'off');
    
    % histogram for neutral
    hN = histogram(N(:, featureNum), nBins);
    hN.FaceColor = barColorN;
    
    hold on
   
    % histogram for dissatisfied
    hD = histogram(D(:, featureNum), nBins);
    hD.FaceColor = barColorD;
    
    % add titles, axes labels, and legend
    feature = featureSpec(featureNum);
    titleText = sprintf('feat%02d %s', featureNum, feature.abbrev);
    subtitleText = sprintf('train+dev, nBins=%d', nBins);
    title(titleText, subtitleText);
    ylabel('Number in bin');
    xlabel('Bin');
    legend('neutral','dissatisfied')
    
    % save image
    imageFilepath = append(imageDir, titleText, ".png");
    saveas(f, imageFilepath);
    fprintf('Saved image to %s\n', imageFilepath);
    
    clf;
end
disp("done");

