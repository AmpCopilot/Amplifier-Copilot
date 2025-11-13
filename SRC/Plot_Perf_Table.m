function axArr = Plot_Perf_Table(dataTbl,var_pairs,parent)
% 按 Topo 上色并把每个 Topo 的点数写进 legend
%
% axArr : 5 个散点轴（最下一行 legend 轴不返回）

% ---------- 0. 容器 -------------------------------------------------
if nargin<3 || isempty(parent), parent = gcf; end
delete(get(parent,'Children'));

nPlot = numel(var_pairs);                      % =5
tlay  = tiledlayout(parent,nPlot+1,1,'TileSpacing','compact','Padding','compact');

% ---------- 1. 分组 / 颜色 / 点大小 --------------------------------
features = categorical(dataTbl.Topo);          % 只按 Topo 分组
featNames= categories(features);
nFeat    = numel(featNames);
cmap     = lines(nFeat);

% legend 字符串附加数量
counts   = zeros(1,nFeat);
for i=1:nFeat
    counts(i) = sum(features==featNames{i});
end
legStr   = cellfun(@(s,n)sprintf('%s (%d)',s,n),featNames,num2cell(counts)','uni',0);

q        = quantile(dataTbl.chip_area,linspace(0,1,2000));
[~,~,qi] = histcounts(dataTbl.chip_area,[-inf q inf]);
ptSize   = 10 + (qi-1)/1999*5;

% ---------- 2. 五幅散点 --------------------------------------------
axArr = gobjects(nPlot,1);
hProxy = gobjects(nFeat,1);                    % legend 代理

for k = 1:nPlot
    axArr(k) = nexttile(tlay,k);  hold(axArr(k),'on');
    xVar = var_pairs{k}{1};    yVar = var_pairs{k}{2};

    for f = 1:nFeat
        idx = features == featNames{f};
        if k>=4                                   % log-log 图
            idx = idx & dataTbl.(xVar)>0 & dataTbl.(yVar)>0;
        end

        h = scatter(axArr(k),dataTbl.(xVar)(idx),dataTbl.(yVar)(idx),...
                     ptSize(idx),cmap(f,:),'filled','LineWidth',0.05);
        if k==1, hProxy(f)=h; end
    end

    if k>=3, set(axArr(k),'XScale','log','YScale','log'); end
    if k==1, set(axArr(k),'XScale','log'); end
    xlabel(axArr(k),strrep(xVar,'_','\_'));
    ylabel(axArr(k),strrep(yVar,'_','\_'));
    title(axArr(k),sprintf('%s vs. %s',xVar,yVar),'Interpreter','none');
    % ---- 网格 + 粗外框 --------------------------------------
    grid(axArr(k),'on');
    set(axArr(k), 'GridAlpha',0.25,'GridLineStyle','-');   % 主网格
    set(axArr(k), 'MinorGridAlpha',0.08);                  % (可选)微网格
    set(axArr(k), 'Box','on','LineWidth',1.5);             % 粗外框
end

% ---------- 3. legend 独占一行 --------------------------------------
axLeg = nexttile(tlay,nPlot+1);  axis(axLeg,'off');
legend(axLeg,hProxy,strrep(legStr,'_','\_'),'NumColumns',2,'Location','south','Box','on');
end