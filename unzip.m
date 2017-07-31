%% Unzip zipped files
%==========================================================================
% Testpattern
%--------------------------------------------------------------------------
% You will need to edit the following to match your own folder structure

Fzipped     = '/Users/roschkoenig/Desktop/GitCode/Thalamic_Connectivity/Unzip Test';  
Funzipped   = '/Users/roschkoenig/Desktop/GitCode/Thalamic_Connectivity/Unzipped';
fs          = filesep;
gz_files  	= cellstr(spm_select('FPList', Fzipped, 'gz$'));

for g = 1:length(gz_files)
    gfile           = gz_files{g};              % Select single file
    [path fname]    = spm_fileparts(gfile);     % Separate filename from path
    dotpos          = find(fname == '.');       % Find where extension begins
    foldname        = fname(1:dotpos-1);        % Folder name = filename without extension
    
    try mkdir([Funzipped fs foldname]); end     % Make folder if it doesn't already exist
    gunzip(gfile, [Funzipped fs foldname]);
end
