function Amplifier_Copilot()
% Haochang, 2025-07

    % =============================================================
    % 0. Data and global state
    % =============================================================
    [Database_dir , Perf_Table] = loadDatabase('../Database');
    
    var_pairs  = {{'gbw','gain'},{'CMRR','PSRR'},...
                  {'gbw','SR'},{'noise','vos'},{'ivdd_27','chip_area'}};

    % allVars    = unique([var_pairs{:}]);
    % -------- 自定义性能显示顺序 ---------------------------------
    prefOrder  = ["gain","gbw","ivdd_27","CMRR","PSRR","vos","SR","tc","noise","pm","VDD","VCM","CL","chip_area","settlingTime","Tech_nodes","FOMS","FOML"]; % 想排在前面的
    varsAll    = string(Perf_Table.Properties.VariableNames);         % 表里真正存在的列
    prefKeep   = prefOrder(ismember(lower(prefOrder),lower(varsAll)));% 已存在的优先列
    remain     = varsAll(~ismember(lower(varsAll),lower(prefKeep)));  % 其余保持原序
    allVars    = cellstr([prefKeep , remain]);                        % ← 供 popup 使用
    varOrder   = [prefKeep , remain];              % ← 表格也用它

    maskTopo = true(height(Perf_Table),1);
    maskTech = true(height(Perf_Table),1);
    maskCL   = true(height(Perf_Table),1);
    maskAdv  = true(height(Perf_Table),1);
    maskVDD = true(height(Perf_Table),1);     
    masterMask = true(height(Perf_Table),1);
    
    advList  = {};                         % advanced condition strings
    scatterAxes  = gobjects(0);            % five scatter sub-axes
    highlightPts = gobjects(0);            % highlight circles
    lastIdxOrig  = [];                     % last selected original row
    
    LabelFontSize = 5;                     % ★ default label font size
    showWL = true;          % true → 显示 W/L；false → 显示 gm/ft
    doneTopo = false;   % ← 是否已经确认
    doneTech = false;
    doneVDD  = false;
    doneCL   = false;
    % =============================================================
    % 1. Main window (pixels 1500×800, centred)
    % =============================================================
    scr  = get(0,'ScreenSize');
    figW = 1400;  figH = 1000;
    left = round((scr(3)-figW)/2);  bot = round((scr(4)-figH)/2);
    
    mainFig = figure('Name','Amplifier-Copilot v1.0 (Github: Amplifier-Copilot)','Units','pixels',...
        'OuterPosition',[left bot figW figH],'Resize','off');
    
    panelL = uipanel(mainFig,'Units','normalized','Position',[0   0 0.10 1]);
    panelM = uipanel(mainFig,'Units','normalized','Position',[0.10 0 0.25 1]);
    panelR = uipanel(mainFig,'Units','normalized','Position',[0.35 0 0.65 1]);
    
    % =============================================================
    % 2. Left column ── quick + advanced filter
    % =============================================================
    topoVals = unique(Perf_Table.Topo);
    topoValsAll = topoVals;      % ← 保存原始列表，搜索时用
    techVals = unique(Perf_Table.Tech_nodes);
    clVals   = unique(Perf_Table.CL);
    vddVals  = unique(Perf_Table.VDD);
    
    % -------- layout (same as之前，略) -------------------------------------
    uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0 0.965 1 0.02],'String','Linear Search','FontWeight','bold');
    
    % ----  Topo title --------------------------------------------
    lblTopo = uicontrol(panelL,'Style','text','Units','normalized',...
               'Position',[0.05 0.935 0.9 0.02],...
               'String','1.Pick Topo','HorizontalAlignment','left',...
               'ForegroundColor','r','FontWeight','bold');     % 初始红色
    
    hTopoSearch = uicontrol(panelL,'Style','edit','Units','normalized',...
         'Position',[0.55 0.935 0.4 0.025],...   % 与标题同行
         'BackgroundColor','white',...
         'TooltipString','Type and Enter to filter topo',...
         'Callback',@topoSearchCallback);
    %--- 1) Topo listbox ----------------------------------------------------
    lbTopo = uicontrol(panelL,'Style','listbox','Units','normalized',...
              'Position',[0.05 0.6 0.9 0.32], ...  % ← bottom=0.70  height=0.25
              'String',topoVals,...
              'Max',numel(topoVals),'Min',0,'Value',1:numel(topoVals),...
              'Callback',@topoCallback);
    
    %--- 2) “Tech nodes”  -------------------------------
    % ----  Tech title --------------------------------------------
    lblTech = uicontrol(panelL,'Style','text','Units','normalized',...
               'Position',[0.05 0.57 0.45 0.02],...
               'String','2.Tech.(nm)','HorizontalAlignment','left',...
               'ForegroundColor','r','FontWeight','bold');
    
    % --- Tech listbox
    lbTech = uicontrol(panelL,'Style','listbox','Units','normalized',...
              'Position',[0.05 0.51 0.42 0.05],...
              'String',cellstr(num2str(techVals)),...
              'Max',numel(techVals),'Min',0,'Value',1:numel(techVals),...
              'Callback',@techCallback);
    % --- VDD title (new)
    % ----  VDD title ---------------------------------------------
    lblVDD  = uicontrol(panelL,'Style','text','Units','normalized',...
               'Position',[0.53 0.57 0.42 0.02],...
               'String','3.VDD(V)','HorizontalAlignment','left',...
               'ForegroundColor','r','FontWeight','bold');
    
    % --- VDD listbox (new)
    lbVDD = uicontrol(panelL,'Style','listbox','Units','normalized',...
              'Position',[0.53 0.51 0.42 0.05],...
              'String',cellstr(num2str(vddVals)),...
              'Max',numel(vddVals),'Min',0,'Value',1:numel(vddVals),...
              'Callback',@vddCallback);

    % ----  CL title ----------------------------------------------
    lblCL   = uicontrol(panelL,'Style','text','Units','normalized',...
               'Position',[0.05 0.485 0.9 0.02],...
               'String','4.CL(pF)',...
               'HorizontalAlignment','left',...
               'ForegroundColor','r','FontWeight','bold');
    
    lbCL = uicontrol(panelL,'Style','listbox','Units','normalized',...
              'Position',[0.05 0.365 0.9 0.12],...
              'String',cellstr(num2str(clVals)),...
              'Max',numel(clVals),'Min',0,'Value',1:numel(clVals),...
              'Callback',@clCallback);
    
    uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0 0.34 1 0.02],'String','Advance Search (AND)',...
              'FontWeight','bold');
    
    popupVar = uicontrol(panelL,'Style','popup','Units','normalized',...
              'Position',[0.05 0.295 0.9 0.04],'String',allVars);
    
    uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0.05 0.265 0.15 0.02],'String','min');
    editMin = uicontrol(panelL,'Style','edit','Units','normalized',...
              'Position',[0.20 0.245 0.3 0.04],'String','50');
    
    uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0.52 0.265 0.15 0.02],'String','max');
    editMax = uicontrol(panelL,'Style','edit','Units','normalized',...
              'Position',[0.67 0.245 0.3 0.04],'String','120');
    
    uicontrol(panelL,'Style','pushbutton','Units','normalized',...
              'Position',[0.05 0.21 0.4 0.026],'String','Add',...
              'Callback',@addAdvCallback);
    
    uicontrol(panelL,'Style','pushbutton','Units','normalized',...
              'Position',[0.55 0.21 0.4 0.026],'String','Reset',...
              'Callback',@clearAdvCallback);
    
    lbAdv = uicontrol(panelL,'Style','listbox','Units','normalized',...
              'Position',[0.05 0.05 0.9 0.14],'String',advList,...
              'Max',2,'Min',0,'TooltipString','Delete to clean');
    
    txtCount = uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0 0 1 0.02],'String','Data available：0',...
              'HorizontalAlignment','center','FontWeight','bold');
    
    set(mainFig,'WindowKeyPressFcn',@keyDeleteAdv);
    
    % =============================================================
    % 3. Middle column ─ scatter plots + select button
    % =============================================================
    scatterPanel = uipanel(panelM,'Units','normalized','Position',[0 0.05 1 0.95]);
    btnPanel     = uipanel(panelM,'Units','normalized','Position',[0 0 1 0.05]);
    
    uicontrol(btnPanel,'Style','pushbutton','String','Pick Individual to Plot',...
              'Units','normalized','Position',[0.3 0.15 0.4 0.7],...
              'FontSize',10,'Callback',@selectPointCallback);
    
    % =============================================================
    % 4. Right column ─ schematic / figures / table / export
    % =============================================================
    txtTopo = uicontrol(panelR,'Style','text','Units','normalized',...
                'Position',[0 0.97 1 0.03],'FontWeight','bold',...
                'FontSize',11,'String','','HorizontalAlignment','center');
    
    % ----- sub-panels -----------------------------------------------------
    axSchPanel = uipanel(panelR,'Units','normalized','Position',[0 0.70 1 0.27]);
    axFigPanel = uipanel(panelR,'Units','normalized','Position',[0 0.15 1 0.55]);
    tblPanel   = uipanel(panelR,'Units','normalized','Position',[0 0.05 1 0.10]);
    exportPanel= uipanel(panelR,'Units','normalized','Position',[0 0.00 1 0.05]);

    axSch = axes(axSchPanel,'Units','normalized','Position',[0 0 0.9 1]); % 留右侧 0.1 给按钮
    axFig = axes(axFigPanel,'Units','normalized','Position',[0 0 1 1]);
    
    uicontrol(axFigPanel,'Style','pushbutton','Units','normalized',...
          'Position',[0.96 0.85 0.035 0.12],...   % 右上角
          'String','Del','ForegroundColor','r','FontWeight','bold',...
          'TooltipString','Delete selected point PERMANENTLY!',...
          'Callback',@deletePointCallback);
    % -------- ★ 新增：User-Guide 按钮 -------------------------------
    uicontrol(axFigPanel,'Style','pushbutton','Units','normalized',...
          'Position',[0.96 0.70 0.035 0.12],...   % 紧跟 Del 下方
          'String','UG','TooltipString','Show User Guide',...
          'Callback',@showUserGuide);

    % ── schematic 右侧按钮区 ─────────────────────────────────────
    uicontrol(axSchPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.92 0.80 0.07 0.18],...   % 最高一格
              'String','Pop','TooltipString','Pop-out schematic window',...
              'Callback',@popSchCallback);
    
    uicontrol(axSchPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.92 0.55 0.07 0.18],'String','A+','FontWeight','bold',...
              'Callback',@incFontSz);
    
    uicontrol(axSchPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.92 0.30 0.07 0.18],'String','A-',...
              'Callback',@decFontSz);
    
    uicontrol(axSchPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.92 0.05 0.07 0.18],...
              'String','W,L↔gm,ft','FontSize',8,...
              'Callback',@toggleLabelMode);
    % ---------- export widgets --------------------------------------------
    uicontrol(exportPanel,'Style','text','Units','normalized',...
              'Position',[0.01 0.15 0.15 0.7],'String','Output Location:',...
              'HorizontalAlignment','left');
    
    editDst = uicontrol(exportPanel,'Style','edit','String','..\Output_netlist','Units','normalized',...
              'Position',[0.17 0.17 0.58 0.66],'HorizontalAlignment','left');
    
    uicontrol(exportPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.76 0.17 0.10 0.66],'String','Browser...','Callback',@browseDir);
    
    uicontrol(exportPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.87 0.17 0.12 0.66],'String','Export Netlist','Callback',@exportNetlist);
    
    % =============================================================
    % 5. initial scatter
    % =============================================================
    updateMask();
    drawScatter();

    showStartupImage(axSch,axFig); % 调用新函数来显示初始图片

    % =============================================================
    % ------------ quick filter callbacks --------------------------
    % =============================================================

    % ───────── Topo 回调 ─────────
    function topoCallback(~,~)
        listTopo = string(get(lbTopo,'String'));   % ① 先转成 string 数组
        selTopo  = listTopo(get(lbTopo,'Value'));  % ② 再用 Value 索引
        maskTopo = ismember(Perf_Table.Topo , selTopo);
    
        doneTopo = true;  doneTech = false; doneVDD = false; doneCL = false;
        maskCL  = true(height(Perf_Table),1);   % ← **把 CL 掩码清空**
        maskVDD  = true(height(Perf_Table),1);   % ← **把 掩码清空**
        maskTech  = true(height(Perf_Table),1);   % ← **把 掩码清空**

        refreshLists('topo');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── Tech 回调 ─────────
    function techCallback(~,~)
        if ~doneTopo, doneTopo = true; end
    
        listTech = str2double(get(lbTech,'String'));
        selTech  = listTech(get(lbTech,'Value'));
        maskTech = ismember(Perf_Table.Tech_nodes , selTech);
    
        doneTech = true;  doneVDD = false; doneCL = false;
        maskCL  = true(height(Perf_Table),1);   % ← **把 CL 掩码清空**
        maskVDD  = true(height(Perf_Table),1);   % ← **把 掩码清空**

        refreshLists('tech');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── VDD 回调 ─────────
    function vddCallback(~,~)
        if ~doneTopo, doneTopo = true; end
        if ~doneTech, doneTech = true; end
        listVDD = str2double(get(lbVDD,'String'));
        selVDD  = listVDD(get(lbVDD,'Value'));
        maskVDD = ismember(Perf_Table.VDD , selVDD);
    
        doneVDD = true;  doneCL = false;
        maskCL  = true(height(Perf_Table),1);   % ← **把 CL 掩码清空**

        refreshLists('vdd');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── CL 回调 ─────────
    function clCallback(~,~)
        
        listCL = str2double(get(lbCL,'String'));
        selCL  = listCL(get(lbCL,'Value'));
        maskCL = ismember(Perf_Table.CL , selCL);
    
        doneCL = true;
    
        updateLabelState();  updateMask(); drawScatter();
    end

    % =============================================================
    % ------------ advanced filter callbacks -----------------------
    % =============================================================
    function addAdvCallback(~,~)
        vName = allVars{get(popupVar,'Value')};
        mn = str2double(get(editMin,'String'));
        mx = str2double(get(editMax,'String'));
        if isnan(mn) || isnan(mx) || mn>=mx
            errordlg('Invalid Range!'); return
        end
        advList{end+1} = sprintf('%s ∈ [%.3g, %.3g]',vName,mn,mx);
        set(lbAdv,'String',advList);
        maskAdv = maskAdv & Perf_Table.(vName)>=mn & Perf_Table.(vName)<=mx;
        refreshLists('adv');        % ★ 仅此处更新列表
        % --- 进入“高级筛选流程” → 清空 4 列选择，重新从 Topo 开始 ----
        set(lbTopo,'Value',1:numel(get(lbTopo,'String')));
        set(lbTech,'Value',1:numel(get(lbTech,'String')));
        set(lbVDD ,'Value',1:numel(get(lbVDD,'String')));
        set(lbCL  ,'Value',1:numel(get(lbCL,'String')));
        maskTopo(:)=true; maskTech(:)=true; maskVDD(:)=true; maskCL(:)=true;
        updateLabelState();
        updateMask(); drawScatter();
    end

    function clearAdvCallback(~,~)
        % ---------- 1. 清空高级条件 -----------------------------
        advList = {};
        set(lbAdv,'String',advList);
        maskAdv = true(height(Perf_Table),1);
    
        % ---------- 2. 4 个快速过滤列表恢复到全集&全选 ----------
        set(lbTopo,'String',topoValsAll,'Value',1:numel(topoValsAll));
        set(lbTech,'String',cellstr(num2str(techVals)),'Value',1:numel(techVals));
        set(lbVDD ,'String',cellstr(num2str(vddVals )),'Value',1:numel(vddVals ));
        set(lbCL  ,'String',cellstr(num2str(clVals  )),'Value',1:numel(clVals ));
    
        % ---------- 3. 掩码必须同步复位！ ------------------------
        maskTopo(:) = true;
        maskTech(:) = true;
        maskVDD(:)  = true;
        maskCL(:)   = true;
    
        % ---------- 4. 步骤提示 √ 全部取消 -----------------------
        doneTopo = false;  doneTech = false;
        doneVDD  = false;  doneCL  = false;
    
        % ---------- 5. 刷新界面 ---------------------------------
        refreshLists('adv');      % 用全集重写列表框
        updateLabelState();       % 4 个标题变红
        updateMask();             % 重新组合 masterMask
        drawScatter();            % 散点图回到“全部数据”
    end

    function keyDeleteAdv(~,evt)
        if strcmp(evt.Key,'delete') && ~isempty(lbAdv.Value)
            advList(lbAdv.Value) = [];
            set(lbAdv,'String',advList,'Value',[]);
            maskAdv = true(height(Perf_Table),1);
            for s = advList
                tk = regexp(s{1},'^(.*) ∈ \[(.*),(.*)\]$','tokens','once');
                v = strtrim(tk{1}); mn = str2double(tk{2}); mx = str2double(tk{3});
                maskAdv = maskAdv & Perf_Table.(v)>=mn & Perf_Table.(v)<=mx;
            end
            refreshLists('adv');        % ★ 删除条件后同步列表
            doneTopo = false;  doneTech = false; doneVDD = false; doneCL = false;
            updateLabelState();updateMask(); drawScatter();
        end
    end

    % =============================================================
    % ------------ select-point callback  --------------------------
    % =============================================================
    function selectPointCallback(~,~)
        if isempty(scatterAxes) || ~isvalid(scatterAxes(1)), return; end
        axes(scatterAxes(1));
        [xClick,yClick,~] = ginput(1);
        if isempty(xClick), return; end
        idxLocal = findNearestRow(xClick,yClick);
        if isempty(idxLocal), return; end
        idxOrig  = find(masterMask); idxOrig = idxOrig(idxLocal);
        lastIdxOrig = idxOrig;

        % update topo title
        set(txtTopo,'String',char(Perf_Table.Topo(idxOrig)));

        % highlight points
        delete(highlightPts(ishandle(highlightPts)));
        highlightPts = gobjects(numel(var_pairs),1);
        tblShow = Perf_Table(masterMask,:);
        for k = 1:numel(var_pairs)
            v1 = var_pairs{k}{1}; v2 = var_pairs{k}{2};
            x0 = tblShow.(v1)(idxLocal);  y0 = tblShow.(v2)(idxLocal);
            highlightPts(k) = line(scatterAxes(k),x0,y0,'Color','r',...
                                   'Marker','o','MarkerSize',12,'LineWidth',1.5);
        end

        % schematic / figure / table
        cla(axSch,'reset');
        Show_Schematic_With_Values(Perf_Table,idxOrig,Database_dir,...
                           axSch,LabelFontSize, ...
                           ternary(showWL,'WL','GMFT'));
        axis(axSch,'off');

        [~,FigImg] = Get_Size_TBM_Figure(Perf_Table,idxOrig,Database_dir);
        cla(axFig); imshow(FigImg,'Parent',axFig); axis(axFig,'off');

        delete(get(tblPanel,'Children'));

        rowTbl   = Perf_Table(idxOrig , cellstr(varOrder));     % 先按顺序取列
        tblData  = row2charcell(rowTbl);                        % 转成带单位的 cell
        colNames = cellstr(varOrder);                           % 列标题
        
        uitable(tblPanel,'Units','normalized','Position',[0 0 1 1],...
                'Data',tblData, ...
                'ColumnName',colNames, ...
                'RowName',[]);
    end

