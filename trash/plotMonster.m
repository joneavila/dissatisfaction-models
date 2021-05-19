plotDirectory = sprintf('%s\\monster-plots', pwd);
[status, msg, msgID] = mkdir(plotDirectory);

numFeatures = size(monster, 2);
for featureNum = 1:numFeatures
    disp(featureNum);
    figWidth = 1920;
    figHeight = 1080;
    fig = figure('visible', 'off', 'position', [0, 0, figWidth, figHeight]);
    x = (1:size(monster, 1)) * milliseconds(10);
    y = monster(:, featureNum);
    plot(x, y);
    title(sprintf('feature %d\n', featureNum));
    xlabel('time (seconds)');
    ylabel('feature value');
    exportgraphics(gca, sprintf('%s\\%d.jpg', plotDirectory, featureNum));
end