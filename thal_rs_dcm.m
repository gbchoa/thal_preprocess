function thal_rs_dcm(sub)
%% Housekeeping
%==========================================================================
spm('defaults', 'FMRI');
dir_spm         = 'D:\My Documents\MATLAB\tools\spm';

% subject-specific variables 
%--------------------------------------------------------------------------

% Define subject parameters and directories
%==========================================================================
fs              = filesep;       % platform-specific file separator
dir_base        = 'D:\Research_Data\HCP_Data\rsAnalysis_MNI';
dir_functional  = [dir_base fs sub fs 'func'];
dir_struct      = [dir_base fs sub fs 'anat'];
% dir_tract       = [dir_base fs sub fs 'tracts']; 
dir_glm         = [dir_base fs sub fs 'glm'];
dir_dcm         = [dir_base fs sub fs 'dcm'];
if ~exist(dir_dcm, 'dir'), mkdir(dir_dcm); end;

vols            = 420;
TR              = 0.72;
RT              = TR;
hpf             = 128;


% Specify DCM
%==========================================================================
clear DCM;
cd(dir_functional)

% ROIs
area    = {'frontal', 'occipital', 'parietal', 'postcentral', 'precentral', 'temporal'};
side    = {'L', 'R'};

for a = 1 :length(area)
for s = 1 :length(side)
    load(['VOI_' side{s} '_cort_' area{a} '_1.mat']);
    DCM.xY(2) = xY;
    
    load(['VOI_' side{s} '_thal_' area{a} '_1.mat']);
    DCM.xY(1) = xY;


% Metadata
%--------------------------------------------------------------------------
v = length(DCM.xY(1).u); % number of time points
n = length(DCM.xY);      % number of regions

DCM.v = v;
DCM.n = n;

% Timeseries
%--------------------------------------------------------------------------
DCM.Y.dt  = TR;
DCM.Y.X0  = DCM.xY(1).X0;
DCM.Y.Q   = spm_Ce(ones(1,n)*v);
for i = 1:DCM.n
    DCM.Y.y(:,i)  = DCM.xY(i).u;
    DCM.Y.name{i} = DCM.xY(i).name;
end

% Task inputs
%--------------------------------------------------------------------------
DCM.U.u    = zeros(v,1);
DCM.U.name = {'null'};         

% Connectivity
%--------------------------------------------------------------------------
DCM.a  = ones(n,n);
DCM.b  = zeros(n,n,0);
DCM.c  = zeros(n,0);
DCM.d  = zeros(n,n,0);

% Timing
%--------------------------------------------------------------------------
DCM.TE     = 0.033;
DCM.delays = repmat(RT,DCM.n,1);

% Options
DCM.options.nonlinear  = 0;
DCM.options.two_state  = 0;
DCM.options.stochastic = 0;
DCM.options.analysis   = 'CSD';

str         = ['DCM_' side{s} '_' area{a}];
DCM.name    = str;

save(fullfile(dir_dcm,str),'DCM');
% DCM = spm_dcm_fmri_csd(fullfile(dir_dcm,str));
clear DCM

end
end