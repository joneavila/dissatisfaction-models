% Frame-level k-NN

% add necessary files to path
addpath(genpath('midlevel-master'));
addpath(genpath('calls'));

% get feature spec (mono.fss)
featureSpec = getfeaturespec('mono.fss');
dirWorking = append(pwd, "\");

% get the track lists
trackListTrain = gettracklist("train.tl");
trackListDev = gettracklist("dev.tl");

% get X (monster regions) and Y (labels)
[Xtrain, yTrain] = getXYforTrackforTrackList(trackListTrain, dirWorking, featureSpec);
[Xdev, yDev] = getXYforTrackforTrackList(trackListDev, dirWorking, featureSpec);

% train
model = fitcknn(Xtrain, yTrain);

% predict on each frame in dev set (~1min)
yPred = predict(model, Xdev);

% count tp, fp, fn, and tn
% positive class is "d" or "dd", negative class is "n" or "nn"
% see getXYforTrack.m
tp = 0;
fp = 0;
fn = 0;
tn = 0;
for i = 1:size(Xdev, 1)
    
    labelPredicted = yPred(i);
    labelActual = yDev(i);
    
    if labelPredicted == 1
        if labelActual == 1
            tp = tp + 1;
        elseif labelActual == 0
            fp = fp + 1;
        end
    elseif labelPredicted == 0
        if labelActual == 1
            fn = fn + 1;
        elseif labelActual == 0
            tn = tn + 1;
        end
    end
end
total = tp + fp + fn + tn;
if total < length(trackListDev)
    error('(tp + fp + fn + tn) is less than the number of tracks')
end

% calculate f score
precision = tp / (tp + fp);
recall = tp / (tp + fn);
beta = 1; % f1 if b=1
fScore = ((beta^2 + 1) * precision * recall) / (beta^2 * precision + recall);
disp(['F-score = ', num2str(fScore)]);

% calculate mean absolute error
mae = mean(abs(yPred - yDev));
disp(['Mean Absolute Error = ', num2str(mae)]);
