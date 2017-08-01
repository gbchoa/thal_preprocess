%% Unzip zipped files
%==========================================================================
% Testpattern
%--------------------------------------------------------------------------
% You will need to edit the following to match your own folder structure

Fzipped     = '/Volumes/DYNAMITE/Preprocessing of a few';  
Funzipped   = '/Volumes/DYNAMITE/Preprocessing of a few/unzipped';
fs          = filesep;
subject  	= cellstr(spm_select('FPList', pwd, 'dir', '^NDA.*.gz$'));
  
% Loop through each individual subject on the hard drive
for g = 1:length(subject)
    subfold     = subject{g};
    gz_files  = cellstr(spm_select('FPList', subfold, 'dir'));
    
    % Loop through each individual image folder within the subject
    for i = 1:length(gz_files);
        gfile           = gz_files{g};
        [path fname]    = spm_fileparts(gfile);
        dotpos          = find(fname == '.');
        foldname        = fname(1:dotpos-1);
        
        try mkdir([gz_files  '-unzipped']); end
        
        gunzip(gfile, [Funzipped fs foldname]);
        
    end
end

