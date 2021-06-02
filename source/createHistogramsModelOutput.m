% generateHistogramsModels.m
% save a histogram for the frame-level model's predictions on neutral 
% frames versus dissatisfied frames

% prepareData;

classNeutral = 0;
classDiss = 1;

XtrainNeutral = XtrainFrame(yTrainFrame==classNeutral, :);
XtrainDiss = XtrainFrame(yTrainFrame==classDiss, :);

XdevNeutral = XdevFrame(yDevFrame==classNeutral, :);
XdevDiss = XdevFrame(yDevFrame==classDiss, :);

XtestNeutral = XtestFrame(yTestFrame==classNeutral, :);
XtestDiss = XtestFrame(yTestFrame==classDiss, :);

% predict on train set
linearRegressor = fitlm(XtrainFrame, yTrainFrame);
predsNeutral = predict(linearRegressor, XtrainNeutral);
predsDiss = predict(linearRegressor, XtrainDiss);
genHistogramForModel(predsNeutral, predsDiss, ...
    'Linear regressor output (train set)');

% predict on dev set
predsNeutral = predict(linearRegressor, XdevNeutral);
predsDiss = predict(linearRegressor, XdevDiss);
genHistogramForModel(predsNeutral, predsDiss, ...
    'Linear regressor output (dev set)');

% predict on test set
predsNeutral = predict(linearRegressor, XtestNeutral);
predsDiss = predict(linearRegressor, XtestDiss);
genHistogramForModel(predsNeutral, predsDiss, ...
    'Linear regressor output (test set)');

function genHistogramForModel(predN, predD, modelName)

    % config
    NBINS = 32;
    BARCOLORN = '#1e88e5'; 
    BARCOLORD = '#fb8c00';
    IMAGEDIR = append(pwd, "\source\histograms-models\");
    
    if ~exist(IMAGEDIR, 'dir')
        mkdir(IMAGEDIR)
    end

    f = figure('Visible', 'off');

    % histogram for predictions on neutral frames
    hPredN = histogram(predN, NBINS);
    hPredN.FaceColor = BARCOLORN;

    hold on

    % histogram for predictions on dissatisfied frames
    hPredD = histogram(predD, NBINS);
    hPredD.FaceColor = BARCOLORD;

    % normalize the histograms so that all bar heights add to 1
    hPredN.Normalization = 'probability';
    hPredD.Normalization = 'probability';

    % adjust bars so that both plots align
    hPredN.BinWidth = hPredD.BinWidth;
    hPredN.BinEdges = hPredD.BinEdges;

    % add titles, axes labels, and legend
    titleText = modelName;
    title(titleText);
    ylabel('Probability');
    xlabel('Dissatisfaction bin');
    lgd = legend('neutral','dissatisfied');
    lgd.Location = 'best';
    
    % save image
    imageFilepath = append(IMAGEDIR, titleText, ".png");
    saveas(f, imageFilepath);
    fprintf('Saved histogram to %s\n', imageFilepath);
end