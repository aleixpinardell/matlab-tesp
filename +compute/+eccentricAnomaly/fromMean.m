function E = fromMean(M,e)

E = M;
for i = 1:10
    E = M + e.*sin(E);
end
E = mod(E,2*pi);