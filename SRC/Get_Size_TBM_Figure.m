function [Size_and_TBM, Figure] = Get_Size_TBM_Figure(Perf_Table, idx, Database_dir)
%GET_SIZE_TBM_FIGURE  根据 Perf_Table 中指定行的信息，回到 Database
%目录里取
%   1) Perf_and_Size_Table 里 gen / index 对应的整行 → Size_and_TBM
%   2) Netlist_and_Figure 里 gen*_perf.png             → Figure (RGB 数组)
%
%[Size_and_TBM, Figure] = Get_Size_TBM_Figure(Perf_Table, idx, Database_dir)
%
%输入
%   Perf_Table   : 由 Get_Perf_Table 生成的总表，应至少包含
%                  Topo, Tech_nodes, VDD, VCM, CL, RUN, gen, index … 等列
%   idx          : 整数，Perf_Table 中的行号
%   Database_dir : 可选，Database 根目录；默认取 Perf_Table 的用户目录上一层
%
%输出
%   Size_and_TBM : table，Perf_and_Size_Table 中匹配 gen/index 的那一行
%   Figure       : uint8 RGB 图像；若未找到图片则返回 []
%
%目录示例
%   Database/Topo/
%       └── <Topo>-<Tech>-<VDD>-<VCM>-<CL>/
%              ├── Perf_and_Size_Table/xxx.csv
%              └── Netlist_and_Figure/
%                     <Topo>-<Tech>-<VDD>-<VCM>-<CL>-<RUN>-<gen>-<index>/
%                         gen<gen>_perf.png
%
%作者：Haochang  (2025-06)

% --------------------------- 参数检查 ---------------------------
arguments
    Perf_Table          table
    idx   (1,1) double  {mustBePositive, mustBeInteger}
    Database_dir string = ""     % 若不给就自动推断
end

if idx > height(Perf_Table)
    error('idx=%d 超过了 Perf_Table 行数 (%d)。', idx, height(Perf_Table));
end

row = Perf_Table(idx, :);

% 自动推断 Database 根目录（放在 Perf_Table.UserData.DatabaseRoot 里最好）
if Database_dir == ""
    if isfield(Perf_Table.Properties.UserData, 'DatabaseRoot')
        Database_dir = Perf_Table.Properties.UserData.DatabaseRoot;
    else
        error('请提供 Database_dir 或在 Perf_Table.Properties.UserData.DatabaseRoot 中存根目录。');
    end
end
Database_dir = char(Database_dir);   % 转成 char，便于与 fullfile 拼接

% --------------------------- 变量取值 ---------------------------
topo   = string(row.Topo);
tech   = numeric2str(row.Tech_nodes);
vdd    = numeric2str(row.VDD);
vcm    = numeric2str(row.VCM);
cl     = numeric2str(row.CL);
run    = numeric2str(row.RUN);
gen    = numeric2str(row.gen);
index = numeric2str(row.index);

% 基础目录： <Topo>-<Tech>-<VDD>-<VCM>-<CL>-<RUN>
cfgDirName = strjoin([topo, tech, vdd, vcm, cl], '-');
cfgDirPath = fullfile(Database_dir, topo, cfgDirName);   % 在 Topo 目录下

% --------------------------- 1. 读取 Size / TBM 行 ---------------------------
Size_and_TBM = table();   % 默认空
perfTblDir   = fullfile(cfgDirPath, 'Perf_and_Size_Table');
csvFiles     = dir(fullfile(perfTblDir, '*.csv'));

if isempty(csvFiles)
    warning('在 %s 下未找到 *.csv', perfTblDir);
else
    % 默认只取第一个 csv
    ptable = readtable(fullfile(perfTblDir, csvFiles(1).name), 'TextType','string');
    % 查找符合 gen / index 的行
    hasGen   = ismember('gen',   ptable.Properties.VariableNames);
    hasIndex = ismember('index', ptable.Properties.VariableNames);
    if ~hasGen || ~hasIndex
        warning('Perf_and_Size_Table 中缺少 gen 或 index 列。');
    else
        mask = (ptable.gen == str2double(gen)) & (ptable.index == str2double(index));
        Size_and_TBM = ptable(mask, :);
        if isempty(Size_and_TBM)
            warning('在 %s 中未找到 gen=%s, index=%s 的行。', csvFiles(1).name, gen, index);
        end
    end
end

% --------------------------- 2. 读取性能图 ---------------------------
Figure = [];
figRoot = fullfile(cfgDirPath, 'Netlist_and_Figure');
leafDir = strjoin([topo, tech, vdd, vcm, cl, run, gen,index], '-');
leafPath = fullfile(figRoot, leafDir);

if isfolder(leafPath)
    pngFiles = dir(fullfile(leafPath, sprintf('gen%s*_perf.png', gen)));
    if ~isempty(pngFiles)
        try
            Figure = imread(fullfile(leafPath, pngFiles(1).name));
        catch ME
            warning(ME.identifier,'%s', ME.message);
        end
    else
        warning('在 %s 下未找到 gen%s*_perf.png', leafPath, gen);
    end
else
    warning('图像目录不存在：%s', leafPath);
end

end
% ============================ 工具函数 ============================
function s = numeric2str(x)
% 把 table 中可能是字符串 / 数值 / categorical 的列统一转成不带空格的字符串
    if ismissing(x) || isempty(x)
        s = "";
    else
        s = string(x);
        s = strrep(s," ","");   % 去掉空格
    end
end