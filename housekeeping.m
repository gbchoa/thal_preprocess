%function D = Housekeeping

fs = filesep;

Fbase = 'C:\Users\Richard\Desktop\Rosch';
FScripts = [Fbase fs 'Scripts'];
FPhenotypes = [Fbase fs 'Phenotypes'];
Fspm = 'C:\Users\Richard\Desktop\spm';

% generating paths
addpath (genpath (FScripts));
addpath (Fspm);
spm ('defaults','fmri');
D.Fbase = Fbase;
D.FScripts = FScripts;
D.FPhenotypes = FPhenotypes;
