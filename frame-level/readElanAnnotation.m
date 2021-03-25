% read frame-level annotations from default ELAN tab-delimited 
% export to MATLAB table

function annotationTable = readElanAnnotation(annotationFilepath, filter)
    importOptions = delimitedTextImportOptions( ...
        'Delimiter', {'\t'}, ...
        'VariableNames', {'tier', 'startTime', 'startTimeShort', 'endTime', 'endTimeShort', 'duration', 'durationShort', 'label'}, ...
        'VariableTypes', {'string', 'duration', 'duration', 'duration', 'duration', 'duration', 'duration', 'string'}, ...
        'SelectedVariableNames', {'tier', 'startTime', 'endTime', 'duration', 'label'}, ...
        'ConsecutiveDelimitersRule', 'join' ...
        );
    annotationTable = readtable(annotationFilepath, importOptions);
    
    % if filter argument was passed, delete rows with labels other than "n"
    % "nn" "d" or "dd"
    if filter
        toDelete = ismember(annotationTable.label, ["n" "nn" "d" "dd"]);
        annotationTable(~toDelete, :) = [];
    end
end

