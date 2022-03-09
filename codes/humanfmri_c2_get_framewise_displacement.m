function humanfmri_c2_get_framewise_displacement(preproc_subject_dir,varargin)

% Compute framewise displacement and apply exculsion criteria and save
% plots in PREPROC.qcdir
%
% :Usage:
%
%  humanfmri_c2_get_framewise_displacement(preproc_subject_dir,varargin)
%
% :Inputs:
%
%   - preproc_subject_dir: the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
%
% :Optional Inputs:
%
%   **'type':**
%       : specify type of FD (default: 'Power's FD')
%
% :Output:
%
%   PREPROC.framewise_displacement
%   save plots in PREPROC.qcdir
%
% Copyright (C) Feb 2019 Suhwan Gim and Hongji Kim
%
% ..
%
% :For example
% 1) humanfmri_c2_get_framewise_displacement(preproc_subject_dir,'type','VD')
% 2) humanfmri_c2_get_framewise_displacement(preproc_subject_dir) %default
% 3) humanfmri_c2_get_framewise_displacement(preproc_subject_dir,'type','Power');

%% functional commands
save_plot = true;
FD_id = 'Power';
FdJenkThr = 0.25;
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'type'}
                FD_id = varargin{i+1};
        end
    end
end
%%
for subj_i = 1:numel(preproc_subject_dir)
    % load PREPROC and Print header
    subject_dir = preproc_subject_dir{subj_i};    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    print_header(['Framewise Displacement: ' FD_id], PREPROC.subject_code);       
    %% Set Movement data (PREPROC.nuisance.mvmt_covariates)
    for run_i = 1:numel(PREPROC.nuisance.mvmt_covariates)
        MoveParams{run_i} = [PREPROC.nuisance.mvmt_covariates{run_i}];
        SpCov{run_i} = [PREPROC.nuisance.spike_covariates{run_i}]; %spikie covariates
    end
    %% Get FD
    switch FD_id
        case {'Power'} % Power's FD
            fprintf(1,'Computing Power''s framewise displacement...\n');
            for run_i = 1:length(MoveParams)
                % ======================================================================= %
                % mov       - an N x 6 matrix containing 6 movement parameters and where N
                %           = length of the time series.
                % head      - head radius (in mm) to use when converting radians to mm.
                % 			default = 50mm, as in Power et al.
                % ======================================================================= %
                head = 50; %maybe default?
                
                
                mov = MoveParams{run_i}; % x,y,z
                mov(:,4:6) = head*mov(:,4:6); % Do not need to covert if RP is calulated by SPM (Suhwan) 
                
                % differentiate movement parameters
                delta_mov = [
                    zeros(1,size(mov,2));
                    diff(mov);
                    ];
                
                % compute total framewise displacement
                FD{run_i} = sum(abs(delta_mov),2);
                MeanFd(run_i) = mean(FD{run_i});
            end
            
        case {'VD'} % Van Dijk's FD
            fprintf(1,'Computing Van Dijk''s framewise displacement...\n');
            for run_i = 1:length(MoveParams)
                mov = MoveParams{run_i}(:,1:3); % x,y,z
                % detrend motion regressors
                mov = detrend(mov,'linear');
                
                % number of time points
                N = size(mov,1);
                
                % initialise fd variable.
                FD{run_i} = zeros(N,1);
                
                % start at volume 2
                for ii = 2:N
                    x = mov(ii,1);
                    y = mov(ii,2);
                    z = mov(ii,3);
                    
                    x_1 = mov(ii-1,1);
                    y_1 = mov(ii-1,2);
                    z_1 = mov(ii-1,3);
                    
                    FD{run_i}(ii) = rms([x y z]) - rms([x_1 y_1 z_1]);
                    MeanFd(run_i) = mean(FD{run_i});
                end
            end
        case {'Jenk'}
            % not implemented yet
            warning('Check your input, especially, FD''s name (VD, Power)');
        otherwise
            warning('Check your input, especially, FD''s name (VD, Power)');
    end
    
    %% Exculsion criteria    
    excul_1 = zeros(1,length(MoveParams)); % liberal (mean FD > 0.55 mm)
    excul_2 = zeros(1,length(MoveParams)); % strigent (mean FD > 0.2 mm)
    excul_3 = zeros(1,length(MoveParams)); % at least one FD > 5 mm
    extxt = {' / meanFD>.55', ' / meanFD>.2' ,' / any(FD)>5'};
    
    % 1) Liberal criteria
    excul_1(MeanFd > 0.55) = 1; % liberal 
    
    
    % 2) More stringent criteria
    % 2.1) greater than 0.2 mm (Ciric)
    excul_2(MeanFd > 0.2) = 1;
    
    for run_i = 1:length(FD)
        % 2.2) Propotion ( > 20%): not implemented yet
