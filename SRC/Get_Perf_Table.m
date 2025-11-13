function Perf_Table = Get_Perf_Table(Database_dir)
%READ_PERF_AND_SIZE_TABLE  Scan the whole “Database” 目录，把所有拓扑的
%Perf_and_Size_Table 读出来并纵向拼接，仅保留最后 25 个性能 / 尺寸列。
%
%   Perf_Table = Read_Perf_and_Size_Table(Database_dir)
%
%输入
%   Database_dir : 字符串，指向 “Database” 顶层目录。
%
%输出
%   Perf_Table   : table，包含所有拓扑的 25 列数据，已按行合并。
%
%目录层级示意
%   Database/
%      ├── <Topo_A>/
%      │     ├── <Topo_A>-<Run_0>/
%      │     │     └── Perf_and_Size_Table/   <- 读这里面的 *.mat / *.csv
%      │     └── …
%      └── <Topo_B>/…
%
%每一个 Perf_and_Size_Table 下如果既有 .mat 又有 .csv，会优先读取 .mat。
%如果 .mat 文件内含多个变量，只会取第一个 table 变量。
%
%作者: Haochang（2025-06）

% ------------------------------- 设置 -------------------------------
reqCols = { ...
  'gen','index','CMRR','FOML','FOMS','FOM_AW','PSRR','SR','chip_area','d_settle', ...
  'fitness','gain','gbw','ivdd_27','noise','pm','settlingTime','tc', ...
  'vos','Topo','Tech_nodes','VDD','VCM','CL','RUN'};     % 25 列

Perf_Table = table();      % 初始化空表

if nargin==0 || ~isfolder(Database_dir)
    error('Cant find database：%s', Database_dir);
end

% ------------------------------- 遍历拓扑 -------------------------------
topoDirs = dir(Database_dir);
for d = topoDirs'
    if ~d.isdir || startsWith(d.name,'.'),  continue, end   % 跳过 . / .. / 隐藏
    topoPath = fullfile(Database_dir, d.name);

    % ----- 遍历数据组 -----
    grpDirs = dir(topoPath);
    for g = grpDirs'
        if ~g.isdir || startsWith(g.name,'.'),  continue, end
        perfDir = fullfile(topoPath, g.name, 'Perf_and_Size_Table');
        if ~isfolder(perfDir),  continue, end

        % ============= 1. 先找 .mat 表格 =============
        matFiles = dir(fullfile(perfDir,'*.mat'));
        for mf = matFiles'
            try
                S = load(fullfile(perfDir, mf.name));
                tbl = firstTableFromStruct(S);
                tbl = keep23Columns(tbl, reqCols);
                Perf_Table = [Perf_Table; tbl];      %#ok<AGROW>
            catch ME
                warning('Read in MAT FAILED (%s): %s', mf.name, ME.message);
            end
        end

        % ============= 2. 再找 .csv / .xlsx =============
        dataFiles = [dir(fullfile(perfDir,'*.csv')) ; dir(fullfile(perfDir,'*.xlsx'))];
        for df = dataFiles'
            try
                if endsWith(df.name,'.csv','IgnoreCase',true)
                    tbl = readtable(fullfile(perfDir, df.name), 'TextType','string');
                else
                    tbl = readtable(fullfile(perfDir, df.name), 'TextType','string', 'Sheet',1);
                end
                tbl = keep23Columns(tbl, reqCols);
                Perf_Table = [Perf_Table; tbl];      %#ok<AGROW>
            catch ME
                warning('Read in CSV/XLSX FAILED (%s): %s', df.name, ME.message);
            end
        end
    end
end

% ------------------------------- 完成 -------------------------------
fprintf('Summary: %d datas read in\n', height(Perf_Table));

end
% ======================================================================
%                       辅助子函数
% ======================================================================
function tbl = firstTableFromStruct(S)
    % 从 load 得到的 struct 里抓出第一个 table 变量
    fns = fieldnames(S);
    for k = 1:numel(fns)
        if istable(S.(fns{k}))
            tbl = S.(fns{k});
            return
        end
    end
    error('No table in .MAT。');
end

function tbl = keep23Columns(tbl, reqCols)
    % 只保留指定 25 列（按列名找；若列名缺失则退化为"最后 25 列”）
    if all(ismember(reqCols, tbl.Properties.VariableNames))
        tbl = tbl(:, reqCols);
    elseif width(tbl) >= 25
        tbl = tbl(:, end-24:end);
        tbl.Properties.VariableNames = reqCols;  % 统一列名，防止后续 concat 报错
    else
        error('Table content WRONG');
    end
end