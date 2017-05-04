function f = fromMean(M,e)

E = tesp.compute.eccentricAnomaly.fromMean(M,e);
f = tesp.compute.trueAnomaly.fromEccentric(E,e);
f = mod(f,2*pi);