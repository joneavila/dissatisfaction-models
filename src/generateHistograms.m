% generateHistograms.m Save a histogram of each feature in feature spec. 
% Use the train and dev set.
%% prepare the data
prepareData;

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

% config
imageDir = append(pwd, "\frame-level\histograms\");
nBins = 32;
barColorN = '#1e88e5'; % blue
barColorD = '#fb8c00'; % orange

%% save a histogram for each feature

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
    titleText = sprintf('feat%02d %s', featureNum, feature.abbrev);
    subtitleText = sprintf('train+dev, nBins=%d, normalized bars', nBins);
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
disp("Saved all feature histograms");

%% save a histogram for the linear regressor's predictions on N and D

% linear 
regressor = fitlm(Xtrain, yTrain);
predN = predict(regressor, devNeutral);
predD = predict(regressor, devDissatisfied);
genHistogramForModel(predN, predD, 'linear regression dev');

% logistic
coeffEstimates = mnrfit(Xtrain, yTrain+1);
pihat = mnrval(coeffEstimates, devNeutral);
predN = pihat(:, 2);
pihat = mnrval(coeffEstimates, devDissatisfied);
predD = pihat(:, 2);
genHistogramForModel(predN, predD, 'logistic regression dev');



% linear 
regressor = fitlm(Xtrain, yTrain);
predN = predict(regressor, trainNeutral);
predD = predict(regressor, trainDissatisfied);
genHistogramForModel(predN, predD, 'linear regression train');

% logistic
coeffEstimates = mnrfit(Xtrain, yTrain+1);
pihat = mnrval(coeffEstimates, trainNeutral);
predN = pihat(:, 2);
pihat = mnrval(coeffEstimates, trainDissatisfied);
predD = pihat(:, 2);
genHistogramForModel(predN, predD, 'logistic regression train');


function genHistogramForModel(predN, predD, modelName)

    nBins = 32; % TODO use the global variables
    barColorN = '#1e88e5'; 
    barColorD = '#fb8c00';
    imageDir = append(pwd, "\src\histograms\");

    f = figure('Visible', 'off');

    % histogram for predictions on N
    hPredN = histogram(predN, nBins);
    hPredN.FaceColor = barColorN;

    hold on

    % histogram for predictions on D
    hPredD = histogram(predD, nBins);
    hPredD.FaceColor = barColorD;

    % normalize the histograms so that all bar heights add to 1
    hPredN.Normalization = 'probability';
    hPredD.Normalization = 'probability';

    % adjust bars so that both plots align
    hPredN.BinWidth = hPredD.BinWidth;
    hPredN.BinEdges = hPredD.BinEdges;

    % add titles, axes labels, and legend
    titleText = modelName;
    subtitleText = sprintf('Predictions on dev set, nBins=%d', nBins);
    title(titleText, subtitleText);
    ylabel('Number in bin');
    xlabel('Bin');
    legend('neutral','dissatisfied')

    % save image
    imageFilepath = append(imageDir, titleText, "-new.png");
    saveas(f, imageFilepath);
    fprintf('Saved regressor output histogram to %s\n', imageFilepath);
end