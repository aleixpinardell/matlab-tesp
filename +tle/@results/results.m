classdef results < tesp.results
    
    properties (SetAccess=immutable)
        noradIdentifiers = []
        meanMotionFirstDerivatives = []
        meanMotionSecondDerivatives = []
        ballisticCoefficients = []
    end
    
    methods
        function obj = results(file)
            obj.columnIndexes = [2 0 0 0];  % Keplerian states at index 2, the rest not defined
            str = fileread(file);
            
            % LINE 1
            [~,tok] = regexp(str,'(?m)^1\s+(\d+)\S\s+\S+\s+(\d\d)(\S+)\s+(\S+)\s+(\S+)\s+(\S+)','match','tokens');
            m = length(tok);
            t = zeros(m,1);
            obj.noradIdentifiers = cell(m,1);
            ndot = zeros(m,1);
            ndotdot = zeros(m,1);
            Bstar = zeros(m,1);
            for j = 1:m
                obj.noradIdentifiers{j} = tok{j}{1};
                year_s = tesp.transform.timeToSeconds(str2double(tok{j}{2}),'sy');
                day_s = tesp.transform.timeToSeconds(str2double(tok{j}{3}),'d');
                t(j) = year_s + day_s;
                ndot(j) = str2double(tok{j}{4});
                ndotdot(j) = str2double([tok{j}{5}(1) '0.' tok{j}{5}(2:end-2) 'E' tok{j}{5}(end-1:end)]);
                Bstar(j) = str2double([tok{j}{6}(1) '0.' tok{j}{6}(2:end-2) 'E' tok{j}{6}(end-1:end)]);
            end
            obj.meanMotionFirstDerivatives = ndot*2*pi/tesp.constants.secondsInOne.day;
            obj.meanMotionSecondDerivatives = ndotdot*2*pi/tesp.constants.secondsInOne.day;
            obj.ballisticCoefficients = 2*Bstar/0.157;
            
            % LINE 2
            [~,tok] = regexp(str,'(?m)^2\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)',...
                'match','tokens','dotexceptnewline');
            i = zeros(m,1);
            raan = zeros(m,1);
            e = zeros(m,1);
            omega = zeros(m,1);
            M = zeros(m,1);
            n = zeros(m,1);
            for j = 1:m
                i(j) = str2double(tok{j}{1})*pi/180;
                raan(j) = str2double(tok{j}{2})*pi/180;
                e(j) = str2double(['0.' tok{j}{3}]);
                omega(j) = str2double(tok{j}{4})*pi/180;
                M(j) = str2double(tok{j}{5})*pi/180;
                n(j) = str2double(tok{j}{6}(1:10))*2*pi/tesp.constants.secondsInOne.day;
            end
            a = (tesp.constants.standardGravitationalParameter.earth./n.^2).^(1/3);
            obj.matrix = [t'; a'; e'; i'; omega'; raan'; M']';
        end
    end
    
end
