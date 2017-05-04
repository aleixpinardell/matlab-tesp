function lifetimes = modifiedLifetimeGradient(lifetimes)

[n,m] = size(lifetimes);
lts = lifetimes;
for i = 1:m
    for j = 1:n
        closeNeighbours = [];
        farNeighbours = [];
        for ii = i-1:i+1
            for jj = j-1:j+1
                try
                    lltt = lts(jj,ii);
                    if ii ~= i && jj ~= j           % different row and column
                        farNeighbours = [farNeighbours lltt];
                    elseif ~(ii == i && jj == j)    % exclude self
                        closeNeighbours = [closeNeighbours lltt];
                    end
                catch
                end
            end
        end
        lt = lifetimes(j,i);
        mlg = max( max(abs(farNeighbours - lt))/sqrt(2), max(abs(closeNeighbours - lt)) );
        lifetimes(j,i) = mlg;
        %lifetimes(j,i) = max(mlg,0.6*mean(neighbours) + 0.4*max(neighbours));
    end
end