% =============================================================
% ------------ font size buttons -------------------------------
% =============================================================
    function incFontSz(~,~)
        LabelFontSize = min(LabelFontSize+1,20);
        refreshSch();
    end
    function decFontSz(~,~)
        LabelFontSize = max(LabelFontSize-1,4);
        refreshSch();
    end
    function toggleLabelMode(~,~)
        showWL = ~showWL;          % 翻转模式
        refreshSch();              % 重新渲染
    end
    function refreshSch
        if ~isempty(lastIdxOrig) && isvalid(axSch)
            cla(axSch,'reset');
            Show_Schematic_With_Values(Perf_Table,lastIdxOrig, ...
                           Database_dir,axSch,LabelFontSize, ...
                           ternary(showWL,'WL','GMFT'));
            axis(axSch,'off');
        end
    end

% =============================================================
% ------------ export callbacks --------------------------------
% =============================================================
    function deletePointCallback(~,~)
        if isempty(lastIdxOrig)
            warndlg('No point selected.'); return
        end
        row = Perf_Table(lastIdxOrig,:);    % 当前行

        % --------- 询问 ----------
        msg = sprintf(['PERMANENTLY delete this result?\n\n',...
                       'Topo=%s  Tech=%g  VDD=%g\nRUN=%s  gen=%d  idx=%d'],...
                       row.Topo,row.Tech_nodes,row.VDD, ...
                       numeric2str(row.RUN),row.gen,row.index);
        if ~strcmp(questdlg(msg,'Confirm delete','Yes','Cancel','Cancel'),'Yes')
            return
        end

        % --------- 1. 计算路径（完全照搬 Get_Size_TBM_Figure） -----------
        topo = string(row.Topo);
        tech = numeric2str(row.Tech_nodes);
        vdd  = numeric2str(row.VDD);
        vcm  = numeric2str(row.VCM);
        cl   = numeric2str(row.CL);
        run  = numeric2str(row.RUN);
        gen  = numeric2str(row.gen);
        idx  = numeric2str(row.index);

        cfgDirName = strjoin([topo, tech, vdd, vcm, cl], '-');
        cfgDirPath = fullfile(Database_dir, topo, cfgDirName);

        perfTblDir = fullfile(cfgDirPath,'Perf_and_Size_Table');
        figRootDir = fullfile(cfgDirPath,'Netlist_and_Figure');
        leafDir    = strjoin([topo, tech, vdd, vcm, cl, run, gen, idx], '-');
        leafPath   = fullfile(figRootDir, leafDir);

        % --------- 2. 删除 Netlist_and_Figure/<leafDir> -------------------
        if isfolder(leafPath)
            try
                rmdir(leafPath,'s');
            catch ME
                errordlg({'Fail to delete folder:',leafPath,ME.message});
                return
            end
        end

        % --------- 3. 从 Perf_and_Size_Table 的 CSV 删行 ------------------
        csvFiles = dir(fullfile(perfTblDir,'*.csv'));
        if isempty(csvFiles)
            warningID = 'GetPerfTable:MissingCSV';
            warning(warningID,'CSV not found under %s', perfTblDir);
        else
            tbl = readtable(fullfile(perfTblDir,csvFiles(1).name), ...
                            'TextType','string');
            msk = tbl.gen==row.gen & tbl.index==row.index;
            tbl(msk,:) = [];
            try
                writetable(tbl, fullfile(perfTblDir,csvFiles(1).name));
            catch ME
                errordlg({'Fail to rewrite CSV',ME.message}); return
            end
        end

    % --------- 4. 从内存 Perf_Table 删行并刷新 ------------------------
    Perf_Table(lastIdxOrig,:) = [];       % 表删行
    % 5 个掩码同步删行（保持原过滤状态）
    maskTopo(lastIdxOrig) = [];
    maskTech(lastIdxOrig) = [];
    maskCL  (lastIdxOrig) = [];
    maskVDD (lastIdxOrig) = [];
    maskAdv (lastIdxOrig) = [];
    lastIdxOrig = [];                     % 清空“当前选中”
    
    % 重新组合 masterMask 并刷新
    masterMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv;
    drawScatter();        % 重画散点
    cla(axSch,'reset');   % 清空示意图
    % cla(axFig,'reset');

    cla(axFig,'reset');   % 清空右侧的图形区域
    showStartupImage(axSch,axFig);   % 重新显示启动引导图

    delete(get(tblPanel,'Children'));
    set(txtTopo,'String','');

    end
    % -------------------------------------------------------------
    % 显示启动引导图 (User Guide) 到 axSch / axFig
    % -------------------------------------------------------------
    function showUserGuide(~,~)
        cla(axSch,'reset');
        cla(axFig,'reset');
        showStartupImage(axSch,axFig);   % 已有的工具函数
        delete(highlightPts(ishandle(highlightPts)));  % 移除高亮圈
        set(txtTopo,'String','');        % 清空拓扑标题
        lastIdxOrig = [];                % 取消当前选中
    end
    
    function browseDir(~,~)
        dst = uigetdir(pwd,'Choose dir to export.');
        if dst ~= 0, set(editDst,'String',dst); end
    end

    function exportNetlist(~,~)
        % ---------- 0. 基本检查 -------------------------------
        if isempty(lastIdxOrig)
            warndlg('Pick a point before export'); return; end
        dstDir = strtrim(get(editDst,'String'));
        if isempty(dstDir)
            warndlg('Choose a dir before export'); return; end
        if ~exist(dstDir,'dir')
            try mkdir(dstDir); catch, errordlg('Unable to create new dir'); return; end
        end
    
        % ---------- 1. 取表格字段 -----------------------------
        row   = Perf_Table(lastIdxOrig,:);
        Topo  = char(row.Topo);
        Tech  = char(string(row.Tech_nodes));
        VDD   = char(string(row.VDD));
        VCM   = char(string(row.VCM));
        CL    = char(string(row.CL));
        if ismember('RUN',Perf_Table.Properties.VariableNames)
              RUN = char(string(row.RUN));
        else, RUN = '1';                % 如果没有 RUN 字段
        end
        gen   = char(string(row.gen));
        idx   = char(string(row.index));
    
        % ---------- 2. 构造源目录 -----------------------------
        dirName = sprintf('%s-%s-%s-%s-%s', ...
                          Topo,Tech,VDD,VCM,CL);
        srcDir  = fullfile(Database_dir,Topo,dirName,'Netlist_and_Figure',[dirName,'-',RUN,'-',gen,'-',idx]);
    
        if ~exist(srcDir,'dir')
            errordlg({'Wrong Dir:',srcDir},'EXPORT FAILED'); return
        end
    
        % ---------- 3. 复制 *.scs ----------------------------
        files = dir(srcDir);                       % 1) 列举
        files = files(~[files.isdir]);             % 2) 去掉所有子目录(含 '.' '..')
        % ↑ 这一步就能把 "." 和 ".." 清理掉，双保险再加下一行
        files = files(~ismember({files.name},{'.','..'}));
        

        if isempty(files)
            warndlg('EMPTY'); return
        end
    
        nCopy      = 0;
        copiedBest = '';                               % 保存提取出的 {...}

        for f = 1:numel(files)
            srcFile = fullfile(srcDir,files(f).name);
            dstFile = fullfile(dstDir ,files(f).name);

            try
                copyfile(srcFile,dstFile,'f');         % 覆盖同名文件
                nCopy = nCopy + 1;
            catch ME
                warning('EXPORT FAILED %s\n%s',srcFile,ME.message);
                continue
            end

            % ── 如果是刚复制的 txt 文件，立即解析 best_indi {...}
            if endsWith(files(f).name,'.txt','IgnoreCase',true)
                try
                    raw = fileread(dstFile);
                    tk  = regexp(raw,'best_indi[^{}]*\{([\s\S]*?)\}','tokens','once');
                    if ~isempty(tk)
                        copiedBest = ['{' tk{1} '}'];  % 补回最外层 {}
                    end
                catch ME
                    % warning('TXT parse failed: %s',ME.message);
                end
            end
        end
        
        % -------------------- Final notification (single dialog) --------------------
        if isempty(copiedBest)
            % no best_indi found ─ just inform the user
            msgbox(sprintf(['Export completed.\n',...
                            'Copied %d file(s) to:\n%s'], ...
                            nCopy,dstDir), ...
                   'Export Done');
        else
            % best_indi {...} was captured ─ ask whether to copy
            choice = questdlg( ...
                sprintf(['Export completed.\n',...
                         'Copied %d file(s) to:\n%s\n\n',...
                         'A best_indi {...} block was found.\n',...
                         'Copy it to the clipboard?'], ...
                         nCopy,dstDir), ...
                'Export Done', ...
                'Copy','Skip','Copy');        % default = Copy
        
            if strcmp(choice,'Copy')
                clipboard('copy',copiedBest);
            end
        end
    end
    
    function topoSearchCallback(src,~)
        key = lower(strtrim(get(src,'String')));   % 输入关键字
        if isempty(key)
            newList = topoValsAll;                 % 清空 ⇒ 显示全部
        else
            newList = topoValsAll(contains(lower(topoValsAll),key));
        end

        % 如果无匹配则保持旧列表
        if isempty(newList)
            return;
        end

        % 更新 listbox 显示并全选（可自行改成不选）
        set(lbTopo,'String',newList,'Value',1:numel(newList));

        % 同步内部掩码（复用原 topoCallback）
        topoCallback();
    end

    % =============================================================
    % ------------ helpers -----------------------------------------
    % =============================================================
    function drawScatter
        tblShow = Perf_Table(masterMask,:);
        scatterAxes = Plot_Perf_Table(tblShow,var_pairs,scatterPanel);
        delete(highlightPts(ishandle(highlightPts)));
        set(txtCount,'String',sprintf('Available data: %d',height(tblShow)));
    end

    function updateMask
        masterMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv;
        set(hTopoSearch,'String','');          % ← 新增
        % --------- 若过滤后无数据 → 还原为全选 -----------------
        if ~any(masterMask)
            warndlg('No record meets current filters. All filters are reset!');
        
            maskTopo(:)=true; maskTech(:)=true; maskCL(:)=true;
            maskVDD(:)=true;  maskAdv(:)=true; masterMask(:)=true;
        
            set(lbTopo,'String',topoValsAll,'Value',1:numel(topoValsAll));
            set(lbTech,'String',cellstr(num2str(techVals)),'Value',1:numel(techVals));
            set(lbVDD ,'String',cellstr(num2str(vddVals )),'Value',1:numel(vddVals ));
            set(lbCL  ,'String',cellstr(num2str(clVals  )),'Value',1:numel(clVals ));
        
            doneTopo=false; doneTech=false; doneVDD=false; doneCL=false;
            updateLabelState();
        end
    end
    
    function setState(lbl, doneFlag)
        txt = regexprep(get(lbl,'String'),'√','');  % 去旧 √
        if doneFlag
            set(lbl,'String',[txt '√'], ...
                'ForegroundColor','k','FontWeight','normal');
        else
            set(lbl,'String',txt, ...
                'ForegroundColor','r','FontWeight','bold');
        end
    end

    function updateLabelState
        setState(lblTopo, doneTopo);
        setState(lblTech, doneTech);
        setState(lblVDD , doneVDD );
        setState(lblCL  , doneCL  );
    end
    % =========================================================
    % 刷新列表
    %   level = 'adv'  → 4 列全部根据高级筛选刷新
    %           'topo' → 已选 Topo + 高筛 →刷新 Tech/VDD/CL
    %           'tech' → 已选 Topo/Tech + 高筛 →刷新 VDD/CL
    %           'vdd'  → 已选 Topo/Tech/VDD + 高筛 →刷新 CL
    % =========================================================
    function refreshLists(level)
        switch level
            case 'adv'                    % 纯高级筛选 → 保留下游选择
                baseMask = maskAdv;
                todo     = ["Topo","Tech","VDD","CL"];
                forceReset = false;
            case 'topo'                   % Topo 变 → 下游全部复位
                baseMask = maskTopo & maskAdv;
                todo     = ["Tech","VDD","CL"];
                forceReset = true;
            case 'tech'                   % Tech 变 → VDD/CL 复位
                baseMask = maskTopo & maskTech & maskAdv;
                todo     = ["VDD","CL"];
                forceReset = true;
            case 'vdd'                    % VDD 变 → CL 复位
                baseMask = maskTopo & maskTech & maskVDD & maskAdv;
                todo     = "CL";
                forceReset = true;
        end
    
        tblAvail = Perf_Table(baseMask ,:);
    
        for item = todo
            switch item
                case "Topo"
                    vals = unique(tblAvail.Topo);
                    if isempty(vals), vals = []; end % 空则让 updList 回退到 fullStr
                    % updList(lbTopo , cellstr(sort(vals)), topoValsAll);
                    updList(lbTopo, cellstr(sort(vals)), topoValsAll, forceReset);
                case "Tech"
                    vals = unique(tblAvail.Tech_nodes);
                    if isempty(vals), vals = []; end % 空则让 updList 回退到 fullStr

                    updList(lbTech , cellstr(num2str(sort(vals))), cellstr(num2str(techVals)), forceReset);
                case "VDD"
                    vals = unique(tblAvail.VDD);
                    if isempty(vals), vals = []; end % 空则让 updList 回退到 fullStr

                    updList(lbVDD , cellstr(num2str(sort(vals))), cellstr(num2str(vddVals)), forceReset);
                case "CL"
                    vals = unique(tblAvail.CL);
                    if isempty(vals), vals = []; end % 空则让 updList 回退到 fullStr

                    updList(lbCL  , cellstr(num2str(sort(vals))), cellstr(num2str(clVals)), forceReset);
            end
        end
    end
    % ------------------------------------------------------------------
    % updList(lb , newStr , fullStr , resetSel)
    %   • newStr  : 依据掩码算出的可用项（若空⇒使用 fullStr）
    %   • resetSel: true  → 直接 “全选”      (用于上游变动)
    %               false → 试图保留旧选择  (用于纯高级筛选)
    %   –– 使用单次 set(...'String',...'Value',...) 避免 MATLAB 警告
    % ------------------------------------------------------------------
    function updList(lb,newStr,fullStr,resetSel)
        if isempty(newStr), newStr = fullStr; end
    
        if resetSel
            newVal = 1:numel(newStr);              % 全选
        else
            oldStr = get(lb,'String');
            if isempty(oldStr), oldStr = {''}; end % 避免空
            oldVal = get(lb,'Value');
            oldSel = oldStr(oldVal);
            [~,newVal] = ismember(oldSel,newStr);
            newVal(newVal==0) = [];
            if isempty(newVal), newVal = 1:numel(newStr); end
        end
    
        newVal = min(newVal, numel(newStr));       % 双保险
        set(lb,'String',newStr,'Value',newVal);
    end

    % -------------------------------------------------------------
    % 找到距鼠标 (xClick,yClick) 最近的行
    %   • 自动判断该散点对的 X/Y 是否为对数坐标
    %   • 距离在“坐标轴归一化”后计算，避免量纲差
    % -------------------------------------------------------------
    function idxLocal = findNearestRow(xClick,yClick)
        tblShow = Perf_Table(masterMask,:);
        idxLocal = []; best = inf;

        for p = 1:numel(var_pairs)
            ax = scatterAxes(p);
            if ~isvalid(ax), continue; end

            % ---- 取 X/Y 数据列 ----
            vx = tblShow.(var_pairs{p}{1});
            vy = tblShow.(var_pairs{p}{2});

            % ---- 若坐标轴为对数 → 取 log10 ----
            if strcmp(ax.XScale,'log')
                vx        = log10(max(vx, realmin));
                xClickAdj = log10(max(xClick, realmin));
            else
                xClickAdj = xClick;
            end
            if strcmp(ax.YScale,'log')
                vy        = log10(max(vy, realmin));
                yClickAdj = log10(max(yClick, realmin));
            else
                yClickAdj = yClick;
            end

            % ---- 用“轴范围”归一化后求距离 ----
            dx = (vx - xClickAdj) ./ range(vx);
            dy = (vy - yClickAdj) ./ range(vy);
            [dm,loc] = min(hypot(dx,dy));

            if dm < best
                best = dm;
                idxLocal = loc;
            end
        end

        % ---- 距离过大则视为没点被选中 (可自行调整 0.06) ----
        if best > 0.06
            idxLocal = [];
        end
    end
    % =============================================================
    %  内部工具：尝试加载数据库，失败则弹出浏览框
    %  返回：
    %     dir   —— 被选中的数据库根目录
    %     tbl   —— 调用 Get_Perf_Table 成功返回的 Perf_Table
    % =============================================================
    function [dir , tbl] = loadDatabase(startDir)
        dir = startDir;                      % 初始猜测
        while true
            try
                tbl = Get_Perf_Table(dir);   % 尝试读取
                break                        % 成功→跳出循环
            catch ME                         % 失败→让用户重新选
                choice = questdlg( ...
                    sprintf(['无法在\n%s\n加载数据库：\n%s\n\n', ...
                             '是否浏览其它目录？'], dir, ME.message), ...
                    '数据库不可用','浏览...','退出','浏览...');
                if ~strcmp(choice,'浏览...')
                    error('AmplifierCopilot:NoDB','未找到有效数据库，程序终止');
                end
                newDir = uigetdir(pwd,'请选择数据库根目录');
                if newDir==0                % 用户点取消
                    error('AmplifierCopilot:NoDB','未找到有效数据库，程序终止');
                end
                dir = newDir;               % 继续下一轮尝试
            end
        end
    end
    % =============================================================
    % -------- schematic pop-out callback  (independent) -----------
    % =============================================================
    function popSchCallback(~,~)
        if isempty(lastIdxOrig)
            warndlg('Pick a point first'); return; end
    
        % ====== ① 把当前状态"快照"成本地副本 ======================
        myIdx      = lastIdxOrig;   % ← 固定住所选行
        myFontSize = LabelFontSize; % ← 自己的字号
        myShowWL   = showWL;        % ← 自己的 WL/GMFT 模式
    
        % ====== ② 布局参数（可再调） ==============================
        txtH = 0.05;  tblH = 0.12;  gap = 0.01;
        axH  = 1 - txtH - tblH - 2*gap;
    
        % ====== ③ 创建窗口骨架 ====================================
        popFig = figure('Name','Schematic (pop-out)','NumberTitle','off',...
                        'Units','pixels','Position',[200 80 1500 600]);
    
        % ---- 顶部拓扑名 ------------------------------------------
        uicontrol(popFig,'Style','text','Units','normalized',...
                  'Position',[0 1-txtH 0.9 txtH],...
                  'String',char(Perf_Table.Topo(myIdx)),...
                  'FontWeight','bold','FontSize',12,...
                  'HorizontalAlignment','center');
    
        % ---- schematic 轴 ----------------------------------------
        popAx = axes(popFig,'Units','normalized',...
                     'Position',[0 tblH+gap 0.9 axH]);
    
        % ---- 底部性能表格 ----------------------------------------
        tblPanelPop = uipanel(popFig,'Units','normalized',...
                              'Position',[0 0 0.9 tblH]);
    
        rowTbl   = Perf_Table(myIdx , cellstr(varOrder));
        tblData  = row2charcell(rowTbl);
        uitable(tblPanelPop,'Units','normalized','Position',[0 0 1 1],...
                'Data',tblData,'ColumnName',cellstr(varOrder),'RowName',[]);
    
        % ====== ④ 右侧本地按钮（只改自己的变量） ===================
        uicontrol(popFig,'Style','pushbutton','Units','normalized',...
                  'Position',[0.92 0.55 0.07 0.18],'String','A+','FontWeight','bold',...
                  'Callback',@(~,~)changeFont(+1));
    
        uicontrol(popFig,'Style','pushbutton','Units','normalized',...
                  'Position',[0.92 0.30 0.07 0.18],'String','A-',...
                  'Callback',@(~,~)changeFont(-1));
    
        uicontrol(popFig,'Style','pushbutton','Units','normalized',...
                  'Position',[0.92 0.05 0.07 0.18],...
                  'String','W,L↔gm,ft','FontSize',8,...
                  'Callback',@toggleMode);
    
        % ====== ⑤ 首次绘制 ========================================
        redraw();
    
        % ----------------------------------------------------------
        % 内部工具函数（全部使用 "my*" 变量）
        % ----------------------------------------------------------
        function redraw
            cla(popAx,'reset');
            Show_Schematic_With_Values(Perf_Table,myIdx,Database_dir,...
                                       popAx,myFontSize,...
                                       ternary(myShowWL,'WL','GMFT'));
            axis(popAx,'off');
        end
        function changeFont(delta)
            myFontSize = min(max(myFontSize + delta,4),20);
            redraw();
        end
        function toggleMode(~,~)
            myShowWL = ~myShowWL;
            redraw();
        end
    end
