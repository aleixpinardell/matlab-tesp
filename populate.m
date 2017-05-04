% function populate(settingsFile,varargin)
clc; clear variables;

super = 'sensitivity';
super = 'optim';
folder = 'dsstSolarActivity';

varargin = {};
settingsFile = fullfile('/Volumes/TarDisk/Documents/Clase/MSc/Thesis/Thesis/gto_output/',super,folder,'settings');
printProgress = tesp.support.optionalArgument(1,'PrintProgress',varargin);
remoteHost = tesp.support.optionalArgument('eudoxos.lr.tudelft.nl','RemoteHost',varargin);
remoteUser = tesp.support.optionalArgument('aleix','RemoteUser',varargin);
remoteBin = tesp.support.optionalArgument(...
    '/home/aleix/tudatBundle/tudatApplications/bin/applications/tesp','RemoteBinary',varargin);
remoteUserDir = tesp.support.optionalArgument(['/home/' remoteUser],'RemoteUserDirectory',varargin);
localDepth = tesp.support.optionalArgument(3,'LocalDepth',varargin);
concurrentJobsLimit = tesp.support.optionalArgument(30,'ConcurrentPropagationsLimit',varargin);
skipInputFilesGeneration = tesp.support.optionalArgument(0,'SkipInputFilesGeneration',varargin);
generateServerPropateCommand = tesp.support.optionalArgument(1,'GenerateServerPropateCommand',varargin);
generateLocalPropateCommand = tesp.support.optionalArgument(0,'GenerateServerPropateCommand',varargin);

