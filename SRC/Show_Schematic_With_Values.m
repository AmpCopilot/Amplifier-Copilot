function hAx = Show_Schematic_With_Values(Perf_Table,idx,Database_dir,...
                                          hAx,LabelFontSize,mode)
if nargin<6 || isempty(mode), mode = 'WL'; end   % mode = 'WL' | 'GMFT'% 根据 Label_data.csv 把尺寸 / 数值渲染到原理图上
% Label_data.csv 必须含 Element,X,Y,Factor (Factor 缺失时默认 1)

% ---------- 路径 -------------------------------------------------------
row    = Perf_Table(idx,:);
topo   = string(row.Topo);
guiDir = fullfile(Database_dir,topo,'GUI_data');
pngF   = fullfile(guiDir,topo+".png");
csvF   = fullfile(guiDir,'Label_data.csv');
if ~isfile(pngF)||~isfile(csvF), error('缺 png 或 csv'); end

[SzTBM,~] = Get_Size_TBM_Figure(Perf_Table,idx,Database_dir);
vnames    = SzTBM.Properties.VariableNames;

L = readtable(csvF,'TextType','string');
if ~ismember('Factor',L.Properties.VariableNames)
    L.Factor = ones(height(L),1);
end

% ---------- 显示图 -----------------------------------------------------
% img = imcomplement(imread(pngF));
img = (imread(pngF));

if nargin<4||isempty(hAx)
    hAx = axes('Parent',figure('Name','Values on Schematic'));
else
    cla(hAx,'reset');
end
imshow(img,'Parent',hAx); hold(hAx,'on');

% ---------- 逐元素写值 -------------------------------------------------
for k = 1:height(L)
    elem = string(L.Element(k)); x=L.X(k); y=L.Y(k); f=L.Factor(k);
    txt  = str4elem(elem,vnames,SzTBM,f,mode);
    if txt=="", txt="N/A"; end
    text(hAx,x,y,txt,'Color','r','FontSize',LabelFontSize,'FontWeight','bold',...
        'Interpreter','tex',...
        'HorizontalAlignment','left','VerticalAlignment','middle');
end
hold(hAx,'off');
end

%========================= 辅助函数 =====================================
function s = str4elem(elem,vnames,T,f,mode)
    s = "";
    if startsWith(elem,'MOSFET_','IgnoreCase',true)
        id   = extractAfter(elem,'MOSFET_');
        Wcol = firstCol(vnames,"MOSFET_"+id+"_","_W_");
        Lcol = firstCol(vnames,"MOSFET_"+id+"_","_L_");
        Mcol = firstCol(vnames,"MOSFET_"+id+"_","_M_");
        gcol = firstCol(vnames,"gm"+replace(id,"_",""));
        ftcol= firstCol(vnames,"ft"+replace(id,"_",""));

        if any(cellfun(@isempty,{Wcol,Lcol,Mcol})) , return; end

        switch upper(mode)
            case 'WL'
                W = T{1,Wcol};  L = T{1,Lcol};  M = T{1,Mcol};
                s = sprintf('W=%.2g, M=%u \\newline NF=%u, L=%.2g',W,M,f,L);
            otherwise  % 'GMFT'
                gm = []; ft = [];
                if ~isempty(gcol),  gm = T{1,gcol}; end
                if ~isempty(ftcol), ft = T{1,ftcol}; end
                if isempty(gm) && isempty(ft),  return; end
                if isempty(gm), gm = NaN; end
                if isempty(ft), ft = NaN; end
                s = sprintf('g_m=%.2e\\newline f_t=%.1g',gm,ft);
        end

    elseif any(startsWith(elem,["RESISTOR_","CAPACITOR_","CURRENT_"],'IgnoreCase',true))
        col = firstCol(vnames,elem);
        if ~isempty(col)
            val = T{1,col};
            s   = sprintf('%g',f*val);
        end
    end
end

function col = firstCol(vnames,prefix,mid)
    if nargin==3
        m = startsWith(vnames,prefix)&contains(vnames,mid);
    else
        m = startsWith(vnames,prefix);
    end
    if any(m), col=vnames{find(m,1)}; else, col=""; end
end