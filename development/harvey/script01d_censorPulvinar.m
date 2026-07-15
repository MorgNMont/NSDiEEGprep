%% This script checks if there were any missing bad channels not labeled in any run

localDataPath = personalDataPath();

ss = 18;

sub = sprintf('sub-%02d', ss);

%% 1) Load pulvinar channels file and determine which channels are pulvinar

% Find MSEL subjectID by matching to deidentified ID
participants = readtable(fullfile(localDataPath.input, 'sourcedata', 'participants.tsv'), 'FileType', 'text', 'Delimiter', '\t');
msel_id = participants.MSEL_id{strcmp(participants.participant_id, sub)};

% Find all channels close to pulvinar
load('data/pulv_subsNSD.mat');
chs_pulv = list{strcmpi(msel_id, list(:, 1)), 2};
fprintf('%s = %s\n', sub, msel_id);

if isempty(chs_pulv)
    fprintf('No pulvinar channels, returning.\n');
    return;
end

fprintf('All pulvinar channels: '); fprintf('%s ', chs_pulv{:}); fprintf('\n');

% load electrodes and keep only thalamic or WM pulv channels
elecsPath = fullfile(localDataPath.input, sub, 'ses-ieeg01', 'ieeg', sprintf('%s_ses-ieeg01_electrodes.tsv', sub));
elecs = ieeg_readtableRmHyphens(elecsPath);
chs_pulv_strict = {};
for ii = 1:length(chs_pulv)

    % add to strict pulv channel set only if in Thalamus or White Matter
    destrieux_label = elecs.Destrieux_label_text{strcmp(elecs.name, chs_pulv{ii})};
    if ~contains(destrieux_label, {'Thalamus', 'Cerebral_White_Matter'}), continue; end
    chs_pulv_strict = [chs_pulv_strict; chs_pulv(ii)];

end

if isempty(chs_pulv_strict)
    fprintf('No strict pulvinar channels, returning.\n');
    return;
end

fprintf('Strict pulvinar channels: '); fprintf('%s ', chs_pulv_strict{:}); fprintf('\n');


%% 2) Load data, censor pulvinar channels, and overwrite. Rename previous files

% censor with 0 or nan?
replace_value = nan;

outdir = fullfile(localDataPath.output, 'derivatives', 'preproc_car', sub);

% load subject CAR and BB data
fprintf('Loading CAR evoked potentials and broadband for %s\n', sub);
load(fullfile(outdir, sprintf('%s_desc-preprocCAR_ieeg.mat', sub)));
load(fullfile(outdir, sprintf('%s_desc-preprocCARBB_ieeg.mat', sub)));

% ensure single format
Mdata = single(Mdata);
Mbb = single(Mbb);

% find and censor the pulvinar channels in Mdata and Mbb
channel_names = all_channels.name;
pulv_channel_numbers = find(ismember(channel_names, chs_pulv_strict));
fprintf('Censoring pulvinar channel numbers: '); fprintf('%d ', pulv_channel_numbers); fprintf(' with %d\n', replace_value);
assert(length(pulv_channel_numbers) == length(chs_pulv_strict), 'Error: Did not find the same number of channels as in pulv list');

Mdata(pulv_channel_numbers, :, :) = replace_value;
Mbb(pulv_channel_numbers, :, :) = replace_value;

% rename the previous ones to not overwrite
movefile(fullfile(outdir, sprintf('%s_desc-preprocCAR_ieeg.mat', sub)), fullfile(outdir, sprintf('%s_desc-preprocCAR_ieeg_containsPulvinar.mat', sub)));
movefile(fullfile(outdir, sprintf('%s_desc-preprocCARBB_ieeg.mat', sub)), fullfile(outdir, sprintf('%s_desc-preprocCARBB_ieeg_containsPulvinar.mat', sub)));

% Save new ones
save(fullfile(outdir, sprintf('%s_desc-preprocCAR_ieeg.mat', sub)), 'tt', 'srate', 'Mdata', 'eventsST', 'all_channels', '-v7.3');
save(fullfile(outdir, sprintf('%s_desc-preprocCARBB_ieeg.mat', sub)), 'tt', 'srate', 'Mbb', 'eventsST', 'all_channels', '-v7.3');

