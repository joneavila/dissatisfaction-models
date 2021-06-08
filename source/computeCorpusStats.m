% corpusStats.m Print various stats for the corpus and annotations
%% prepare the data
prepareData;

%% count neutral and dissatified frames in each set
% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = XtrainDialog(yTrainDialog==0, :);
devNeutral = XdevDialog(yDevDialog==0, :);
testNeutral = XtestDialog(yTestDialog==0, :);

trainDissatisfied = XtrainDialog(yTrainDialog==1, :);
devDissatisfied = XdevDialog(yDevDialog==1, :);
testDissatisfied = XtestDialog(yTestDialog==1, :);

% combined totals
N = [trainNeutral; devNeutral; testNeutral];
D = [trainDissatisfied; devDissatisfied; testDissatisfied];

fprintf('train frames\n');
fprintf('\tneutral=%d, dissatisfied=%d\n', ...
    length(trainNeutral), length(trainDissatisfied));
fprintf('dev frames\n');
fprintf('\tneutral=%d, dissatisfied=%d\n', ...
    length(devNeutral), length(devDissatisfied));
fprintf('test frames\n');
fprintf('\tneutral=%d, dissatisfied=%d\n', ...
    length(testNeutral), length(testDissatisfied));
%% find the min, max, and mean call durations
% files = dir('calls/*.wav');
% nFiles = size(files, 1);
% callDurationSec = zeros([nFiles 1]);
% for fileNum = 1:nFiles
%     file = files(fileNum);
%     [y,Fs] = audioread(file.name);
%     callDurationSec(fileNum) = size(y, 1) / Fs;
% end
% callDurationMinSec = min(callDurationSec);
% callDurationMaxSec = max(callDurationSec);
% callDurationMeanSec = mean(callDurationSec);
% fprintf('callDurationMinSec=%.2f, callDurationMaxSec=%.2f callDurationMeanSec=%.2f\n', callDurationMinSec, callDurationMaxSec, callDurationMeanSec);

%% count neutral and dissatified utterances in each set
printSetUtterancesStats(tracklistTrainDialog, "train");
printSetUtterancesStats(tracklistDevDialog, "dev");
printSetUtterancesStats(tracklistTestDialog, "test");

function printSetUtterancesStats(trackList, displayName)
    
    fprintf('%s utterances\n', displayName);
    
    nNeutralUtter = 0;
    nSuperNeutralUtter = 0;
    nDissUtter = 0;
    nSuperDissUtter = 0;

    nTracks = size(trackList, 2);
   
    for trackNum = 1:nTracks
        track = trackList{trackNum};
        
        % get the annotation filename from the dialog filename, assuming
        % they have the same name
        [~, name, ~] = fileparts(track.filename);
        annFilename = append(name, ".txt");
        annTable = readElanAnnotation(append('annotations\', annFilename), true);
        
        nNeutralRows = size(annTable(annTable.label == "n", :), 1);
        nSuperNeutralRows = size(annTable(annTable.label == "nn", :), 1);
        nDissRows = size(annTable(annTable.label == "d", :), 1);
        nSuperDissRows = size(annTable(annTable.label == "dd", :), 1);
        
        nNeutralUtter = nNeutralUtter + nNeutralRows;
        nSuperNeutralUtter = nSuperNeutralUtter + nSuperNeutralRows;
        nDissUtter = nDissUtter + nDissRows;
        nSuperDissUtter = nSuperDissUtter + nSuperDissRows;

    end
    
    fprintf('\tneutral=%d (n=%d, nn=%d), dissatisfied=%d (d=%d, dd=%d)\n', ...
        nNeutralUtter + nSuperNeutralUtter, nNeutralUtter, nSuperNeutralUtter, ...
        nDissUtter + nSuperDissUtter, nDissUtter, nSuperDissUtter);
end