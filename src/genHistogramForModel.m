function genHistogramForModel(predN, predD, modelName)

    % config
    NBINS = 32;
    BARCOLORN = '#1e88e5'; 
    BARCOLORD = '#fb8c00';
    IMAGEDIR = append(pwd, "\src\histograms-models\");
    
    mkdir(IMAGEDIR);

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
    % hPredN.BinWidth = hPredD.BinWidth;
    % hPredN.BinEdges = hPredD.BinEdges;

    % add titles, axes labels, and legend
    titleText = modelName;
    subtitleText = sprintf('nBins=%d', NBINS);
    title(titleText, subtitleText);
    ylabel('Number in bin');
    xlabel('Bin');
    lgd = legend('neutral','dissatisfied');
    lgd.Location = 'best';
    
    % save image
    imageFilepath = append(IMAGEDIR, titleText, ".png");
    saveas(f, imageFilepath);
    fprintf('Saved regressor output histogram to %s\n', imageFilepath);
end