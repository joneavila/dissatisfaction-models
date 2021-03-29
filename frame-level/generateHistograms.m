% generateHistograms.m Save a histogram of each feature in feature spec. 
% Use the train and dev set.

featureSpec = getfeaturespec('.\mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec);

% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = Xtrain(yTrain==0, :);
trainDissatisfied = Xtrain(yTrain==1, :);

devNeutral = Xdev(yDev==0, :);
devDissatisfied = Xdev(yDev==1, :);

% t-test will compare neutral and dissatisfied
N = [trainNeutral; devNeutral];
D = [trainDissatisfied; devDissatisfied];

%% save a histogram for each feature

% config
nBins = 32;
barColorN = '#1e88e5'; % blue
barColorD = '#fb8c00'; % orange

imageDir = append(pwd, "\frame-level\histograms\");
status = mkdir(imageDir);
if ~status
    error("Error creating image directory");
end

% documentation on plotting mulitple histograms: 
% https://www.mathworks.com/help/matlab/ref/matlab.graphics.chart.primitive.histogram.html#buiynvy-13
for featureNum = 1:size(featureSpec, 2)
    
    f = figure('Visible', 'off');
    
    % histogram for neutral
    hN = histogram(N(:, featureNum), nBins);
    hN.FaceColor = barColorN;
    
    hold on
   
    % histogram for dissatisfied
    hD = histogram(D(:, featureNum), nBins);
    hD.FaceColor = barColorD;
    
    % normalize the histograms so that all bar heights add to 1
    hN.Normalization = 'probability';
    hD.Normalization = 'probability';
    
    % adjust bars so that both plots align
    hN.BinWidth = hD.BinWidth;
    hN.BinEdges = hD.BinEdges;
    
    % add titles, axes labels, and legend
    feature = featureSpec(featureNum);
    titleText = sprintf('feat%02d %s (normalized)', featureNum, feature.abbrev);
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
disp("Done");

