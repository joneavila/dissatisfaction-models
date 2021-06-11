% calculateCorrelations.m
prepareData;
X = [XtrainFrame; XdevFrame];
y = [yTrainFrame; yDevFrame];

numFeatures = size(X, 2);

% create an empty result table
varNames = {'featureAbbrev', 'pointBiserial', 'pearson'};
sz = [numFeatures length(varNames)];
varTypes = {'string', 'double', 'double'};
resultsTable = table('VariableNames', varNames, 'Size', sz, ...
    'VariableTypes', varTypes);

for featureNum = 1:numFeatures
    feature = featureSpec(featureNum);
    resultsTable{featureNum,1} = cellstr(feature.abbrev);
    resultsTable{featureNum,2} = pointbiserial(X(:,featureNum), y);
    resultsTable{featureNum,3} = pearson(X(:,featureNum), y);
end

function r = pointbiserial(x, y)

    % "To calculate r_pb, assume that the dichotomous variable Y has the 
    % two values 0 and 1. If we divide the data set into two groups, group 
    % 1 which received the value "1" on Y and group 2 which received the 
    % value "0" on Y, then the point-biserial correlation coefficient is 
    % calculated as follows: r = r = (M1 - M0) / sn * sqrt(n0 * n1 / n^2)"

    y = logical(y);

    % "where sn is the standard deviation used when data are available for
    % every member of the population"
    sn = std(x);

    % "M1 being the mean value on the continuous variable X for all data 
    % points in group 1, and M0 the mean value on the continuous variable X 
    % for all data points in group 2."
    M1 = mean(x(y));
    M0 = mean(x(~y));

    % "Further, n1 is the number of data points in group 1, n0 is the 
    % number of data points in group 2 and n is the total sample size."
    n1 = sum(y);
    n0 = sum(~y);
    n = length(y);

    r = (M1 - M0) / sn * sqrt(n0 * n1 / n^2);
end

function r = pearson(x, y)
    % https://www.mathworks.com/help/matlab/ref/corrcoef.html
    % "For two input arguments, R is a 2-by-2 matrix with ones along the 
    % diagonal and the correlation coefficients along the off-diagonal."
    R = corrcoef(x, y);
    r = R(1,2);
end