function float = labelToFloat(label)
    if strcmp(label, "n") || strcmp(label, "nn") || ...
            strcmp(label, "successful")
        float = 0;
    elseif strcmp(label, "d") || strcmp(label, "dd") || ...
            strcmp(label, "doomed_1") || strcmp(label, "doomed_2")
        float = 1;
    else
        error('labelToFloat: unknown label: "%s"\n', label);
    end    
end