end



%% 以下是子函数

function showStartupImage(targetAxes1, targetAxes2)
    startupImgFile1 = 'Startup_UG_1.png';
    startupImgFile2 = 'Startup_UG_2.png';
    if isfile(startupImgFile1) && isfile(startupImgFile2)
        try
            img1 = imread(startupImgFile1);
            img2 = imread(startupImgFile2);
            imshow(img1, 'Parent', targetAxes1); 
            imshow(img2, 'Parent', targetAxes2); 
            axis(targetAxes1, 'off');           % 
            axis(targetAxes2, 'off');           % 
        catch ME
            cla(targetAxes1, 'reset');          % 
            axis(targetAxes1, 'off');           % 
            cla(targetAxes2, 'reset');          % 
            axis(targetAxes2, 'off');           % 
            warning('Could not load or display startup image "%s": %s', startupImgFile1, ME.message);
        end
    else
        cla(targetAxes, 'reset');              % 
        text(targetAxes, 0.5, 0.5, {'Startup guide "Startup_UG_1or2.png" not found.', 'Please select a point to begin.'}, ...
             'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', [0.5 0.5 0.5]);
        axis(targetAxes, 'off');               % 
    end
end

% =============================================================
% Sub-Function: turn single-row table to char cell with units
% =============================================================
function C = row2charcell(Trow)
    varNames = Trow.Properties.VariableNames;
    vals     = table2cell(Trow);
    C        = cell(size(vals));

    for k = 1:numel(vals)
        vName = varNames{k};  % 获取变量名
        v = vals{k};          % 获取变量值

        if isnumeric(v) || islogical(v)
            % --- 首先处理特殊数值 ---
            if isempty(v), C{k}=''; continue; end
            if isnan(v),   C{k}='NaN'; continue; end
            if isinf(v),   C{k}='Inf'; continue; end

            % --- 使用 switch 根据变量名应用不同格式和单位 ---
            switch vName
                % --- 电压相关 (V) ---
                case {'VDD', 'VCM'}
                    C{k} = sprintf('%.2f V', v);
                case {'noise', 'vos'} % 噪声和失调电压，通常较小
                    C{k} = formatWithEngUnit(v, 'V');
                
                % --- 增益/抑制比相关 (dB) ---
                case {'gain', 'CMRR', 'PSRR'}
                    C{k} = sprintf('%.1f dB', v);
                
                % --- 频率/带宽/速率相关 ---
                case 'gbw'
                    C{k} = formatWithEngUnit(v, 'Hz');
                case 'SR' % 压摆率单位通常是 V/us，直接格式化
                    C{k} = formatWithEngUnit(v,'V/s');
                
                % --- 温度特性  ---
                case 'tc'
                    C{k} = formatWithEngUnit(v, 'V/°C');
                % --- 时间相关 (s) ---
                case {'settlingTime'}
                    C{k} = formatWithEngUnit(v, 's');
                % --- 电流 (A) ---
                case 'ivdd_27'
                    C{k} = formatWithEngUnit(v, 'A');

                % --- 面积 (m^2) ---
                case 'chip_area' % 假定单位是 um^2
                    C{k} = sprintf('%.0f*%.0f µm^2', v,v);

                % --- 其他有明确单位的量 ---
                case 'pm' % 相位裕度
                    C{k} = sprintf('%.1f °', v);
                case 'Tech_nodes'
                    C{k} = sprintf('%d nm', v);
                case 'CL' % 容性负载
                    C{k} = sprintf('%.3f pF', v);

                % --- 无单位或纯数字的量 (整数格式) ---
                case {'gen', 'index', 'RUN'}
                    C{k} = sprintf('%d', v);
                
                % --- 默认情况: 无特定单位的量 (如 FOM, fitness, d_settle) ---
                otherwise
                    C{k} = sprintf('%.3g', v); % 使用 .3g 格式更通用
            end
        else
            % --- 对于非数值类型 (如 Topo)，直接转换为字符 ---
            C{k} = char(string(v));
        end
    end
