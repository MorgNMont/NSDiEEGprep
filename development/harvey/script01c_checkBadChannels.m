%% This script checks if there were any missing bad channels not labeled in any run

localDataPath = personalDataPath();

% save for each sub
for ss = 5:18

    %if ss == 4, continue; end

    sub = sprintf('sub-%02d', ss);
    
    % load subject
    fprintf('Loading CAR evoked potentials for %s\n', sub);
    load(fullfile(localDataPath.input, 'derivatives', 'preproc_car', sub, sprintf('%s_desc-preprocCAR_ieeg.mat', sub)));
    
    % pdf out path
    pdf_name = fullfile(localDataPath.output, 'derivatives', 'preproc_car', sub, sprintf('%s_desc-preprocCAR_prelim.pdf', sub));
    
    %% 1) Save preliminary plots for a subset of trials in each recording set
    
    % indexes of SEEG channels only
    idx_seeg = strcmp(all_channels.type, 'SEEG');
    
    channel_names = all_channels.name(idx_seeg);
    
    % bad channels or soz to omit in plot
    badChs = all_channels.status(idx_seeg) == 0 | all_channels.soz(idx_seeg) == 1;
    
    % For each recording_set, plot and save a ch x average ERP heatmap. This assumes bad channels are constant per recording set
    recording_sets = unique(eventsST.recording_set);
    
    % number of trials to pull for each recording set. Keep this constant so that the expected noise amplitude is constant
    n_trial_samp = 20;
    
    % for reproducibility
    rng(sum(sub));
    for ii = 1:length(recording_sets)
        
        idx_set = find(eventsST.recording_set == recording_sets(ii) & ...
            strcmp(eventsST.status, 'good') & strcmp(eventsST.pre_status, 'good') & ... % just use events with good status
            ~contains(lower(eventsST.status_description), 'interictal') & ~contains(lower(eventsST.pre_status_description), 'interictal')); % and no interictals
        assert(length(idx_set) >= n_trial_samp, 'Error: not enough good trials to sample %d from', n_trial_samp);
        P = randperm(length(idx_set));
        idx_set = idx_set(P(1:n_trial_samp));
    
        % matrix of trials for current recording set
        M_set = Mdata(idx_seeg, :, idx_set);
    
        toPlot = mean(M_set, 3);
        toPlot(badChs, :) = nan; % nan out bad channels and soz channels
    
        figure('Position', [200, 200, 480, 800]);
        imagescNaN(tt, 1:length(channel_names), toPlot); clim([-50, 50]);
        colorbar;
        xlim([-0.8, 0.8]);
        xlabel('Time (s)'); ylabel('Channel');
        yticks(1:2:length(channel_names)); yticklabels(channel_names(1:2:end));
    
        title(sprintf('recording set %d, %d trials', ii, n_trial_samp));
    
        if ii == 1
            exportgraphics(gcf, pdf_name, 'ContentType', 'Image', 'Resolution', 300);
        else
            exportgraphics(gcf, pdf_name, 'ContentType', 'Image', 'Resolution', 300, 'Append', true);
        end
        close(gcf);
        
    end

end