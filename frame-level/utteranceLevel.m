%% utteranceLevel.m 
% Predict utterances using frame-level predictions. For each utterance in
% the dev set, the model predicts the mean of the predictions on the frames 
% in that utterance. The baseline predicts the most common annotation for
% all frames in the train set.

featureSpec = getfeaturespec('.\mono.fss');

trackListTrain = gettracklist(".\frame-level\train.tl");
trackListDev = gettracklist(".\frame-level\dev.tl");

useAllAnnotators = false;
[Xtrain, yTrain] = getXYfromTrackList(trackListTrain, featureSpec, useAllAnnotators);
[Xdev, yDev] = getXYfromTrackList(trackListDev, featureSpec, useAllAnnotators);

%%
model = fitlm(Xtrain, yTrain); % train regressor

yUtterancePred = [];
yUtteranceActual = [];

nTracks = size(trackListTrain, 2);
for trackNum = 1:nTracks
    
    track = trackListTrain{trackNum};
    fprintf("predicting on %s\n", track.filename)
    
    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(track.filename);
    annotationFilename = append(name, ".txt");
    
    % get the annotation table set up (just using one annotator here)
    annotationPathRelative = append('annotations\ja-annotations\', annotationFilename);
    annotationTable = readElanAnnotation(annotationPathRelative, true);
    
    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, track.filename, track.directory);
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    % for each utterance (row in annotation table) let the regressor 
    % predict on each frame of the utterance then make the average of 
    % those predictions the final prediction
    nUtterances = size(annotationTable, 1);
    utterancePred = zeros([nUtterances 1]);
    for rowNum = 1:nUtterances
        row = annotationTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        utterance = monster(frameStart:frameEnd, :);
        utterancePredictions = predict(model, utterance);
        utterancePred(rowNum) = mean(utterancePredictions);
    end
    
    utteranceActual = arrayfun(@labelToFloat, annotationTable.label);
    
    % display utterance info in a table
    disp(table(utterancePred, utteranceActual));

    % appending is ugly but isn't too slow here
    yUtterancePred = [yUtterancePred; utterancePred];
    yUtteranceActual = [yUtteranceActual; utteranceActual];
    
end
%%
yUtteranceBaseline = zeros(size(yUtteranceActual)); % TODO hardcoded 'neutral'

mae = @(A, B) (mean(abs(A - B)));
disp('Utterance-level:');
fprintf('Utterance MAE = %f\n', mae(yUtteranceActual, yUtterancePred));
fprintf('Baseline MAE = %f\n', mae(yUtteranceActual, yUtteranceBaseline));