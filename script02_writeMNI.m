%% This script calculates MNI152 and MNI305 positions each subject and saves them

%localDataPath = setLocalDataPath(1); % runs local PersonalDataPath (gitignored)
localDataPath = personalDataPath();
addpath('functions');

ss = 17;
sub_label = sprintf('%02d', ss);

ses_label = 'ieeg01';
outdir = fullfile(localDataPath.output,'derivatives','preproc_car',['sub-' sub_label]);

% load electrodes
elecsPath = fullfile(localDataPath.input, ['sub-' sub_label], ['ses-' ses_label], 'ieeg', ['sub-' sub_label '_ses-' ses_label '_electrodes.tsv']);
elecs = ieeg_readtableRmHyphens(elecsPath);
elecmatrix = [elecs.x, elecs.y, elecs.z];

% FS dir at root level, then of subject
FSRootdir = fullfile(localDataPath.input, 'sourcedata', 'freesurfer');
FSdir = fullfile(FSRootdir, sprintf('sub-%s', sub_label));

%% 1) Get and save MNI152 positions to electrodesMni152.tsv (volumetric, SPM12)

% locate forward deformation field from SPM. There are variabilities in session name, so we use dir to find a matching one
niiPath = dir(fullfile(localDataPath.input, 'sourcedata', 'spm_forward_deformation_fields', sprintf('sub-%s_ses-*_T1w_acpc.nii', sub_label)));
assert(length(niiPath) == 1, 'Error: did not find exactly one match in sourcedata T1w MRI'); % check for only one unique match
niiPath = fullfile(niiPath.folder, niiPath.name);

% create a location in derivatives to save the transformed electrode images
rootdirMni = fullfile(localDataPath.input, 'derivatives', 'MNI152_electrode_transformations', sprintf('sub-%s', sub_label));
mkdir(rootdirMni);

% calculate MNI152 coordinates for electrodes
xyzsMni152 = ieeg_getXyzMni(elecmatrix, niiPath, rootdirMni);

% save as separate MNI 152 electrodes table
elecsMni152Path = fullfile(localDataPath.input, ['sub-' sub_label], ['ses-' ses_label], 'ieeg', ['sub-' sub_label '_ses-' ses_label '_space-' 'MNI152NLin2009' '_electrodes.tsv']);
elecsMni152 = elecs;
elecsMni152.x = xyzsMni152(:, 1); elecsMni152.y = xyzsMni152(:, 2); elecsMni152.z = xyzsMni152(:, 3);
writetable(elecsMni152, elecsMni152Path, 'FileType', 'text', 'Delimiter', '\t');

fprintf('Saved to %s\n', elecsMni152Path);

%% 2) Get and save MNI305 positions (through fsaverage)

% calculate MNI305 coordinates for electrodes
[xyzsMni305, vertIdxFsavg, minDists, surfUsed] = ieeg_mni305ThroughFsSphere(elecmatrix, elecs.hemisphere, FSdir, FSRootdir, 'closest', 5);

% save as separate MNI 305 electrodes table
elecsMni305Path = fullfile(localDataPath.input, ['sub-' sub_label], ['ses-' ses_label], 'ieeg', ['sub-' sub_label '_ses-' ses_label '_space-' 'MNI305' '_electrodes.tsv']);
elecsMni305 = elecs;
elecsMni305.x = xyzsMni305(:, 1); elecsMni305.y = xyzsMni305(:, 2); elecsMni305.z = xyzsMni305(:, 3);
elecsMni305.vertex_fsaverage = vertIdxFsavg; % also add a column to indicate vertex on fsavg, so we can easily get position for inflated brain
writetable(elecsMni305, elecsMni305Path, 'FileType', 'text', 'Delimiter', '\t');

fprintf('Saved to %s\n', elecsMni305Path);

