function [score, precision, recall] = fScore(yActual, yPred, classPositive, classNegative)
% FSCORE Assumes yActual and yPred are same size.

    tp = 0;
    fp = 0;
    fn = 0;
    tn = 0;
    
    for i = 1:length(yActual)
        
        predicted = yPred{i};
        actual = yActual{i};
        
        if isequal(predicted, classPositive)
            if isequal(actual, classPositive)
                tp = tp + 1;
            elseif isequal(actual, classNegative)
                fp = fp + 1;
            end
        elseif isequal(predicted, classNegative)
            if isequal(actual, classPositive)
                fn = fn + 1;
            elseif isequal(actual, classNegative)
                tn = tn + 1;
            end
        end
    end
    
    total = tp + fp + fn + tn;
    if total < length(yActual)
        error('(tp + fp + fn + tn) is less than the number of tracks')
    end
    
    %%
    % calculate f score
    precision = tp / (tp + fp);
    recall = tp / (tp + fn);
    beta = 1; % f1 if b=1
    if precision == 0 || recall == 0
        score = 0;
    else
        score = ((beta^2 + 1) * precision * recall) / (beta^2 * precision + recall);
    end
end