% Determine file system
warning('off','MATLAB:MKDIR:DirectoryExists');
dc = '/'; % directory delimiter char
sdc = '/'; % directory delimiter char inside sprintf
if isempty(strfind(pwd,'/')) && ~isempty(strfind(pwd,'\'))
    dc = '\';
    sdc = '\\';
end

% Read settings file
settingsFile = appendExtension(settingsFile,'tespvar');
settingsText = fileread(settingsFile);

% Get directory and set as working directory
[dir,settingsFilename,~] = fileparts(settingsFile);
cd(dir);

% Determine remote directory
remoteDir = '';
dirParts = strsplit(dir,dc);
for i = 1:localDepth
    remoteDir = [remoteDir dirParts{end-localDepth+i}];
    if i < localDepth
        remoteDir = [remoteDir dc];
    end
end
remoteDir = fullfile(remoteUserDir,remoteDir);

% Remove comments (from character % until new line except when between '' or "")
settingsText = regexprep(settingsText,'(?<=^([^'']|''[^'']*'')*)%.*','','dotexceptnewline');

% Remove empty lines
settingsText = regexprep(settingsText,'\n*','\n');

% Find user-defined variables
udvNames = {};
udvCases = {};
udvBodies = {};
udvNameExp = '\s*\$((?:[a-z]|[A-Z]|_)+?(?:[0-9]|[a-z]|[A-Z]|_)+?)\>';
udvExp = [udvNameExp '\s*?\{(\s*?(?:''|").*?(?:''|")\s*?\{\s*?.*?\s*?\}\s*?)*\}'];
[~,tok] = regexp(settingsText,udvExp,'match','tokens');
for i = 1:length(tok)
    udvNames{i} = tok{1,i}{1};
    stringExp = '(?<quote>''|")(.*?)\k<quote>';
    [~,subtok] = regexp(tok{1,i}{2},[stringExp '\s*?\{(.*?)\}\s*?'],'match','tokens');
    for j = 1:length(subtok)
        udvCases{i}{j} = subtok{1,j}{2};
        udvBodies{i}{j} = regexprep(subtok{1,j}{3},'\n*','\n');
    end
end

% Remove user-defined variables from original text
settingsText = regexprep(settingsText,udvExp,'');

% Find parameters
stringRangeWarningID = 'MATLAB:colon:operandsNotRealScalar';
warning('off',stringRangeWarningID);
[varNames,varValues] = readParameters(settingsText);


% Iterate through stored variable values to find sprintf's
% Replace names with eval-able expressions, but not eval'ed yet
Mindexes = [];
Nindexes = [];
for i = 1:length(varValues)
    if ~isempty(strfind(varValues{i}{1},'sprintf'))
        % User-defined variable replacement
        [~,names] = regexp(varValues{i}{1},udvNameExp,'match','tokens');
        for k = 1:length(names)
            name = names{k}{1};
            found = 0;
            for kk = 1:length(udvNames)
                if strcmp(name,udvNames{kk})
                    found = 1;
                    break;
                end
            end
            if found
                varValues{i}{1} = strrep(varValues{i}{1},['$' name],sprintf('udvCases{%i}{index}',kk));
                Mindexes = [Mindexes kk];
            end
        end
        % TESP variable replacement
        [~,names] = getSprintfArguments(varValues{i}{1});
        for k = 1:length(names)
            name = names{k};
            found = 0;
            for kk = 1:length(varNames)
                if strcmp(name,varNames{kk})
                    found = 1;
                    break;
                end
            end
            if found
                varValues{i}{1} = strrep(varValues{i}{1},name,sprintf('varValues{%i}{index}',kk));
                Nindexes = [Nindexes kk];
            end
        end
    end
end

% These variables are supported by tespvar files but not by tespin files
% And output file tree/naming cannot be added to a shared file
tespvarVarNames = {'MAXIMUM_CONCURRENT_PROPAGATIONS','SHARED_INPUT_FILE_DIRECTORY_PATH',...
    'SHARED_INPUT_FILE_NAME','INPUT_FILES_PARENT_DIRECTORY_PATH','INPUT_FILES_DIRECTORY_TREE',...
    'INPUT_FILES_NAMING_PATTERN','OUTPUT_FILE_NAME'};

% Create shared input
sharedFileDir = getVariableNamed(varNames,varValues,'SHARED_INPUT_FILE_DIRECTORY_PATH','');
if ~isempty(sharedFileDir)
    mkdir(sharedFileDir);
end
sharedFileName = getVariableNamed(varNames,varValues,'SHARED_INPUT_FILE_NAME','shared');
sharedFilePath = fullfile(sharedFileDir,appendExtension(sharedFileName,'tespin'));
sfid = fopen(sharedFilePath,'w');
for i = 1:length(varNames)
    varName = varNames{i};
    % Check variable is not a tespvar variable
    if all(~strcmp(varName,tespvarVarNames))
        if length(varValues{i}) == 1
            if isempty(strfind(varValues{i}{1},'sprintf'))
                fprintf(sfid,'%s  %s\n',varName,varValues{i}{1});
            end
        end
    end
end
fclose(sfid);

% Create inputs parent directory
inputDir = getVariableNamed(varNames,varValues,'INPUT_FILES_PARENT_DIRECTORY_PATH','inputs');
mkdir(inputDir);

% Prepare for creating inputs directory tree
[tree,m] = getVariableNamed(varNames,varValues,'INPUT_FILES_DIRECTORY_TREE','');
[naming,n] = getVariableNamed(varNames,varValues,'INPUT_FILES_NAMING_PATTERN','{sprintf(''%s'',{''input''})}');
[treeText,treeParts] = getSprintfArguments(tree);
[namingText,namingParts] = getSprintfArguments(naming);
M = length(treeParts);
N = length(namingParts);
parts = [treeParts namingParts];
evalparts = strrep(parts,'{index}','');
lengths = zeros(1,M+N);
for i = 1:length(evalparts)
    evalparts{i} = eval(evalparts{i});
    lengths(i) = length(evalparts{i});
end

% Replace index in sprintf's with index(1), index(2), etc.
for i = 1:M+N
    mn = m;
    if i > M
        mn = n;
    end
    if ~isempty(mn)
        varValue = varValues{mn}{1};
        finds = strfind(varValue,'{index}');
        if ~isempty(finds)
            f = finds(1);
            varValue = [varValue(1:f-1) sprintf('{index(%i)}',i) varValue(f+7:end)];
            varValues{mn} = {varValue};
        end
    end
end

% Determine depth of tree (for including shared file as relative path ../../)
cdepth = length(strfind(inputDir,dc)) + ~isempty(inputDir);  % constant-name depth
vdepth = length(strfind(treeText,sdc)) + ~isempty(treeText);  % variable-name depth
depth = cdepth + vdepth;
sharedFileRelativePath = sharedFilePath;
for i = 1:depth
    sharedFileRelativePath = ['..' dc sharedFileRelativePath];
end

% Determine output tree
outputDir = getVariableNamed(varNames,varValues,'OUTPUT_DIRECTORY_PATH','outputs');
relativeOutputDir = outputDir;
for i = 1:depth
    relativeOutputDir = ['..' dc relativeOutputDir];
end

% Process user-defined variable's blocks
for i = 1:length(udvBodies)
    for j = 1:length(udvBodies{i})
        body = udvBodies{i}{j};
        [svn,svv] = readParameters(body);
        subvarNames{i}{j} = svn;
        subvarValues{i}{j} = svv;
    end
end

% Determine attached variables (one-to-one relationship)
attachIndexes = zeros(1,M+N);
[~,tok] = regexp(settingsText,'#ATTACH\s+(.+)','match','tokens','dotexceptnewline');
for i = 1:length(tok)
    [~,subtok] = regexp(tok{i}{1},'(\S+)','match','tokens');
    [~,attachIndex] = getVariableNamed(varNames,varValues,subtok{1}{1});
    attachLength = length(varValues{attachIndex});
    NattachIndex = find(Nindexes==attachIndex);
    for j = 2:length(subtok)
        [~,attachedIndex] = getVariableNamed(varNames,varValues,subtok{j}{1});
        attachedLength = length(varValues{attachedIndex});
        if attachedLength ~= attachLength
            error(['Could not attach variable %s (%g cases) to %s (%g cases). ' ...
                'Attached variables must have the same number of cases.'], ...
                varNames{attachedIndex},attachedLength,varNames{attachIndex},attachLength);
        end
        NattachedIndex = find(Nindexes==attachedIndex);
        attachIndexes(M + NattachedIndex) = M + NattachIndex;
    end
end

if ~skipInputFilesGeneration
    % Generate all input files
    index = ones(1,M+N);
    % Determine total number of files
    F = 1;
    for i = 1:length(lengths)
        if attachIndexes(i) == 0
            F = F * lengths(i);
        end
    end
    f = 1;  % current file counter
    progress = -1;
    while f <= F
        % Get path to current file
        if ~isempty(m)
            currentTree = eval(varValues{m}{1});
            currentDir = fullfile(inputDir,currentTree);
            mkdir(currentDir);
        else
            currentTree = '';
            currentDir = inputDir;
        end
        if ~isempty(n)
            currentFileName = eval(varValues{n}{1});
        else
            currentFileName = 'input';
        end
        currentFilePath = fullfile(currentDir,appendExtension(currentFileName,'tespin'));
        
        
        % Write file contents
        cfid = fopen(currentFilePath,'w');
        
        % include shared file
        fprintf(cfid,['#INCLUDE ''' sharedFileRelativePath '''\n\n']);
        
        % output directory and filename
        fprintf(cfid,['OUTPUT_DIRECTORY_PATH  ''' fullfile(relativeOutputDir,currentTree) '''\n']);
        outputFileName = getVariableNamed(varNames,varValues,'OUTPUT_FILE_NAME');
        if ~isempty(outputFileName)
            outputFileName = strrep(outputFileName,'$FILENAME',currentFileName);
            fprintf(cfid,['OUTPUT_FILE_NAME  ' outputFileName '\n']);
        end
        fprintf(cfid,'\n');
        
        % variable parameters
        I = 0;  % current index for user-defined variable
        for i = 1:M+N
            part = parts{i};
            if ~isempty(strfind(part,'udvCases'))
                % user-defined variables
                I = I + 1;
                subnames = subvarNames{I}{index(I)};
                for j = 1:length(subnames)
                    fprintf(cfid,[subnames{j} '  ' subvarValues{I}{index(I)}{j}{1} '\n']);
                end
                fprintf(cfid,'\n');
            else
                % tesp variables
                name = eval(strrep(strrep(parts{i},'varValues','varNames'),'{index}',''));
                value = evalparts{i}{index(i)};
                fprintf(cfid,[name '  ' value '\n']);
            end
        end
        
        fclose(cfid);
        
        
        if printProgress
            % Update progress
            new_progress = floor(f/F*100);
            update_progress = new_progress ~= progress;
            progress = new_progress;
            if update_progress
                clc; fprintf('%i%%\n',progress);
            end
        end
        
        % Update indexes for next iteration
        f = f + 1;
        j = M+N;
        while j > 0
            if attachIndexes(j) ~= 0
                % If variable is attached to another variable, go to next variable
                j = j - 1;
            else
                % If variable is not attached, increase it by one
                index(j) = index(j) + 1;
                if index(j) > lengths(j)
                    % If length has been exceeded, set it to 1 and go to next variable
                    index(j) = 1;
                    j = j - 1;
                else
                    % If length has not been exceeded, break the loop and start new file
                    j = 0;
                end
            end
        end
        % Make indexes of attached variable match with the indexes of the variables they are attached to
        for j = 1:M+N
            attachIndex = attachIndexes(j);
            if attachIndex ~= 0
                index(j) = index(attachIndex);
            end
        end
    end
end

% Save as .mat for later usage when generating plot
save(settingsFilename,'varNames','varValues');


%% Create the .command files to run the propagations (on the server)

jobLimit = ' ';
if concurrentJobsLimit > 0
    jobLimit = sprintf(' -j%g ',concurrentJobsLimit);
end

if generateServerPropateCommand
    % Upload input
    remoteUrl = [remoteUser '@' remoteHost];
    commandLineFile = fullfile(dir,'syncInput.command');
    fid = fopen(commandLineFile,'w');
    fprintf(fid,['ssh -t ' remoteUrl ' "mkdir -p ' remoteDir '"\n']);
    thingsToUpload = {sharedFilePath,[inputDir '/']};
    for i = 1:length(thingsToUpload)
        thingToUpload = thingsToUpload{i};
        fprintf(fid,['rsync -avhu ' fullfile(dir,thingToUpload) ...
            ' ' remoteUrl ':' fullfile(remoteDir,thingToUpload) ' --delete\n']);
    end
    fclose(fid);
    fileattrib(commandLineFile, '+x')

    % Propagate on sever
    commandLineFile = fullfile(dir,'propagate.command');
    fid = fopen(commandLineFile,'w');
    if isempty(inputDir)
        contantDirs = '.';
    else
        contantDirs = inputDir;
    end
    wildcard = '';
    for i = 1:vdepth
        wildcard = fullfile(wildcard,'.*');
    end
    wildcard = fullfile(wildcard,'.*[.]tespin');
    fprintf(fid,['ssh -t ' remoteUrl ' "' ...
        'tmux new-session -d -s gto_session ''' ...
        'cd ' remoteDir '; ' ...
        'find inputs -print | grep -i \\"' wildcard '\\" | sort | ' ...
        'parallel' jobLimit ...
        remoteBin ...
        '''' ...
        '"' ...
        '\n']);
    % fprintf(fid,'ssh -t aleix@eudoxos.lr.tudelft.nl "tmux attach"\n');
    fclose(fid);
    fileattrib(commandLineFile, '+x')

    % Download output
    commandLineFile = fullfile(dir,'syncOutput.command');
    fid = fopen(commandLineFile,'w');
    fprintf(fid,['mkdir ' fullfile(dir,outputDir) '\n']);
    fprintf(fid,['rsync -avhu ' remoteUrl ':' fullfile(remoteDir,outputDir) '/ ' ...
        fullfile(dir,outputDir) '/\n']);
    fclose(fid);
    fileattrib(commandLineFile, '+x')
end

% Propagate locally
if generateLocalPropateCommand
    commandLineFile = fullfile(dir,'propagateLocally.command');
    fid = fopen(commandLineFile,'w');
    if isempty(inputDir)
        contantDirs = '.';
    else
        contantDirs = inputDir;
    end
    wildcard = '';
    for i = 1:vdepth
        wildcard = fullfile(wildcard,'.*');
    end
    wildcard = fullfile(wildcard,'.*[.]tespin');
    fprintf(fid,['cd ' dir '; ' ...
        'find inputs -print | grep -i "' wildcard '" | sort | ' ...
        'parallel' jobLimit ' tesp ' ...
        '\n']);
    % fprintf(fid,'ssh -t aleix@eudoxos.lr.tudelft.nl "tmux attach"\n');
    fclose(fid);
    fileattrib(commandLineFile, '+x')
end

% end


%% Auxiliary functions

function [text,list] = getSprintfArguments(sprintfText)

text = '';
list = {};
try
    [~,tok] = regexp(sprintfText,'sprintf\(''(.*?)'',(.+?)\)','match','tokens');
    text = tok{1}{1};
    list = strsplit(tok{1}{2},',');
catch
end

end


function path = appendExtension(path,extension)

[~,~,ext] = fileparts(path);
ext = strrep(ext,'.','');
if isempty(ext)
    path = [path '.' extension];
elseif ~strcmp(ext,extension)
    error('Failed while appending extension %s. The file has extension %s.',extension,ext);
end

end


function [value,index] = getVariableNamed(names,values,name,default)

if nargin < 4
    value = [];
else
    value = default;
end
index = find(ismember(names,name));
if index
    value = values{index}{1};
end

end


function [varNames,varValues] = readParameters(text)

[~,tok] = regexp(text,'\<(\S+)\>\s+(.+)','match','tokens','dotexceptnewline');
j = 0;
for i = 1:length(tok)
    varName = tok{i}{1};
    varValue = tok{i}{2};
    if ~strcmp(varName(1),'#')  % check it's not a #KEYWORD
        j = j + 1;
        varNames{j} = varName;
        % Convert dates (or periods of time) to seconds since J2000 (or seconds)
        if any(strcmp(varName,{'INITIAL_EPOCH','END_EPOCH','PROPAGATION_PERIOD',...
                'INTEGRATOR_FIXED_STEPSIZE','INTEGRATOR_INITIAL_STEPSIZE'}))
            [~,subtok] = regexp(varValue,'''(.*?)''','match','tokens');
            for k = 1:length(subtok)
                try
                    inSeconds = tesp.transform.dateToEpoch(subtok{k}{1});
                catch
                    inSeconds = tesp.transform.timeToSeconds(subtok{k}{1});
                end
                varValue = strrep(varValue,['''' subtok{k}{1} ''''],sprintf('%.16f',inSeconds));
            end
        end
        try
            % Try to eval expression directly
            varValues{j} = eval(varValue);
            if isa(varValues{j},'char')
                varValues{j} = ['''' varValues{j} ''''];
            end
        catch
            % If it fails, store as string
            varValues{j}{1} = varValue;
        end
        varValues{j} = tesp.support.cellCompactFormat(varValues{j});
    end
end

end

