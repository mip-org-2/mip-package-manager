function result = parse_yaml(yamlText)
%PARSE_YAML   Minimal YAML parser for mip.yaml files.
%
% Supports: scalar key-value pairs, lists of scalars, lists of mappings,
% inline lists [a, b], quoted strings, booleans, and numbers.
%
% Args:
%   yamlText - YAML content as a string
%
% Returns:
%   result - MATLAB struct

lines = strsplit(yamlText, newline, 'CollapseDelimiters', false);

result = struct();
idx = 1;
while idx <= length(lines)
    [result, idx] = parseMapping(lines, idx, 0, result);
end

end


function [mapping, idx] = parseMapping(lines, idx, baseIndent, mapping)
% Parse a YAML mapping (key: value pairs) at a given indentation level.

if nargin < 4
    mapping = struct();
end

while idx <= length(lines)
    line = lines{idx};

    if isEmptyOrComment(line)
        idx = idx + 1;
        continue;
    end

    indent = countIndent(line);
    if indent < baseIndent
        return;
    end

    trimmed = strtrim(line);

    % List item at this level — not part of this mapping
    if startsWith(trimmed, '- ') || strcmp(trimmed, '-')
        return;
    end

    % Must be a key: value pair
    [key, valPart] = splitKeyValue(trimmed);
    if isempty(key)
        idx = idx + 1;
        continue;
    end

    if isempty(valPart)
        % Value is on subsequent indented lines
        [mapping.(key), idx] = parseBlockValue(lines, idx + 1, indent);
    elseif startsWith(valPart, '[')
        mapping.(key) = parseInlineList(valPart);
        idx = idx + 1;
    else
        mapping.(key) = parseScalar(valPart);
        idx = idx + 1;
    end
end

end


function [val, idx] = parseBlockValue(lines, idx, parentIndent)
% Parse a block value (list or mapping) that follows a key with no inline value.

nextIndent = findNextIndent(lines, idx);
if nextIndent < 0 || nextIndent <= parentIndent
    val = '';
    return;
end

nextLine = findNextLine(lines, idx);
nextTrimmed = strtrim(nextLine);
if startsWith(nextTrimmed, '- ')
    [val, idx] = parseList(lines, idx, nextIndent);
else
    [val, idx] = parseMapping(lines, idx, nextIndent);
end
end


function [lst, idx] = parseList(lines, idx, baseIndent)
% Parse a YAML list (sequence of - items).

lst = {};
while idx <= length(lines)
    line = lines{idx};

    if isEmptyOrComment(line)
        idx = idx + 1;
        continue;
    end

    indent = countIndent(line);
    if indent < baseIndent
        return;
    end

    trimmed = strtrim(line);
    if ~startsWith(trimmed, '- ')
        return;
    end

    itemVal = strtrim(trimmed(3:end));
    itemContentIndent = indent + 2;

    % Check if this is a key: value (mapping item) or a simple scalar
    [itemKey, itemValuePart] = splitKeyValue(itemVal);

    if isempty(itemKey)
        % Simple scalar list item: - value
        lst{end+1} = parseScalar(itemVal); %#ok<AGROW>
        idx = idx + 1;
    else
        % This list item is a mapping. Parse the first key, then collect
        % any sibling keys at itemContentIndent.
        entry = struct();
        idx = idx + 1;

        if isempty(itemValuePart)
            % "- key:" with block value on next lines
            [entry.(itemKey), idx] = parseBlockValue(lines, idx, itemContentIndent);
        elseif startsWith(itemValuePart, '[')
            entry.(itemKey) = parseInlineList(itemValuePart);
        else
            entry.(itemKey) = parseScalar(itemValuePart);
        end

        % Collect remaining sibling keys at itemContentIndent
        [entry, idx] = parseMapping(lines, idx, itemContentIndent, entry);

        lst{end+1} = entry; %#ok<AGROW>
    end
end

end


function [key, valPart] = splitKeyValue(s)
% Split a "key: value" string. Returns empty key if no colon found.
% Handles colons inside quoted values by only looking at the first colon.

colonIdx = find(s == ':', 1);
if isempty(colonIdx)
    key = '';
    valPart = '';
    return;
end

key = strtrim(s(1:colonIdx-1));
valPart = strtrim(s(colonIdx+1:end));
end


function val = parseScalar(s)
% Parse a scalar YAML value.

% Remove trailing comments (but not inside quotes)
if ~startsWith(s, '"') && ~startsWith(s, '''')
    hashIdx = find(s == '#', 1);
    if ~isempty(hashIdx) && hashIdx > 1 && s(hashIdx-1) == ' '
        s = strtrim(s(1:hashIdx-2));
    end
end

% Quoted string
if (startsWith(s, '"') && endsWith(s, '"')) || ...
   (startsWith(s, '''') && endsWith(s, ''''))
    val = s(2:end-1);
    return;
end

% Boolean
if strcmpi(s, 'true') || strcmpi(s, 'yes')
    val = true;
    return;
end
if strcmpi(s, 'false') || strcmpi(s, 'no')
    val = false;
    return;
end

% Null
if strcmpi(s, 'null') || strcmp(s, '~')
    val = [];
    return;
end

% Empty list
if strcmp(s, '[]')
    val = {};
    return;
end

% Number
num = str2double(s);
if ~isnan(num)
    val = num;
    return;
end

% Plain string
val = s;
end


function lst = parseInlineList(s)
% Parse an inline YAML list like [a, b, c].

s = strtrim(s);
if startsWith(s, '[') && endsWith(s, ']')
    s = s(2:end-1);
end
s = strtrim(s);
if isempty(s)
    lst = {};
    return;
end

parts = strsplit(s, ',');
lst = {};
for i = 1:length(parts)
    lst{end+1} = parseScalar(strtrim(parts{i})); %#ok<AGROW>
end
end


function n = countIndent(line)
n = 0;
for i = 1:length(line)
    if line(i) == ' '
        n = n + 1;
    else
        return;
    end
end
end


function tf = isEmptyOrComment(line)
trimmed = strtrim(line);
tf = isempty(trimmed) || startsWith(trimmed, '#');
end


function indent = findNextIndent(lines, idx)
% Find the indentation of the next non-empty, non-comment line.
indent = -1;
while idx <= length(lines)
    if ~isEmptyOrComment(lines{idx})
        indent = countIndent(lines{idx});
        return;
    end
    idx = idx + 1;
end
end


function line = findNextLine(lines, idx)
% Find the next non-empty, non-comment line.
line = '';
while idx <= length(lines)
    if ~isEmptyOrComment(lines{idx})
        line = lines{idx};
        return;
    end
    idx = idx + 1;
end
end
