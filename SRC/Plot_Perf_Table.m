function axArr = Plot_Perf_Table(dataTbl,var_pairs,parent)
% Plot_Perf_Table  Draw five scatter plots of the performance table
%   • Color is grouped by Topology (Topo)
%   • Legend shows point count of each topology
%
% axArr – graphics handle array of the five scatter axes
% (The last row that only contains the legend axis is not returned.)

%% ------------------------------------------------------------------------
% 0)  Axis scale configuration (edit here only)
%     {'linear' | 'log'}  ×  5 rows, each row = {xScale , yScale}
axisMode = { {'log'   ,'linear'}   ...  % plot-1 : log-x / linear-y
           , {'linear','linear'}   ...  % plot-2 : linear / linear
           , {'log'   ,'log'   }   ...  % plot-3 : log / log
           , {'log'   ,'log'   }   ...  % plot-4 : log / log
           , {'log'   ,'log'   } };     % plot-5 : log / log
%% ------------------------------------------------------------------------

% Container ---------------------------------------------------------------
if nargin<3 || isempty(parent), parent = gcf; end
delete(get(parent,'Children'));                     % clear previous axes

nPlot = numel(var_pairs);                           % expected = 5
tlay  = tiledlayout(parent,nPlot+1,1, ...
                    'TileSpacing','compact', ...
                    'Padding','compact');

% Grouping / color map / point size --------------------------------------
features  = categorical(dataTbl.Topo);              % group by Topo
featNames = categories(features);
nFeat     = numel(featNames);
cmap      = lines(nFeat);                           % distinct colors

% Legend text with point count
counts  = zeros(1,nFeat);
for i = 1:nFeat
    counts(i) = sum(features == featNames{i});
end
legStr = cellfun(@(s,n)sprintf('%s (%d)',s,n), ...
                 featNames,num2cell(counts)','uni',0);

% Point size mapped to chip_area (quantile-based)
q        = quantile(dataTbl.chip_area,linspace(0,1,2000));
[~,~,qi] = histcounts(dataTbl.chip_area,[-inf q inf]);
ptSize   = 10 + (qi-1)/1999*5;

% Draw 5 scatter plots ----------------------------------------------------
axArr  = gobjects(nPlot,1);
hProxy = gobjects(nFeat,1);                          % first plot proxy for legend

for k = 1:nPlot
    axArr(k) = nexttile(tlay,k);  hold(axArr(k),'on');
    xVar = var_pairs{k}{1};
    yVar = var_pairs{k}{2};

    % Axis scale for this plot
    xMode = lower(axisMode{k}{1});   % 'linear' | 'log'
    yMode = lower(axisMode{k}{2});

    for f = 1:nFeat
        idx = features == featNames{f};

        % Exclude invalid data for log axes (≤0)
        if strcmp(xMode,'log'), idx = idx & dataTbl.(xVar) > 0; end
        if strcmp(yMode,'log'), idx = idx & dataTbl.(yVar) > 0; end
        if ~any(idx), continue, end          % no point for this group

        h = scatter(axArr(k), ...
                    dataTbl.(xVar)(idx), dataTbl.(yVar)(idx), ...
                    ptSize(idx), ...
                    cmap(f,:), 'filled', 'LineWidth',0.05);
        if k==1, hProxy(f) = h; end          % first plot keeps proxies
    end

    % Apply axis scale
    set(axArr(k),'XScale',xMode,'YScale',yMode);

    % Labels and title
    xlabel(axArr(k), strrep(xVar,'_','\_'));
    ylabel(axArr(k), strrep(yVar,'_','\_'));
    title(axArr(k), sprintf('%s vs. %s',xVar,yVar), 'Interpreter','none');

    % Grid and box style
    grid(axArr(k),'on');
    set(axArr(k), 'GridAlpha',0.25,'GridLineStyle','-');   % major grid
    set(axArr(k), 'MinorGridAlpha',0.08);                  % minor grid
    set(axArr(k), 'Box','on','LineWidth',1.5);             % thick border
end

% Dedicated legend row ----------------------------------------------------
axLeg = nexttile(tlay,nPlot+1);  axis(axLeg,'off');
legend(axLeg, hProxy, strrep(legStr,'_','\_'), ...
       'NumColumns',2, 'Location','south', 'Box','on');
end