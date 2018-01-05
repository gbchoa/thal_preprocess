function thal_glm_gen(sub)

spm('defaults', 'FMRI');
spmpath = which('spm');
seppos  = find(spmpath == filesep);
dir_spm = spmpath(1:seppos(end) - 1);

%% Define subject parameters and directories
%==========================================================================
% sub             = 'NDARAA536PTU';                                                 % Needs to change
fs              = filesep;      

dir_base        = 'C:\Users\Richard\Desktop\Rosch\Subjects';                    %% Needs to change
dir_functional  = [dir_base fs sub fs 'func'];
dir_struct      = [dir_base fs sub fs 'anat'];
dir_glm         = [dir_base fs sub fs 'glm'];
dir_masks       = [dir_base fs 'George' fs 'MNI'];

try mkdir(dir_glm); end;

% dir_site        = 'preprocessed_data';
% dir_tract       = [dir_base fs sub fs 'tracts'];

vols            = 420;                                                      % Number of scans in the big files
TR              = 0.72;                                                     % Check with the acquisition protocol 
hpf             = 128;                                                      % Check with acquisition protocol 

% Define desired processing steps
glm             = 1;
dct             = 1;
glm2            = 1;
voi             = 1;
dct             = 1;
two             = 0;      

%% Model Specification
%==========================================================================
if glm
   
cd(dir_functional);
f       = spm_select('ExtFPList', dir_functional, '^swr_u', Inf);    % This needs to exclude the mean image
files  = cellstr(f);

