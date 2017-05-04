function M = fromTrue(f,e)

E = tesp.compute.eccentricAnomaly.fromTrue(f,e);
M = tesp.compute.meanAnomaly.fromEccentric(E,e);
M = mod(M,2*pi);