%         if strcmp(FD_id,'Jenk')
%             FdTher = round(size(FD{run_i},1) * 0.20);
%             if sum(FD{run_i}> FdJenkThr) > FdTher
%                 excul_2(run_i) = 1;
%             end
%         end

        % 3) > 5mm 
        if any(FD{run_i} > 5)
            excul_3(run_i) = 1;
        end
    end
    
    %% plot FD
    c=1;
    if save_plot
        close all;
        Nrow_subplot = length(FD);
        sz = get(0, 'screensize');
        set(gcf, 'Position', [sz(3)*.02 sz(4)*.07 sz(3) *.65 sz(4)*.85])
        for run_i = 1:length(FD)
            % draw plot
            subplot(Nrow_subplot,3,[c c+1]);
            plot(FD{run_i});
            title(sprintf('run %02d',run_i));
            
            set(gca,'xlim', [0 length(FD{run_i})] ,'ylim',[0 0.7]);
            
            % draw histogram
            subplot(Nrow_subplot,3,c+2);
            
            histogram(FD{run_i},70);
            set(gca,'xlim', [0 0.7]);
            
            c=c+3;  
            
            title_text = ['Mean: ' num2str(MeanFd(run_i))];
            title(title_text);

            % title color BLUE if exc2 
            
            if excul_2(run_i)
                if  excul_1(run_i)
                    title_text = [title_text extxt{1}];
                    title(title_text,'color',[1 0 0]);
                else
                    title_text = [title_text extxt{2}];
                    title(title_text,'color',[0 0 1]);
                end
            end
            
            % title color RED if exc3
            if excul_3(run_i)
                title_text = [title_text extxt{3}];
                title(title_text, 'color', [1 0 0]);
            end
            
            % 0.2> 0.15 > 0.10
            %         if MeanFd(run_i) > 0.2
            %             title(['Mean: ' num2str(MeanFd(run_i))],'color',[1 0 0]);
            %         elseif MeanFd(run_i) < 0.2 && MeanFd(run_i) > 0.15
            %             title(['Mean: ' num2str(MeanFd(run_i))],'color',[1 0.2 0.2]);
            %         elseif MeanFd(run_i) < 0.15 && MeanFd(run_i) > 0.10
            %             title(['Mean: ' num2str(MeanFd(run_i))],'color',[1 0.4 0.4]);
            %         else
            %             title(['Mean: ' num2str(MeanFd(run_i))]);
            %         end
            
            
        end
        set(gcf, 'color', 'w');
        subtitle(char(['FrameWise Displacement: ' PREPROC.subject_code]));
        figdir = PREPROC.qcdir;
        graphwrite = fullfile(figdir, sprintf('FrameWise_Power_sub%s.png', PREPROC.subject_code(end-2:end)));
        % pagesetup(gcf);
        saveas(gcf,graphwrite);
    end
    
    %% output
    results.fd_id = FD_id;
    results.FD = FD;
    results.mean_FD = MeanFd;
    results.raw = MoveParams;
    results.exclusion_1 = excul_1;
    results.exclusion_2 = excul_2;
    results.exclusion_3 = excul_3;
    results.exclusion_descrip = {...
        'Description                                    : ''1'' means mark for exculsion; the order is order of run based on PREPROC'
        'exclusion_1 (less stringent)                   : 1) mean FD > 0.55 mm '; ...
        'exclusion_2 (more stringent and multi-criteria): 1) mean FD > 0.2mm'; ...
        'exclusion_3 (at least one spike) : 1) any spike > 5 mm';};
    %% save PREPROC
    PREPROC.framewise_displacement = results;
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
end

end