end

% =============================================================
% Helper Function: Format number with engineering unit (M, k, m, µ, n, etc.)
% =============================================================
function str = formatWithEngUnit(val, baseUnit)
    % 输入:
    %   val: 数值
    %   baseUnit: 基础单位字符串, e.g., 'V', 'Hz', 's', 'A'
    
    if val == 0
        str = sprintf('0 %s', baseUnit);
        return;
    end

    % 工程前缀和对应的数量级
    prefixes = {'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', '', 'm', 'µ', 'n', 'p', 'f', 'a', 'z', 'y'};
    exponents = [24, 21, 18, 15, 12, 9, 6, 3, 0, -3, -6, -9, -12, -15, -18, -21, -24];
    
    % 计算数值的指数
    val_exp = floor(log10(abs(val)));
    
    % 找到最接近的工程指数 (3的倍数)
    best_exp_idx = 1;
    min_diff = inf;
    for i = 1:length(exponents)
        diff = abs(val_exp - exponents(i));
        if diff < min_diff
            min_diff = diff;
            best_exp_idx = i;
        end
    end
    
    % 如果数值本身在 [1, 1000) 范围内，则不使用前缀
    if val_exp >= 0 && val_exp < 3
        best_exp_idx = find(exponents == 0);
    end

    % 使用找到的最佳指数进行换算
    p = prefixes{best_exp_idx};
    exp_val = exponents(best_exp_idx);
    
    scaled_val = val / (10^exp_val);
    
    % 根据数值大小决定小数点位数
    if abs(scaled_val) >= 100
        fmt = '%.1f';
    elseif abs(scaled_val) >= 10
        fmt = '%.2f';
    else
        fmt = '%.3f';
    end
    
    % 组合成最终字符串
    str = sprintf([fmt ' %s%s'], scaled_val, p, baseUnit);
end

function out = ternary(cond,a,b)
    if cond, out = a; else, out = b; end
end

% === helper: unify table value → string (same as Get_Size_TBM_Figure) ===
function s = numeric2str(x)
    if ismissing(x) || isempty(x)
        s = "";
    else
        s = string(x);
        s = strrep(s," ","");
    end
end