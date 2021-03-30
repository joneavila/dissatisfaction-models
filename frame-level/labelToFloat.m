function float = labelToFloat(label)
    if strcmp(label, "n") || strcmp(label, "nn")
        float = 0;
    elseif strcmp(label, "d") || strcmp(label, "dd")
        float = 1;
    else
        error('unknown label encountered: "%s"\n', label);
    end
end