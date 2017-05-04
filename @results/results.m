classdef results
    
    properties (SetAccess=protected)
        initialEpoch = []
        propagationTime = []
        computationTime = []
        matrix = []
    end
    
    properties (Hidden)
        columnIndexes = [0 0 0 0]
    end
    
    properties (Dependent, SetAccess=immutable)
        epochs
        lifetime
        keplerianStates
        cartesianStates
        sunPositions
        moonPositions
    end
    
    methods
        function obj = results(file)
            if nargin > 0
                % Read output file
                if isempty(strfind(file,'.'))
                    file = [file '.tespout'];
                elseif isempty(strfind(file,'.tespout'))
                    error('The provided file must have "tespout" extesion.')
                end
                resultsText = fileread(file);
                
                % Initial epoch
                [~,tok] = regexp(resultsText,'INITIAL_EPOCH\s+?(\S+)','match','tokens');
                if ~isempty(tok)
                    obj.initialEpoch = str2double(tok{1}{1});
                end
                
                % Propagation time
                [~,tok] = regexp(resultsText,'PROPAGATION_TIME\s*=\s*(.+?)\s+','match','tokens');
                if ~isempty(tok)
                    obj.propagationTime = str2double(tok{1}{1});
                end
                
                % Computation time
                [~,tok] = regexp(resultsText,'COMPUTATION_TIME\s*=\s*(.+?)\s+','match','tokens');
                if ~isempty(tok)
                    obj.computationTime = str2double(tok{1}{1});
                end
                
                % Determine what is each column
                c = 2;  % Index of the first column (after the epoch) that may contain results
                if ~isempty(regexp(resultsText,'OUTPUT_BODY_KEPLERIAN_STATE\s+YES','once')) || ...
                        ~isempty(strfind(resultsText,'BODY SEMIMAJOR AXIS'))
                    obj.columnIndexes(1) = c;
                    c = c + 6;
                end
                if ~isempty(regexp(resultsText,'OUTPUT_BODY_CARTESIAN_STATE\s+YES','once')) || ...
                        ~isempty(strfind(resultsText,'BODY POSITION X'))
                    obj.columnIndexes(2) = c;
                    c = c + 6;
                end
                if ~isempty(regexp(resultsText,'OUTPUT_SUN_POSITION\s+YES','once')) || ...
                        ~isempty(strfind(resultsText,'SUN POSITION X'))
                    obj.columnIndexes(3) = c;
                    c = c + 3;
                end
                
                if ~isempty(regexp(resultsText,'OUTPUT_MOON_POSITION\s+YES','once')) || ...
                        ~isempty(strfind(resultsText,'MOON POSITION X'))
                    obj.columnIndexes(4) = c;
                    c = c + 3;
                end
                
                % Parse results matrix
                [~,tok] = regexp(resultsText,'RESULTS\s*=\s*(.+)','match','tokens');
                obj.matrix = str2num(tok{1}{1});
            end
        end
        
        % Getters
        function val = get.epochs(obj)
            val = obj.matrix(:,1);
        end
        
        function val = get.lifetime(obj)
            val = tesp.transform.secondsTo(obj.epochs(end) - obj.initialEpoch, 'years');
        end
        
        function val = get.keplerianStates(obj)
            c = obj.columnIndexes(1);
            if c > 0
                val = obj.matrix(:,c:c+6-1);
            else
                error('Keplerian states not available.');
            end
        end
        
        function val = get.cartesianStates(obj)
            c = obj.columnIndexes(2);
            if c > 0
                val = obj.matrix(:,c:c+6-1);
            else
                error('Cartesian states not available.');
            end
        end
        
        function val = get.sunPositions(obj)
            c = obj.columnIndexes(3);
            if c > 0
                val = obj.matrix(:,c:c+3-1);
            else
                error('Sun positions not available.');
            end
        end
        
        function val = get.moonPositions(obj)
            c = obj.columnIndexes(4);
            if c > 0
                val = obj.matrix(:,c:c+3-1);
            else
                error('Moon positions not available.');
            end
        end
        
    end
    
end
