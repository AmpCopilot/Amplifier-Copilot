function Amplifier_Copilot()
% Haochang, 2025-12

    % =============================================================
    % 0. Data and global state
    % =============================================================
    [Database_dir , Perf_Table] = loadDatabase('../Database');
    
    var_pairs  = {{'gbw','gain'},{'CMRR','PSRR'},...
                  {'gbw','SR'},{'noise','vos'},{'ivdd_27','chip_area'}};
    
    
    % -------- Customize performance display order -----------------
    prefOrder  = ["gain","gbw","ivdd_27","CMRR","PSRR","vos","SR","tc","noise","pm","VDD","VCM","CL","chip_area","settlingTime","Tech_nodes","FOMS","FOML"]; 
    varsAll    = string(Perf_Table.Properties.VariableNames); 
    prefKeep   = prefOrder(ismember(lower(prefOrder),lower(varsAll)));
    remain     = varsAll(~ismember(lower(varsAll),lower(prefKeep)));  
    allVars    = cellstr([prefKeep , remain]);                     
    varOrder   = [prefKeep , remain]; 

    maskTopo = true(height(Perf_Table),1);
    maskTech = true(height(Perf_Table),1);
    maskCL   = true(height(Perf_Table),1);
    maskAdv  = true(height(Perf_Table),1);
    maskVDD = true(height(Perf_Table),1);     
    masterMask = true(height(Perf_Table),1);
    maskFOM = true(height(Perf_Table),1);      

    advList  = {};                    
    scatterAxes  = gobjects(0);       
    highlightPts = gobjects(0);       
    lastIdxOrig  = [];                
    
    LabelFontSize = 5;                     % ★ default label font size
    showWL = true; 
    doneTopo = false; 
    doneTech = false;
    doneVDD  = false;
    doneCL   = false;
    % =============================================================
    % 1. Main window (pixels 1500×800, centred)
    % =============================================================
    scr  = get(0,'ScreenSize');
    figW = 1400;  figH = 1000;
    left = round((scr(3)-figW)/2);  bot = round((scr(4)-figH)/2);
    
    mainFig = figure('Name','Amplifier-Copilot v25.1.1 (Github: Amplifier-Copilot)','Units','pixels',...
        'OuterPosition',[left bot figW figH],'Resize','on');
    
    panelL = uipanel(mainFig,'Units','normalized','Position',[0   0 0.10 1]);
    panelM = uipanel(mainFig,'Units','normalized','Position',[0.10 0 0.25 1]);
    panelR = uipanel(mainFig,'Units','normalized','Position',[0.35 0 0.65 1]);
    
    % =============================================================
    % 2. Left column ── quick + advanced filter
    % =============================================================
    topoVals = unique(Perf_Table.Topo);
    topoValsAll = topoVals;    
    techVals = unique(Perf_Table.Tech_nodes);
    clVals   = unique(Perf_Table.CL);
    vddVals  = unique(Perf_Table.VDD);
    
    % -------- layout  -------------------------------------
    uicontrol(panelL,'Style','text','Units','normalized',...
              'Position',[0 0.965 1 0.02],'String','Linear Search','FontWeight','bold');
    
    % ----  Topo title --------------------------------------------
    lblTopo = uicontrol(panelL,'Style','text','Units','normalized',...
               'Position',[0.05 0.935 0.9 0.02],...
               'String','1.Pick Topo','HorizontalAlignment','left',...
               'ForegroundColor','r','FontWeight','bold');   
    
    hTopoSearch = uicontrol(panelL,'Style','edit','Units','normalized',...
         'Position',[0.55 0.935 0.4 0.025],...  
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
    
    % uicontrol(btnPanel,'Style','pushbutton','String','Pick Individual to Plot',...
    %           'Units','normalized','Position',[0.3 0.15 0.4 0.7],...
    %           'FontSize',10,'Callback',@selectPointCallback);
    % -------- Slider + Button ----------------------------------------
    uicontrol(btnPanel,'Style','text','Units','normalized',...
              'Position',[0.02 0.65 0.18 0.3],'String','Filter:',...
              'HorizontalAlignment','left','FontSize',9,...
              'BackgroundColor',get(btnPanel,'BackgroundColor'));
    
    sliderFOM = uicontrol(btnPanel,'Style','slider','Units','normalized',...
              'Position',[0.02 0.15 0.55 0.25],... 
              'Min',5,'Max',100,'Value',50,...
              'SliderStep',[5/95, 20/95],...
              'Callback',@sliderFOMCallback);
    
    txtFOMPercent = uicontrol(btnPanel,'Style','text','Units','normalized',...
              'Position',[0.16 0.65 0.12 0.3],'String','50%',...
              'HorizontalAlignment','left','FontSize',9,'FontWeight','bold',...
              'ForegroundColor',[0 0.45 0.74],... 
              'BackgroundColor',get(btnPanel,'BackgroundColor'));
    
    uicontrol(btnPanel,'Style','pushbutton','String','Pick to Plot',...
              'Units','normalized','Position',[0.62 0.15 0.36 0.7],...
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

    axSch = axes(axSchPanel,'Units','normalized','Position',[0 0 0.9 1]); 
    axFig = axes(axFigPanel,'Units','normalized','Position',[0 0 1 1]);
    
    uicontrol(axFigPanel,'Style','pushbutton','Units','normalized',...
          'Position',[0.96 0.85 0.035 0.12],... 
          'String','Del','ForegroundColor','r','FontWeight','bold',...
          'TooltipString','Delete selected point PERMANENTLY!',...
          'Callback',@deletePointCallback);
    % -------- User-Guide Button -------------------------------
    uicontrol(axFigPanel,'Style','pushbutton','Units','normalized',...
          'Position',[0.96 0.70 0.035 0.12],...  
          'String','UG','TooltipString','Show User Guide',...
          'Callback',@showUserGuide);

    % -------- schematic ----------------------------------------------
    uicontrol(axSchPanel,'Style','pushbutton','Units','normalized',...
              'Position',[0.92 0.80 0.07 0.18],...  
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
    sliderFOMCallback(); 

    showStartupImage(axSch,axFig);

    % =============================================================
    % ------------ quick filter callbacks --------------------------
    % =============================================================

    % ───────── Topo Callback ─────────
    function topoCallback(~,~)
        listTopo = string(get(lbTopo,'String'));   
        selTopo  = listTopo(get(lbTopo,'Value'));  
        maskTopo = ismember(Perf_Table.Topo , selTopo);
    
        doneTopo = true;  doneTech = false; doneVDD = false; doneCL = false;
        maskCL  = true(height(Perf_Table),1);   
        maskVDD  = true(height(Perf_Table),1);  
        maskTech  = true(height(Perf_Table),1);  

        refreshLists('topo');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── Tech Callback ─────────
    function techCallback(~,~)
        if ~doneTopo, doneTopo = true; end
    
        listTech = str2double(get(lbTech,'String'));
        selTech  = listTech(get(lbTech,'Value'));
        maskTech = ismember(Perf_Table.Tech_nodes , selTech);
    
        doneTech = true;  doneVDD = false; doneCL = false;
        maskCL  = true(height(Perf_Table),1);   
        maskVDD  = true(height(Perf_Table),1);  

        refreshLists('tech');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── VDD Callback ─────────
    function vddCallback(~,~)
        if ~doneTopo, doneTopo = true; end
        if ~doneTech, doneTech = true; end
        listVDD = str2double(get(lbVDD,'String'));
        selVDD  = listVDD(get(lbVDD,'Value'));
        maskVDD = ismember(Perf_Table.VDD , selVDD);
    
        doneVDD = true;  doneCL = false;
        maskCL  = true(height(Perf_Table),1);  

        refreshLists('vdd');
        updateLabelState();  updateMask(); drawScatter();
    end
    
    % ───────── CL Callback ─────────
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
        refreshLists('adv');       
        set(lbTopo,'Value',1:numel(get(lbTopo,'String')));
        set(lbTech,'Value',1:numel(get(lbTech,'String')));
        set(lbVDD ,'Value',1:numel(get(lbVDD,'String')));
        set(lbCL  ,'Value',1:numel(get(lbCL,'String')));
        maskTopo(:)=true; maskTech(:)=true; maskVDD(:)=true; maskCL(:)=true;
        updateLabelState();
        updateMask(); drawScatter();
    end

    function clearAdvCallback(~,~)
        % ---------- 1. Clear mask -----------------------------
        advList = {};
        set(lbAdv,'String',advList);
        maskAdv = true(height(Perf_Table),1);
    
        % ---------- 2. filter clear----------
        set(lbTopo,'String',topoValsAll,'Value',1:numel(topoValsAll));
        set(lbTech,'String',cellstr(num2str(techVals)),'Value',1:numel(techVals));
        set(lbVDD ,'String',cellstr(num2str(vddVals )),'Value',1:numel(vddVals ));
        set(lbCL  ,'String',cellstr(num2str(clVals  )),'Value',1:numel(clVals ));
    
        % ---------- 3. mask reset ------------------------
        maskTopo(:) = true;
        maskTech(:) = true;
        maskVDD(:)  = true;
        maskCL(:)   = true;
        maskFOM(:)  = true;  
        set(sliderFOM,'Value',50);        
        % ---------- 4. step reset -----------------------
        doneTopo = false;  doneTech = false;
        doneVDD  = false;  doneCL  = false;
    
        % ---------- 5. refresh ---------------------------------
        refreshLists('adv');     
        updateLabelState();      
        sliderFOMCallback();  
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
            refreshLists('adv');        
            doneTopo = false;  doneTech = false; doneVDD = false; doneCL = false;
            updateLabelState();updateMask(); drawScatter();
        end
    end
    % =============================================================
    % ------------ FOM slider callback -----------------------------
    % =============================================================
    function sliderFOMCallback(~,~)
        rawValue = get(sliderFOM,'Value');
        percent = round(rawValue / 5) * 5;      
        percent = max(5, min(100, percent));    
        set(sliderFOM, 'Value', percent);       
        set(txtFOMPercent,'String',sprintf('%d%%',percent));
        
        baseMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv;
        tblBase = Perf_Table(baseMask,:);
        
        if isempty(tblBase)
            maskFOM(:) = true;
            updateMask(); drawScatter();
            return;
        end
        
        %  FOM_gg = gbw * gain
        % FOM_gg = tblBase.gbw .* tblBase.gain; 
        FOM_gg = tblBase.gbw .* (10.^(tblBase.gain/20));

        % sort by Fom_gg 
        [~,sortIdx] = sort(FOM_gg,'descend');
        nKeep = max(1, round(length(FOM_gg) * percent/100)); 
        keepIdx = sortIdx(1:nKeep);
        
        % refresh mask
        maskFOM(:) = false;
        baseIdx = find(baseMask);
        maskFOM(baseIdx(keepIdx)) = true;
        
        updateMask(); drawScatter();
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

        rowTbl   = Perf_Table(idxOrig , cellstr(varOrder));  
        tblData  = row2charcell(rowTbl);                     
        colNames = cellstr(varOrder);                        
        
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
        showWL = ~showWL;         
        refreshSch();             
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
        row = Perf_Table(lastIdxOrig,:);   

        % --------- msg pop up ----------
        msg = sprintf(['PERMANENTLY delete this result?\n\n',...
                       'Topo=%s  Tech=%g  VDD=%g\nRUN=%s  gen=%d  idx=%d'],...
                       row.Topo,row.Tech_nodes,row.VDD, ...
                       numeric2str(row.RUN),row.gen,row.index);
        if ~strcmp(questdlg(msg,'Confirm delete','Yes','Cancel','Cancel'),'Yes')
            return
        end

        % --------- 1. calculate path, as same as in Get_Size_TBM_Figure.m -----------
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

        % --------- 2. delete Netlist_and_Figure/<leafDir> -------------------
        if isfolder(leafPath)
            try
                rmdir(leafPath,'s');
            catch ME
                errordlg({'Fail to delete folder:',leafPath,ME.message});
                return
            end
        end

        % --------- 3. delete row in Perf_and_Size_Table  ------------------
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

    % --------- 4. delete row in Perf_Table, then refrest ------------------------
    Perf_Table(lastIdxOrig,:) = [];    
 
    maskTopo(lastIdxOrig) = [];
    maskTech(lastIdxOrig) = [];
    maskCL  (lastIdxOrig) = [];
    maskVDD (lastIdxOrig) = [];
    maskAdv (lastIdxOrig) = [];
    maskFOM (lastIdxOrig) = []; 
    lastIdxOrig = [];                 
    
    masterMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv;
    drawScatter();       
    cla(axSch,'reset');   
    % cla(axFig,'reset');

    cla(axFig,'reset');   
    showStartupImage(axSch,axFig);   

    delete(get(tblPanel,'Children'));
    set(txtTopo,'String','');

    end
    % -------------------------------------------------------------
    % Show User Guide in axSch / axFig
    % -------------------------------------------------------------
    function showUserGuide(~,~)
        cla(axSch,'reset');
        cla(axFig,'reset');
        showStartupImage(axSch,axFig);  
        delete(highlightPts(ishandle(highlightPts)));  
        set(txtTopo,'String','');       
        lastIdxOrig = [];                
    end
    
    function browseDir(~,~)
        dst = uigetdir(pwd,'Choose dir to export.');
        if dst ~= 0, set(editDst,'String',dst); end
    end

    function exportNetlist(~,~)
        % ---------- 0. Basic check -------------------------------
        if isempty(lastIdxOrig)
            warndlg('Pick a point before export'); return; end
        dstDir = strtrim(get(editDst,'String'));
        if isempty(dstDir)
            warndlg('Choose a dir before export'); return; end
        if ~exist(dstDir,'dir')
            try mkdir(dstDir); catch, errordlg('Unable to create new dir'); return; end
        end
    
        % ---------- 1. Combine string -----------------------------
        row   = Perf_Table(lastIdxOrig,:);
        Topo  = char(row.Topo);
        Tech  = char(string(row.Tech_nodes));
        VDD   = char(string(row.VDD));
        VCM   = char(string(row.VCM));
        CL    = char(string(row.CL));
        if ismember('RUN',Perf_Table.Properties.VariableNames)
              RUN = char(string(row.RUN));
        else, RUN = '1';               
        end
        gen   = char(string(row.gen));
        idx   = char(string(row.index));
    
        % ---------- 2. Combine path string ----------------------
        dirName = sprintf('%s-%s-%s-%s-%s', ...
                          Topo,Tech,VDD,VCM,CL);
        srcDir  = fullfile(Database_dir,Topo,dirName,'Netlist_and_Figure',[dirName,'-',RUN,'-',gen,'-',idx]);
    
        if ~exist(srcDir,'dir')
            errordlg({'Wrong Dir:',srcDir},'EXPORT FAILED'); return
        end
    
        % ---------- 3. copy *.scs ----------------------------
        files = dir(srcDir);                      
        files = files(~[files.isdir]);            
        files = files(~ismember({files.name},{'.','..'}));
        

        if isempty(files)
            warndlg('EMPTY'); return
        end
    
        nCopy      = 0;
        copiedBest = '';                              

        for f = 1:numel(files)
            srcFile = fullfile(srcDir,files(f).name);
            dstFile = fullfile(dstDir ,files(f).name);

            try
                copyfile(srcFile,dstFile,'f');       
                nCopy = nCopy + 1;
            catch ME
                warning('EXPORT FAILED %s\n%s',srcFile,ME.message);
                continue
            end

            if endsWith(files(f).name,'.txt','IgnoreCase',true)
                try
                    raw = fileread(dstFile);
                    tk  = regexp(raw,'best_indi[^{}]*\{([\s\S]*?)\}','tokens','once');
                    if ~isempty(tk)
                        copiedBest = ['{' tk{1} '}']; 
                    end
                catch ME
                    warning('TXT parse failed: %s',ME);
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
        key = lower(strtrim(get(src,'String')));  
        if isempty(key)
            newList = topoValsAll;                
        else
            newList = topoValsAll(contains(lower(topoValsAll),key));
        end

        if isempty(newList)
            return;
        end

        set(lbTopo,'String',newList,'Value',1:numel(newList));

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
        % masterMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv;
        masterMask = maskTopo & maskTech & maskCL & maskVDD & maskAdv & maskFOM;
        set(hTopoSearch,'String','');    
        if ~any(masterMask)
            warndlg('No record meets current filters. All filters are reset!');
        
            maskTopo(:)=true; maskTech(:)=true; maskCL(:)=true;
            maskVDD(:)=true;  maskAdv(:)=true; maskFOM(:)=true; masterMask(:)=true;
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
    % Refresh available lists based on current masks
    %   level = 'adv'  → Only clean advanced filter → keep downstream
    %           'topo' → clean topo but keep downstream
    %           'tech' → clean tech but keep VDD/CL
    %           'vdd'  → clean VDD but keep CL
    % =========================================================
    function refreshLists(level)
        switch level
            case 'adv'                  
                baseMask = maskAdv;
                todo     = ["Topo","Tech","VDD","CL"];
                forceReset = false;
            case 'topo'                  
                baseMask = maskTopo & maskAdv;
                todo     = ["Tech","VDD","CL"];
                forceReset = true;
            case 'tech'                  
                baseMask = maskTopo & maskTech & maskAdv;
                todo     = ["VDD","CL"];
                forceReset = true;
            case 'vdd'                   
                baseMask = maskTopo & maskTech & maskVDD & maskAdv;
                todo     = "CL";
                forceReset = true;
        end
    
        tblAvail = Perf_Table(baseMask ,:);
    
        for item = todo
            switch item
                case "Topo"
                    vals = unique(tblAvail.Topo);
                    if isempty(vals), vals = []; end 
                    updList(lbTopo, cellstr(sort(vals)), topoValsAll, forceReset);
                case "Tech"
                    vals = unique(tblAvail.Tech_nodes);
                    if isempty(vals), vals = []; end 

                    updList(lbTech , cellstr(num2str(sort(vals))), cellstr(num2str(techVals)), forceReset);
                case "VDD"
                    vals = unique(tblAvail.VDD);
                    if isempty(vals), vals = []; end 

                    updList(lbVDD , cellstr(num2str(sort(vals))), cellstr(num2str(vddVals)), forceReset);
                case "CL"
                    vals = unique(tblAvail.CL);
                    if isempty(vals), vals = []; end

                    updList(lbCL  , cellstr(num2str(sort(vals))), cellstr(num2str(clVals)), forceReset);
            end
        end
    end
    % ------------------------------------------------------------------
        % updList(lb , newStr , fullStr , resetSel)
        %   • newStr  : Available items calculated by mask (if empty⇒use fullStr)
        %   • resetSel: true  → Directly "select all"      (for upstream changes)
        %               false → Try to keep old selection  (for pure advanced filter)
        %   –– Use single set(...'String',...'Value',...) to avoid MATLAB warnings
    % ------------------------------------------------------------------
    function updList(lb,newStr,fullStr,resetSel)
        if isempty(newStr), newStr = fullStr; end
    
        if resetSel
            newVal = 1:numel(newStr);              
        else
            oldStr = get(lb,'String');
            if isempty(oldStr), oldStr = {''}; end 
            oldVal = get(lb,'Value');
            oldSel = oldStr(oldVal);
            [~,newVal] = ismember(oldSel,newStr);
            newVal(newVal==0) = [];
            if isempty(newVal), newVal = 1:numel(newStr); end
        end
    
        newVal = min(newVal, numel(newStr));     
        set(lb,'String',newStr,'Value',newVal);
    end

    % -------------------------------------------------------------
        % Find the row closest to the mouse (xClick, yClick)
        %   • Automatically determine whether the X/Y of the scatter pair is logarithmic axis
        %   • Distance is calculated after "axis normalization" to avoid unit difference
    % -------------------------------------------------------------
    function idxLocal = findNearestRow(xClick,yClick)
        tblShow = Perf_Table(masterMask,:);
        idxLocal = []; best = inf;

        for p = 1:numel(var_pairs)
            ax = scatterAxes(p);
            if ~isvalid(ax), continue; end

            % ---- Get X/Y data columns ----
            vx = tblShow.(var_pairs{p}{1});
            vy = tblShow.(var_pairs{p}{2});

            % ---- If axis is logarithmic → take log10 ----
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

            % ---- Calculate distance after normalization by axis range ----
            dx = (vx - xClickAdj) ./ range(vx);
            dy = (vy - yClickAdj) ./ range(vy);
            [dm,loc] = min(hypot(dx,dy));

            if dm < best
                best = dm;
                idxLocal = loc;
            end
        end

        % ---- If the distance is too large, treat as no point selected (can adjust 0.06) ----
        if best > 0.06
            idxLocal = [];
        end
    end
    % =============================================================
    %  Internal tool: try to load database, if failed then pop up browse dialog
    %  Return:
    %     dir   —— selected database root directory
    %     tbl   —— Perf_Table returned by calling Get_Perf_Table successfully
    % =============================================================
    function [dir , tbl] = loadDatabase(startDir)
        dir = startDir;                      % Initial guess
        while true
            try
                tbl = Get_Perf_Table(dir);   % Try to read
                break                        % Success→break loop
            catch ME                         % Failure→let user reselect
                choice = questdlg( ...
                    sprintf(['Failed to load database at\n%s\n:\n%s\n\n', ...
                             'Browse another directory?'], dir, ME.message), ...
                    'Database unavailable','Browse...','Exit','Browse...');
                if ~strcmp(choice,'Browse...')
                    error('AmplifierCopilot:NoDB','No valid database found, program terminated');
                end
                newDir = uigetdir(pwd,'Please select database root directory');
                if newDir==0                % User clicked cancel
                    error('AmplifierCopilot:NoDB','No valid database found, program terminated');
                end
                dir = newDir;               % Continue next attempt
            end
        end
    end
    % =============================================================
    % -------- schematic pop-out callback  (independent) -----------
    % =============================================================
    function popSchCallback(~,~)
        if isempty(lastIdxOrig)
            warndlg('Pick a point first'); return; end
    
        % ====== ① Snapshot current state as local copy ======================
        myIdx      = lastIdxOrig;   % ← Fix selected row
        myFontSize = LabelFontSize; % ← Own font size
        myShowWL   = showWL;        % ← Own WL/GMFT mode
    
        % ====== ② Layout parameters (can be adjusted) ==============================
        txtH = 0.05;  tblH = 0.12;  gap = 0.01;
        axH  = 1 - txtH - tblH - 2*gap;
    
        % ====== ③ Create window skeleton ====================================
        popFig = figure('Name','Schematic (pop-out)','NumberTitle','off',...
                        'Units','pixels','Position',[200 80 1500 600]);
    
        % ---- Top topology name ------------------------------------------
        uicontrol(popFig,'Style','text','Units','normalized',...
                  'Position',[0 1-txtH 0.9 txtH],...
                  'String',char(Perf_Table.Topo(myIdx)),...
                  'FontWeight','bold','FontSize',12,...
                  'HorizontalAlignment','center');
    
        % ---- schematic axis ----------------------------------------
        popAx = axes(popFig,'Units','normalized',...
                     'Position',[0 tblH+gap 0.9 axH]);
    
        % ---- Bottom performance table ----------------------------------------
        tblPanelPop = uipanel(popFig,'Units','normalized',...
                              'Position',[0 0 0.9 tblH]);
    
        rowTbl   = Perf_Table(myIdx , cellstr(varOrder));
        tblData  = row2charcell(rowTbl);
        uitable(tblPanelPop,'Units','normalized','Position',[0 0 1 1],...
                'Data',tblData,'ColumnName',cellstr(varOrder),'RowName',[]);
    
        % ====== ④ Right local buttons (only change own variables) ===================
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
    
        % ====== ⑤ First draw ========================================
        redraw();
    
        % ----------------------------------------------------------
        % Internal helper functions (all use "my*" variables)
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



%% The following are sub-functions

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
        vName = varNames{k};  % Get variable name
        v = vals{k};          % Get variable value

        if isnumeric(v) || islogical(v)
            % --- First handle special values ---
            if isempty(v), C{k}=''; continue; end
            if isnan(v),   C{k}='NaN'; continue; end
            if isinf(v),   C{k}='Inf'; continue; end

            % --- Use switch to apply different formats and units according to variable name ---
            switch vName
                % --- Voltage related (V) ---
                case {'VDD', 'VCM'}
                    C{k} = sprintf('%.2f V', v);
                case {'noise', 'vos'} % Noise and offset voltage, usually small
                    C{k} = formatWithEngUnit(v, 'V');
                
                % --- Gain/suppression ratio related (dB) ---
                case {'gain', 'CMRR', 'PSRR'}
                    C{k} = sprintf('%.1f dB', v);
                
                % --- Frequency/bandwidth/rate related ---
                case 'gbw'
                    C{k} = formatWithEngUnit(v, 'Hz');
                case 'SR' % Slew rate unit is usually V/us, format directly
                    C{k} = formatWithEngUnit(v,'V/s');
                
                % --- Temperature characteristics  ---
                case 'tc'
                    C{k} = formatWithEngUnit(v, 'V/°C');
                % --- Time related (s) ---
                case {'settlingTime'}
                    C{k} = formatWithEngUnit(v, 's');
                % --- Current (A) ---
                case 'ivdd_27'
                    C{k} = formatWithEngUnit(v, 'A');

                % --- Area (m^2) ---
                case 'chip_area' % Assume unit is um^2
                    C{k} = sprintf('%.0f*%.0f µm^2', v,v);

                % --- Other quantities with clear units ---
                case 'pm' % Phase margin
                    C{k} = sprintf('%.1f °', v);
                case 'Tech_nodes'
                    C{k} = sprintf('%d nm', v);
                case 'CL' % Capacitive load
                    C{k} = sprintf('%.3f pF', v);

                % --- Quantities without units or pure numbers (integer format) ---
                case {'gen', 'index', 'RUN'}
                    C{k} = sprintf('%d', v);
                
                % --- Default: quantities without specific units (such as FOM, fitness, d_settle) ---
                otherwise
                    C{k} = sprintf('%.3g', v); % Use .3g format for generality
            end
        else
            % --- For non-numeric types (such as Topo), directly convert to char ---
            C{k} = char(string(v));
        end
    end
end

% =============================================================
% Helper Function: Format number with engineering unit (M, k, m, µ, n, etc.)
% =============================================================
function str = formatWithEngUnit(val, baseUnit)
    % Input:
    %   val: value
    %   baseUnit: base unit string, e.g., 'V', 'Hz', 's', 'A'
    
    if val == 0
        str = sprintf('0 %s', baseUnit);
        return;
    end

    % Engineering prefixes and corresponding orders of magnitude
    prefixes = {'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', '', 'm', 'µ', 'n', 'p', 'f', 'a', 'z', 'y'};
    exponents = [24, 21, 18, 15, 12, 9, 6, 3, 0, -3, -6, -9, -12, -15, -18, -21, -24];
    
    % Calculate the exponent of the value
    val_exp = floor(log10(abs(val)));
    
    % Find the closest engineering exponent (multiple of 3)
    best_exp_idx = 1;
    min_diff = inf;
    for i = 1:length(exponents)
        diff = abs(val_exp - exponents(i));
        if diff < min_diff
            min_diff = diff;
            best_exp_idx = i;
        end
    end
    
    % If the value itself is in the range [1, 1000), do not use a prefix
    if val_exp >= 0 && val_exp < 3
        best_exp_idx = find(exponents == 0);
    end

    % Use the found best exponent for conversion
    p = prefixes{best_exp_idx};
    exp_val = exponents(best_exp_idx);
    
    scaled_val = val / (10^exp_val);
    
    % Determine the number of decimal places based on the value size
    if abs(scaled_val) >= 100
        fmt = '%.1f';
    elseif abs(scaled_val) >= 10
        fmt = '%.2f';
    else
        fmt = '%.3f';
    end
    
    % Combine into the final string
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