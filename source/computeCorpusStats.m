% corpusStats.m Print various stats for the corpus and annotations.
%% prepare the data
trackListTrain = gettracklist('.\frame-level\train.tl');
trackListDev = gettracklist('.\frame-level\dev.tl');
trackListTest = gettracklist('.\frame-level\test.tl');

featureSpec = getfeaturespec('.\mono.fss');
%% count neutral and dissatified frames in each set
% 'n' and 'nn' are the negative class (0), 'd' and 'dd' are the positive
% class (1)
trainNeutral = Xtrain(yTrain==0, :);
devNeutral = Xdev(yDev==0, :);
testNeutral = Xtest(yTest==0, :);

trainDissatisfied = Xtrain(yTrain==1, :);
devDissatisfied = Xdev(yDev==1, :);
testDissatisfied = Xtest(yTest==1, :);

% test will compare neutral frames to dissatisfied frames
N = [trainNeutral; devNeutral; testNeutral];
D = [trainDissatisfied; devDissatisfied; testDissatisfied];

%% find the min, max, and mean call durations
files = dir('calls/*.wav');
nFiles = size(files, 1);
callDurationSec = zeros([nFiles 1]);
for fileNum = 1:nFiles
    file = files(fileNum);
    [y,Fs] = audioread(file.name);
    callDurationSec(fileNum) = size(y, 1) / Fs;
end
callDurationMinSec = min(callDurationSec);
callDurationMaxSec = max(callDurationSec);
callDurationMeanSec = mean(callDurationSec);
fprintf('callDurationMinSec=%.2f, callDurationMaxSec=%.2f callDurationMeanSec=%.2f\n', callDurationMinSec, callDurationMaxSec, callDurationMeanSec);
%% count neutral and dissatified utterances in each set
printSetUtterancesStats(trackListTrain, "train");
printSetUtterancesStats(trackListDev, "dev");
printSetUtterancesStats(trackListTest, "test");

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
        annTable = readElanAnnotation(append('annotations\ja-annotations\', annFilename), true);
        
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