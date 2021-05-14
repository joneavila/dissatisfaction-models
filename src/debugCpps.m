% debugCpps.m - test whether the new CPPS code fixes the NaN bug
% if there are no NaN in monster, then the new code has fixed the bug

trackListTrain = gettracklist('train-dialog.tl');
featureSpec = getfeaturespec('.\mono-extended.fss');

trackNum = 1;
track = trackListTrain{trackNum};

customerSide = 'l';
filename = track.filename;
trackSpec = makeTrackspec(customerSide, filename, '.\calls\');

[~, monster] = makeTrackMonster(trackSpec, featureSpec);

numNan = length(find(isnan(monster)));
fprintf('numNam=%d\n', numNan);