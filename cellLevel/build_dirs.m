function [data_manifest] = build_dirs(path,filename)

% Checks for files and directories; sorts rearranges files
% Assumes that E/A files are named according to:
% qbh_xxx_(bh/ht/pt)(1/2/3/...)(E/A)

if exist([path,'/data_manifest.mat'],'file')==2
    
    error('Data sort already executed');    % Make sure you don't overwrite after files have already been renamed/moved
    
else
    % Identify number and type of data files
    bh_structE=dir([path,'/',filename,'_b*E']);  
    bh_structA=dir([path,'/',filename,'_b*A']);
    if isempty(bh_structE)~=1 && isempty(bh_structA)~=1
        if strcmp(bh_structE(end).name,[filename,'_bhE'])==1    % Fix set ordering issue if first set is named X_bhA/E and not X_bh1A/E
            tempE={};
            tempA={};
            numsets=numel(bh_structE);
            tempE{1}=bh_structE(end).name;
            tempA{1}=bh_structA(end).name;
            for i=2:numsets
                tempE{i}=bh_structE(i-1).name;
                tempA{i}=bh_structA(i-1).name;
            end
            bh_testsE=tempE;
            bh_testsA=tempA;
        else
            bh_testsE={};
            bh_testsA={};
            for i=1:numel(bh_structE)
                bh_testsE{i}=[bh_structE(i).name];
                bh_testsA{i}=[bh_structA(i).name];
            end
        end
    else
        bh_testsE={};
        bh_testsA={};
    end
    
    ht_structE=dir([path,'/',filename,'_h*E']);
    ht_structA=dir([path,'/',filename,'_h*A']);
    if isempty(ht_structE)~=1 && isempty(ht_structA)~=1
        if strcmp(ht_structE(end).name,[filename,'_htE'])==1
            tempE={};
            tempA={};
            numsets=numel(ht_structE);
            tempE{1}=ht_structE(end).name;
            tempA{1}=ht_structA(end).name;
            for i=2:numsets
                tempE{i}=ht_structE(i-1).name;
                tempA{i}=ht_structA(i-1).name;
            end
            ht_testsE=tempE;
            ht_testsA=tempA;
        else
            ht_testsE={};
            ht_testsA={};
            for i=1:numel(ht_structE)
                ht_testsE{i}=[ht_structE(i).name];
                ht_testsA{i}=[ht_structA(i).name];
            end
        end
    else
        ht_testsE={};
        ht_testsA={};
    end
    
    pt_structE=dir([path,'/',filename,'_p*E']);
    pt_structA=dir([path,'/',filename,'_p*A']);
    if isempty(pt_structE)~=1 && isempty(pt_structA)~=1
        if strcmp(pt_structE(end).name,[filename,'_ptE'])==1
            tempE={};
            tempA={};
            numsets=numel(pt_structE);
            tempE{1}=pt_structE(end).name;
            tempA{1}=pt_structA(end).name;
            for i=2:numsets
                tempE{i}=pt_structE(i-1).name;
                tempA{i}=pt_structA(i-1).name;
            end
            pt_testsE=tempE;
            pt_testsA=tempA;
        else
            pt_testsE={};
            pt_testsA={};
            for i=1:numel(pt_structE)
                pt_testsE{i}=[pt_structE(i).name];
                pt_testsA{i}=[pt_structA(i).name];
            end
        end
    else
        pt_testsE={};
        pt_testsA={};
    end
    
    rp_structE=dir([path,'/',filename,'_rp*E']);
    rp_structA=dir([path,'/',filename,'_rp*A']);
    if isempty(rp_structE)~=1 && isempty(rp_structA)~=1
        if strcmp(rp_structE(end).name,[filename,'_rpE'])==1
            tempE={};
            tempA={};
            numsets=numel(rp_structE);
            tempE{1}=rp_structE(end).name;
            tempA{1}=rp_structA(end).name;
            for i=2:numsets
                tempE{i}=rp_structE(i-1).name;
                tempA{i}=rp_structA(i-1).name;
            end
            rp_testsE=tempE;
            rp_testsA=tempA;
        else
            rp_testsE={};
            rp_testsA={};
            for i=1:numel(rp_structE)
                rp_testsE{i}=[rp_structE(i).name];
                rp_testsA{i}=[rp_structA(i).name];
            end
        end
    else
        rp_testsE={};
        rp_testsA={};
    end
    
    mdot_structE = dir([path,'/',filename,'_mdot*E']);
    mdot_structA = dir([path,'/',filename,'_mdot*A']);
    if ~isempty(mdot_structE) && ~isempty(mdot_structA)
        numsets = numel(mdot_structE);
        
        % Check if reordering needed (if first file in series 
        if strcmp(mdot_structE(end).name,[filename,'_mdotE'])
            tempE = cell(numsets,1);
            tempA = cell(numsets,1);
            
            tempE{1} = mdot_structE(end).name;
            tempA{1} = mdot_structA(end).name;
            for i = 2:numsets
                tempE{i} = mdot_structE(i-1).name;
                tempA{i} = mdot_structA(i-1).name;
            end
            
            mdot_testsE = tempE;
            mdot_testsA = tempA;
        else
            mdot_testsE = cell(numsets,1);
            mdot_testsA = cell(numsets,1);
            for i = 1:numel(mdot_structE)
                mdot_testsE{i} = [mdot_structE(i).name];
                mdot_testsA{i} = [mdot_structA(i).name];
            end
        end
    else
        mdot_testsE = {};
        mdot_testsA = {};
    end
end

% Check for pre-existing directories, make 'em if we've got the data and
% sort raw data into sets

% Heading datasets
if exist([path,'/heading_tuning'],'dir')==0 && isempty(ht_testsE)~=1
    mkdir(path,'heading_tuning');
    
    if length(ht_testsE)==1    % For single dataset
        movefile([path,'/',ht_testsE{1}],[path,'/heading_tuning/',filename,'_htE']);
        movefile([path,'/',ht_testsA{1}],[path,'/heading_tuning/',filename,'_htA']);
    else
        for a=1:length(ht_testsE)  % For multiple datasets
            mkdir([path,'/heading_tuning/'],['set',num2str(a)]);
            
            movefile([path,'/',ht_testsE{a}],[path,'/heading_tuning/set',num2str(a),'/',filename,'_htE']);
            movefile([path,'/',ht_testsA{a}],[path,'/heading_tuning/set',num2str(a),'/',filename,'_htA']);
        end
    end
end

% Pursuit datasets
if exist(strcat(path,'/pursuit_tuning'),'dir')==0 && isempty(pt_testsE)~=1
    mkdir(path,'pursuit_tuning');
    
    if length(pt_testsE)==1    % For single dataset
        movefile([path,'/',pt_testsE{1}],[path,'/pursuit_tuning/',filename,'_ptE']);
        movefile([path,'/',pt_testsA{1}],[path,'/pursuit_tuning/',filename,'_ptA']);
    else
        for b=1:length(pt_testsE)  % For multiple datasets
            mkdir([path,'/pursuit_tuning/'],['set',num2str(b)]);
            
            movefile([path,'/',pt_testsE{b}],[path,'/pursuit_tuning/set',num2str(b),'/',filename,'_ptE']);
            movefile([path,'/',pt_testsA{b}],[path,'/pursuit_tuning/set',num2str(b),'/',filename,'_ptA']);
        end
    end
end

% Bighead datasets
if exist(strcat(path,'/bh_tests'),'dir')==0 && isempty(bh_testsE)~=1
    mkdir(path,'bh_tests');
    
%     if length(bh_testsE)==1    % For single dataset
%         movefile([path,'/',bh_testsE{1}],[path,'/bh_tests/',filename,'_bhE']);
%         movefile([path,'/',bh_testsA{1}],[path,'/bh_tests/',filename,'_bhA']);
%     else
        for c=1:length(bh_testsE)  % Make child directories regardless of number of sets
            mkdir([path,'/bh_tests/'],['set',num2str(c)]);
            
            movefile([path,'/',bh_testsE{c}],...
                [path,'/bh_tests/set',num2str(c),'/',filename,'_bhE']);
            movefile([path,'/',bh_testsA{c}],...
                [path,'/bh_tests/set',num2str(c),'/',filename,'_bhA']);
        end
%     end
end

% Stabilized pursuit replay datasets
if exist(strcat(path,'/pursuit_replay'),'dir')==0 && isempty(rp_testsE)~=1
    mkdir(path,'pursuit_replay');
    
    if length(rp_testsE)==1    % For single dataset
        movefile([path,'/',rp_testsE{1}],...
            [path,'/pursuit_replay/',filename,'_rpE']);
        movefile([path,'/',rp_testsA{1}],...
            [path,'/pursuit_replay/',filename,'_rpA']);
    else
        for c=1:length(rp_testsE)  % Make child directories regardless of number of sets
            mkdir([path,'/pursuit_replay/'],['set',num2str(c)]);
            
            movefile([path,'/',rp_testsE{c}],...
                [path,'/pursuit_replay/set',num2str(c),'/',filename,'_rpE']);
            movefile([path,'/',rp_testsA{c}],...
                [path,'/pursuit_replay/set',num2str(c),'/',filename,'_rpA']);
        end
    end
end

% Multidot datasets
if ~exist(strcat(path,'/multidot'),'dir') && ~isempty(mdot_testsE)
    mkdir(path,'/multidot');
    
    if length(mdot_testsE)==1    % For single dataset
        movefile([path,'/',mdot_testsE{1}],...
            [path,'/multidot/',filename,'_mdotE']);
        movefile([path,'/',mdot_testsA{1}],...
            [path,'/multidot/',filename,'_mdotA']);
    else
        for b = 1:length(mdot_testsE)  % For multiple datasets
            mkdir([path,'/multidot/'],['set',num2str(b)]);
            
            movefile([path,'/',mdot_testsE{b}],...
                [path,'/multidot/set',num2str(b),'/',filename,'_mdotE']);
            movefile([path,'/',mdot_testsA{b}],...
                [path,'/multidot/set',num2str(b),'/',filename,'_mdotA']);
        end
    end
end

% Save data manifest
if exist([path,'/data_manifest.mat'],'file')==0
    data_manifest=struct;
    
    data_manifest.ht_tests=length(ht_testsE);
    data_manifest.ht_filenames=[ht_testsE; ht_testsA];
    
    data_manifest.pt_tests=length(pt_testsE);
    data_manifest.pt_filenames=[pt_testsE; pt_testsA];
    
    data_manifest.bh_tests=length(bh_testsE);
    data_manifest.bh_filenames=[bh_testsE; bh_testsA];
    
    data_manifest.rp_tests=length(rp_testsE);
    data_manifest.rp_filenames=[rp_testsE; rp_testsA];
    
    data_manifest.mdot_tests=length(mdot_testsE);
    data_manifest.mdot_filenames=[mdot_testsE; mdot_testsA];
    
    save(strcat(path,'/data_manifest'),'data_manifest');
end

end