jobs{1}.spm.stats.fmri_spec.dir = {dir_functional};
jobs{1}.spm.stats.fmri_spec.timing.units = 'scans';
jobs{1}.spm.stats.fmri_spec.timing.RT = TR;         % Interscan Interval
jobs{1}.spm.stats.fmri_spec.timing.fmri_t = 16;     % Microtime resolution
jobs{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;     % Microtime onset

jobs{1}.spm.stats.fmri_spec.sess(1).scans = files;     
jobs{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
jobs{1}.spm.stats.fmri_spec.sess(1).multi = {''};
jobs{1}.spm.stats.fmri_spec.sess(1).regress.name = 'images';
jobs{1}.spm.stats.fmri_spec.sess(1).regress.val = [1:vols];
jobs{1}.spm.stats.fmri_spec.sess(1).multi_reg = {''};
jobs{1}.spm.stats.fmri_spec.sess(1).hpf = hpf;       

jobs{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
jobs{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
jobs{1}.spm.stats.fmri_spec.volt = 1;
jobs{1}.spm.stats.fmri_spec.global = 'None';
jobs{1}.spm.stats.fmri_spec.mask = {''};
jobs{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

% Model estimation definitions
%--------------------------------------------------------------------------
jobs{2}.spm.stats.fmri_est.spmmat = {[dir_functional fs 'SPM.mat']};
save modelestimation.mat jobs

% Run Jobs
%--------------------------------------------------------------------------
spm_jobman('run', jobs);
clear jobs;
end

% VOI extraction
%==========================================================================
if voi
area = {'frontal', 'occipital', 'parietal', 'postcentral', 'precentral', 'temporal'};
side = {'L', 'R'};
th_s = {'r', 'l'};

for a = 1:length(area)
for s = 1:length(side)
    cd (dir_functional)
    f  = spm_select('FPList', dir_functional, '^SPM.*\.mat$'); 

    jobs{1}.spm.util.voi.spmmat = {f};
    jobs{1}.spm.util.voi.adjust = 0;
    jobs{1}.spm.util.voi.session = 1;
    jobs{1}.spm.util.voi.name = [side{s} '_thal_' area{a}];
    jobs{1}.spm.util.voi.roi{1}.mask.image = {[dir_masks fs 'thal_masks' fs side{s} '_thal_' area{a} '.nii,1']};
    jobs{1}.spm.util.voi.roi{1}.mask.threshold = 0.5;
    jobs{1}.spm.util.voi.expression = 'i1';
 
    jobs{2}.spm.util.voi.spmmat = {f};
    jobs{2}.spm.util.voi.adjust = 0;
    jobs{2}.spm.util.voi.session = 1;
    jobs{2}.spm.util.voi.name = [side{s} '_cort_' area{a}];
    jobs{2}.spm.util.voi.roi{1}.mask.image = {[dir_masks fs 'cort_masks' fs side{s} '_' area{a} '.nii,1']};
    jobs{2}.spm.util.voi.roi{1}.mask.threshold = 0.5;
    jobs{2}.spm.util.voi.expression = 'i1';
  
    % Run Jobs
    %--------------------------------------------------------------------------
    spm_jobman('run', jobs);
    clear jobs;
end
end
end

%% DCT
%==========================================================================
if dct 

cd(dir_functional)
f           = spm_select('ExtFPList', dir_functional, '^swr_u', Inf); % Should exclude the mean image
scans       = cellstr(f);
n_scans     = length(scans);
Nyq_freq    = 1/(2*TR);
high_freq   = 0.1;
full_dct    = spm_dctmtx(n_scans,n_scans);

% Calculate lower limit components & remove
%--------------------------------------------------------------------------
n_hpf_freq                  = fix(2*(n_scans*TR)/hpf+1);
full_dct(:,1:n_hpf_freq)    = [];       % removes lowest frequency colums

% Calculate upper limit components & remove
%--------------------------------------------------------------------------
n_high_freq                 = fix(2*(n_scans*TR)/(1/high_freq)+1);
full_dct(:,n_high_freq:end) = [];       % removes freq > upper limit
[n_dct_rows,n_dct_cols]     = size(full_dct);

% Integrate into nuissance matrix
%--------------------------------------------------------------------------
f           = spm_select('FPList', dir_functional, '^rp.*\.txt$');
multi_regs  = cellstr(f);
mvmnt       = load(multi_regs{1},'-ascii');

area = {'frontal', 'occipital', 'parietal', 'postcentral', 'precentral', 'temporal'};

for a = 1:length(area)
    load(['VOI_L_cort_' area{a} '_1.mat']); Ys = Y;
    VOI.L.cort{a} = Ys; clear Ys Y
    load(['VOI_L_thal_' area{a} '_1.mat']); Ys = Y;
    VOI.L.thal{a} = Ys; clear Ys Y
    
    load(['VOI_R_cort_' area{a} '_1.mat']); Ys = Y;
    VOI.R.cort{a} = Ys; clear Ys Y
    load(['VOI_R_thal_' area{a} '_1.mat']); Ys = Y;
    VOI.R.thal{a} = Ys; clear Ys Y
end

GLM = [ full_dct, ...
        VOI.L.thal{1:length(area)}, ...
        VOI.L.cort{1:length(area)}, ...
        VOI.R.thal{1:length(area)}, ...
        VOI.R.cort{1:length(area)}, ...
        mvmnt ];

cd(dir_glm)
dlmwrite('GLM.txt',GLM, '\t');
DesMtx = fullfile(dir_glm, 'GLM.txt');

% Calculate the contrasts to test
f_all_freq = (eye(n_dct_cols));
end
%    
if glm2   

cd(dir_glm)

jobs{1}.spm.stats.fmri_spec.dir = {dir_glm};
jobs{1}.spm.stats.fmri_spec.timing.units = 'scans';
jobs{1}.spm.stats.fmri_spec.timing.RT = TR;
jobs{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
jobs{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;


jobs{1}.spm.stats.fmri_spec.sess.scans = scans;
jobs{1}.spm.stats.fmri_spec.sess.cond = {''};
jobs{1}.spm.stats.fmri_spec.sess.multi = {''};

f = []; files = [];

jobs{1}.spm.stats.fmri_spec.sess.multi_reg = {DesMtx};
jobs{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});

jobs{1}.spm.stats.fmri_spec.sess.hpf = hpf;
jobs{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
jobs{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
jobs{1}.spm.stats.fmri_spec.volt = 1;
jobs{1}.spm.stats.fmri_spec.global = 'Scaling';
jobs{1}.spm.stats.fmri_spec.mthresh = 0.8;
jobs{1}.spm.stats.fmri_spec.mask = {''};
jobs{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

% MODEL ESTIMATION
%--------------------------------------------------------------------------
jobs{2}.spm.stats.fmri_est.spmmat = {[dir_glm fs 'SPM.mat']};

% CONTRAST MANAGER
%--------------------------------------------------------------------------
jobs{3}.spm.stats.con.spmmat = {[dir_glm fs 'SPM.mat']};

jobs{3}.spm.stats.con.consess{1}.fcon.name   = 'All_freq';
jobs{3}.spm.stats.con.consess{1}.fcon.convec = {f_all_freq}; 
jobs{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';

jobs{3}.spm.stats.con.delete = 0;

spm_jobman('run',jobs);
clear jobs   

end
end
