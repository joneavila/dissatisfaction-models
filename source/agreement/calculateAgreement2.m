% calculateAgreement2.m

% this tracklist has all 18 tracks
% try a tracklist excluding tracks in the train set next
tracksAll = [
    "20201229-aa-5f6b70d050d8b206c64e4ba1-tire-y-y.txt"
    "20210112-jl-5d67b4c31e367a0017273ecb-pet-n-n.txt"
    "20210112-sf-5e2cf87d49436731eac78e46-cable-n-n.txt"
    "20210114-ja-5e9d5b3a9a4acf0009ff70cc-console-n-n.txt"
    "20210114-ja-5f46aa41d1c4910597680a40-console-n-n.txt"
    "20210115-aa-5f2fad64d1609e000b157ba5-magician-y-y.txt"
    "20210118-aa-5e8b62e78dddff0287b5dd7d-wall-n-n.txt"
    "20210118-aa-5ec3c753622b97236b9e6796-wall-n-n.txt"
    "20210118-ja-5e8b62e78dddff0287b5dd7d-tire-n-n.txt"
    "20210118-ja-5eb350c50f432115af792bf9-tire-n-n.txt"
    "20210118-sf-5c51b4d014aa5000015523f0-lawn-y-y.txt"
    "20210118-sf-5e8b62e78dddff0287b5dd7d-lawn-y-y.txt"
    "20210122-jl-5fa2e888f2ec2d41c1faf2d1-tire-y-y.txt"
    "20210126-aa-5ecc4a93243b34435985b392-console-y-y.txt"
    "20210128-jl-5f3528bbed7b4d2df5cf0c4b-tire-y-y.txt"
    "20210202-jl-5e4a2f23f64db74915406236-magician-y-y-second.txt"
    "20210202-jl-5e4a2f23f64db74915406236-magician-y-y.txt"
    "20210204-jl-5eb5c2051cabb149a0636117-magician-n-n.txt"
];

% Remove tracks in the train set and run
% tracksAll = [
%     "20201229-aa-5f6b70d050d8b206c64e4ba1-tire-y-y.txt"
%     "20210112-jl-5d67b4c31e367a0017273ecb-pet-n-n.txt"
%     "20210112-sf-5e2cf87d49436731eac78e46-cable-n-n.txt"
%     "20210114-ja-5e9d5b3a9a4acf0009ff70cc-console-n-n.txt"
%     "20210114-ja-5f46aa41d1c4910597680a40-console-n-n.txt"
%     "20210115-aa-5f2fad64d1609e000b157ba5-magician-y-y.txt"
%     "20210118-aa-5e8b62e78dddff0287b5dd7d-wall-n-n.txt"
%     "20210118-aa-5ec3c753622b97236b9e6796-wall-n-n.txt"
%     "20210118-ja-5e8b62e78dddff0287b5dd7d-tire-n-n.txt"
%     "20210118-ja-5eb350c50f432115af792bf9-tire-n-n.txt"
%     "20210118-sf-5c51b4d014aa5000015523f0-lawn-y-y.txt"
%     "20210118-sf-5e8b62e78dddff0287b5dd7d-lawn-y-y.txt"
%     "20210122-jl-5fa2e888f2ec2d41c1faf2d1-tire-y-y.txt"
%     "20210126-aa-5ecc4a93243b34435985b392-console-y-y.txt"
%     "20210128-jl-5f3528bbed7b4d2df5cf0c4b-tire-y-y.txt"
%     "20210202-jl-5e4a2f23f64db74915406236-magician-y-y-second.txt"
%     "20210202-jl-5e4a2f23f64db74915406236-magician-y-y.txt"
%     "20210204-jl-5eb5c2051cabb149a0636117-magician-n-n.txt"
% ];

raters = ["aa" "ad" "ja" "nw"];

numTracks = length(tracksAll);
numRaters = length(raters);

raterScores = [];

for trackNum = 1:numTracks
    annFilename = tracksAll(trackNum);
    fprintf('[%d/%d] %s\n', trackNum, numTracks, annFilename);
    
    % read the audio to get the duration
    [~, name, ~] = fileparts(annFilename);
    audioFilename = append(name, ".wav");
    [audioData, sampleRate] = audioread(append('calls\', audioFilename));
    durationSeconds = length(audioData) / sampleRate;
    
    numFrames = round(durationSeconds) * 100;
    
    % the first loop is to populate annotatedByRater
    annotatedByRater = zeros([numFrames numRaters]);
    for raterNum = 1:numRaters
        % fprintf('[%d/%d] %s\n', raterNum, numRaters, rater);
        rater = raters(raterNum);
        annTable = getAnnotationTable(rater, annFilename);
        frameAnnotations = getFrameAnnotations(numFrames, annTable);
        frameIsAnnotated = frameAnnotations >= 0;
        if length(frameIsAnnotated) > length(annotatedByRater)
            fprintf('\trater annotated non-existent frame\n');
        else
            annotatedByRater(:,raterNum) = frameIsAnnotated;
        end
    end
    
    % the second loop is to get the final scores
    % complete frame = frame annotated by all raters
    completeFramesIdx = all(annotatedByRater, 2);
    numCompleteFrames = nnz(completeFramesIdx);
    raterScoresTrack = zeros([numCompleteFrames numRaters]);
    for raterNum = 1:numRaters
        rater = raters(raterNum);
        annTable = getAnnotationTable(rater, annFilename);
        frameAnnotations = getFrameAnnotations(numFrames, annTable);
        raterScoresTrack(:,raterNum) = frameAnnotations(completeFramesIdx);   
    end
    
    raterScores = [raterScores; raterScoresTrack];
    
end

% agreement for all raters
calculateAgreement(raterScores);

% agreement for AA vs AD
raterScoresAAAD = raterScores(:,[2 1]);
calculateAgreement(raterScoresAAAD);

% agreement for JA vs AD
raterScoresJAAD = raterScores(:,[2 3]);
calculateAgreement(raterScoresJAAD);

% agreement for NW vs AD
raterScoresNWAD = raterScores(:,[2 4]);
calculateAgreement(raterScoresNWAD);

function annTable = getAnnotationTable(rater, annFilename)
    annPath = append('source\agreement\', rater, '-annotations\', annFilename);
    useFilter = true;
    annTable = readElanAnnotation(annPath, useFilter);
end

function frameAnnotations = getFrameAnnotations(numFrames, annTable)
    frameAnnotations = ones([numFrames 1]) * -1;
    numRows = size(annTable, 1);
    for rowNum = 1:numRows
        row = annTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        label = labelToFloat(row.label);
        frameAnnotations(frameStart:frameEnd) = label;
    end
end

function calculateAgreement(scores)
% "Each cell lists the number of raters who assigned the indicated (row) 
% subject to the indicated (column) category."
% There are M raters (columns of 'scores'), N subjects
% (rows of 'scores'), and two categories (neutral or dissatisfied).
    classNeutral = 0;
    classDiss = 1;
    countsNeutral = sum(scores == classNeutral, 2);
    countsDiss = sum(scores == classDiss, 2);
    x = [countsNeutral countsDiss];
    fleiss(x);
end