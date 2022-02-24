classdef dataPlotterClass < handle
    % Define an object class that organizes data for creating bar plots
    
    properties
        ah
        groupType
        errorType
        ConditionLabels
        ClassLabels
        PlotHandles
        DataDict
        titleStr
        yLabelStr
        xLabelStr
        fontsize
        colors
        showDataPts
        dataPtHandles
        renderType
        validTypes
        legendLocation
    end
    
    methods
        
        function obj = dataPlotterClass(~)
            if nargin > 0
                obj.ah = axes('Parent',figure);
            else
                obj.ah = [];
            end
            obj.ConditionLabels = {};
            obj.ClassLabels = {};
            obj.PlotHandles = gobjects;
            obj.DataDict = containers.Map;
            obj.groupType = 'Condition';
            obj.errorType = 'StdErr';
            obj.titleStr = '';
            obj.yLabelStr = '';
            obj.xLabelStr = '';
            obj.fontsize = 14;
            obj.colors = [0 0 1;...
                0 0.5 0;...
                1 0 0;...
                1 1 0; ...
                RGBColor('Cornflower Blue');...
                RGBColor('Maroon');...
                RGBColor('Goldenrod');...
                RGBColor('Pale Green');
                RGBColor('Pale Turquoise');...
                RGBColor('Olive Drab');
                RGBColor('Dark Orchid')];
            obj.showDataPts = false;
            obj.dataPtHandles = gobjects;
            obj.renderType = 'bar';
            obj.validTypes = {'bar','box','notched box','line'};
            obj.legendLocation = 'NorthEast';
        end
        
        function resetData(obj)
            obj.ConditionLabels = {};
            obj.ClassLabels = {};
            delete(obj.DataDict);
            obj.DataDict = containers.Map;
        end
        
        function setTitle(obj,title)
            obj.titleStr = title;
        end
        
        function setYLabel(obj,yLabel)
            obj.yLabelStr = yLabel;
        end
        
        function setXLabel(obj,xLabel)
            obj.xLabelStr = xLabel;
        end
        
        function setYlim(obj,newLims)
            if nargin == 1 || isempty(newLims)
                set(obj.ah,'YLimMode','auto');
            else
                set(obj.ah,'YLim',newLims);
            end
        end
        
        function setXlim(obj,newLims)
            if nargin == 1 || isempty(newLims)
                set(obj.ah,'YLimMode','auto');
            else
                set(obj.ah,'XLim',newLims);
            end
        end
        
        function setLegendLocation(obj,location)
            lh = findobj(get(obj.ah,'parent'),'Tag','legend');
            if ~isempty(lh)
                set(lh,'Location',location);
            end
            obj.legendLocation = location;
        end
        
        function addData(obj,Condition,Class,data)
            if ~isnumeric(data)
                errstr = sprintf('%s.addData: data must be numeric',...
                    class(obj));
                if isdeployed
                    errordlg(errstr,class(obj));
                end
                error(errstr); %#ok<SPERR>
            end
            if min(size(data)) > 1
                errstr = sprintf('%s.addData: data must be a 1-d array',...
                    class(obj));
                errordlg(errstr,class(obj));
                error(errstr); %#ok<SPERR>
            end
            if sum(strcmp(obj.ConditionLabels,Condition)) == 0
                obj.ConditionLabels{end+1} = Condition;
            end
            if sum(strcmp(obj.ClassLabels,Class)) == 0
                obj.ClassLabels{end+1} = Class;
            end
            dataKey = sprintf('%s_%s',Condition,Class);
            obj.DataDict(dataKey) = data;
        end
        
        function toggleGroupType(obj)
            if strcmp(obj.groupType,'Condition')
                obj.groupType = 'Class';
            else
                obj.groupType = 'Condition';
            end
            render(obj);
        end
        
        function toggleShowDataPts(obj)
            obj.showDataPts = ~obj.showDataPts;
            render(obj);
        end
        
        function setRenderType(obj,type)
            if sum(strcmpi((type),obj.validTypes))
                obj.renderType = lower(type);
            else
                error('dataPlotterClass.setRenderType: unknown type %s',type);
            end
        end
        
        function render(obj)
            % Render the data
            
            % Make sure the axes is valid
            if isempty(obj.ah) || ~ishandle(obj.ah)
                warndlg(sprintf(...
                    '%s.render: invalid axes, data will not render',...
                    class(obj)),sprintf('%s',class(obj)));
                return
            end
            try
                % Remove any existing plot handles
                delete([obj.PlotHandles]);
                delete(obj.dataPtHandles);
                obj.PlotHandles = gobjects;
                % Figure out groupings
                switch obj.groupType
                    case 'Condition'
                        grpLabels = obj.ConditionLabels;
                        legLabels = obj.ClassLabels;
                    case 'Class'
                        grpLabels = obj.ClassLabels;
                        legLabels = obj.ConditionLabels;
                end
                nG = length(grpLabels);
                nC = length(legLabels);
                % Type specific rendering
                switch obj.renderType
                    case 'bar'
                        renderBars(obj,grpLabels,legLabels,nG,nC);
                    case 'box'
                        renderBoxes(obj,grpLabels,legLabels,nG,nC);
                    case 'notched box'
                        renderBoxes(obj,grpLabels,legLabels,nG,nC,'on');
                    case 'lines'
                        renderLines(obj,grpLabels,legLabels,nG,nC);
                end
            catch ME
                errstr = sprintf('%s.render error\n%s',...
                    class(obj),getReport(ME));
                if isdeployed
                    errordlg(errstr,class(obj));
                else
                    error(errstr); %#ok<SPERR>
                end
            end
        end
        
        function renderBars(obj,grpLabels,legLabels,nG,nC)
            % Render as bar plot
            
            % Calculate the bar widths and centers based on the group
            % spacing
            gC = 1:nG; % centers of groupings
            gW = 1; % width of groupings
            cC0 = gW*(1:nC)/(nC+1); % baseline spacing of bar centers within condition
            bW = 0.9*cC0(1); % width of each bar
            % draw the bars with errors
            hold(obj.ah,'on');
            dataKeys = obj.DataDict.keys;
            % Make sure there are enough colors to show all of the bars
            % uniquely
            nColors = length(legLabels);
            if nColors > length(obj.colors)
                theColors = jet(nColors);
            else
                theColors = obj.colors;
            end
            
            for iK = 1:numel(dataKeys)
                % Figure out indici based on the dataKey and groupType
                dataKey = dataKeys{iK};
                parts = regexp(dataKey,'_','split');
                theCond = parts{1};
                theClass = parts{2};
                switch obj.groupType
                    case 'Condition'
                        iG = strcmp(grpLabels,theCond);
                        iC = strcmp(legLabels,theClass);
                    case 'Class'
                        iC = strcmp(legLabels,theCond);
                        iG = strcmp(grpLabels,theClass);
                end
                % Plot the data
                data = obj.DataDict(dataKey);
                mu = mean(data);
                n = length(data);
                sterr = std(data)/sqrt(n);
                stddev = std(data);
                % Calculate the rectangle that describes the bar
                bC = gC(iG)-gW/2 * 1+cC0(iC); % bar center location
                %Xrect = bC + [-bW bW bW -bW]/2;
                %Yrect = [0 0 mu mu];
                Xrect = bC + [-bW -bW bW bW]/2;
                Yrect = [0 mu mu 0];
                % Draw the bar and errors in the application window
                % color = obj.colors(iC,:);
                color = theColors(iC,:);
                bar = area(obj.ah,Xrect,Yrect,'facecolor',color);
                % Setup the call-back for button clicks on the bars
                switch obj.errorType
                    case 'StdErr'
                        errSrc = sterr;
                    case 'StdDev'
                        errSrc = stddev;
                end
                errSrc(mu<0) = -errSrc(mu<0); % draw bar down for negative values
                err = plot(obj.ah,[bC bC],mu+[0 errSrc],'color','k');
                obj.PlotHandles(end+1:end+2) = [bar err];
                % Render individual data points on top of bar
                if obj.showDataPts
                    obj.PlotHandles(end+1) = plot(obj.ah,...
                        bC * ones(1,n),data,'linestyle','none',...
                        'marker','o','color',[0 0 0]);
                    % obj.PlotHandles(end+1) = plot(obj.ah,...
                    %     bC * ones(1,n) + bW*0.1*(rand(1,n)-0.5),data,'linestyle','none',...
                    %     'marker','o','color',[0 0 0]);
                end
            end
            hold(obj.ah,'off');
            % Format the plot
            set(obj.ah,'xlim',[gC(1)-gW/2 gC(end)+gW/2]);
            set(obj.ah,'XTick',gC,'XTickLabel',grpLabels,...
                'fontsize',obj.fontsize)
            if ~isempty(obj.titleStr)
                title(obj.ah,obj.titleStr,'fontsize',obj.fontsize)
            end
            if ~isempty(obj.yLabelStr)
                ylabel(obj.ah,obj.yLabelStr,'fontsize',obj.fontsize);
            end
            if ~isempty(obj.xLabelStr)
                xlabel(obj.ah,obj.xLabelStr,'fontsize',obj.fontsize);
            end
            % Create a legend using the scribe.legend class to select
            % which objects to display - one entry for each color bar
            % on the plot
            leg_handles = zeros(1,nC);
            for iC = 1:nC
                hs = findobj(obj.PlotHandles,'facecolor',...
                    theColors(iC,:));
                if ~isempty(hs)
                    leg_handles(iC) = hs(1);
                end
            end
            leg_handles = leg_handles(leg_handles ~= 0);
            if verLessThan('matlab', '7.11') % R2010b
                % Could probably just use legend for everything, but I know
                % this works with older versions and don't want to reverify
                propargs = {}; % linewidth and things like that?
                listen = false; % dynamic positioning
                lh = scribe.legend(obj.ah,'vertical',obj.legendLocation,-1,...
                    leg_handles,listen,legLabels,propargs{:});
            else
                lh = legend(obj.ah,leg_handles,legLabels,...
                    'Location',obj.legendLocation);
            end
            obj.PlotHandles(end+1) = double(lh);
        end
        
        function renderBoxes(obj,grpLabels,legLabels,nG,nC,useNotch)
            % Render as box and whisker plot
            if nargin < 6
                useNotch = 'off';
            end
            
            % Calculate the bar widths and centers based on the group
            % spacing
            gC = 1:nG; % centers of groupings
            gW = 1; % width of groupings
            cC0 = gW*(1:nC)/(nC+1); % baseline spacing of bar centers within condition
            bW = 0.9*cC0(1); % width of each bar
            % draw the bars with errors
            hold(obj.ah,'on');
            dataKeys = obj.DataDict.keys;
            for iK = 1:numel(dataKeys)
                % Figure out indici based on the dataKey and groupType
                dataKey = dataKeys{iK};
                parts = regexp(dataKey,'_','split');
                theCond = parts{1};
                theClass = parts{2};
                switch obj.groupType
                    case 'Condition'
                        iG = strcmp(grpLabels,theCond);
                        iC = strcmp(legLabels,theClass);
                    case 'Class'
                        iC = strcmp(legLabels,theCond);
                        iG = strcmp(grpLabels,theClass);
                end
                
                % Calculate the 1st-3rd quantiles
                data = obj.DataDict(dataKey);
                q2 = median(data);
                q1 = median(data(data < q2));
                q3 = mean(data(data > q2));
                % Identify and remove outliers - whiskers no longer than
                % 1.5xIQR
                W = 1.5;
                iqr = q3-q1;
                iOutPlus = data > q3+W*iqr;
                iOutMinus = data < q1-W*iqr;
                iOutliers = iOutPlus | iOutMinus;
                outliers = data(iOutliers);
                data = data(~iOutliers);
                % Recalculate the quantiles
                q2 = median(data);
                q1 = median(data(data < q2));
                q3 = mean(data(data > q2));
                
                % Draw the box whiskers, and any outliers
                theColor = obj.colors(iC,:);
                args = {'color',theColor,'linewidth',2};
                bC = gC(iG)-gW/2 * 1+cC0(iC); % box center location
                switch useNotch
                    case 'on'
                        % Notches are +- 1.58 x IQR / srqt(n) which is
                        % about equivalent to 95% confidence intervals
                        nh = 1.58*iqr/sqrt(length(data)); % Notch height
                        xRect = bC+[-bW,bW,bW,bW/2,bW,bW,-bW,-bW,-bW/2,-bW,-bW]/2;
                        yRect = [q1,q1,q2-nh,q2,q2+nh,q3,q3,q2+nh,q2,q2-nh,q1];
                        p1 = plot(obj.ah,bC+[-bW bW]/4,[q2 q2],args{:});
                    otherwise
                        xRect = bC + [-bW bW bW -bW -bW]/2;
                        yRect = [q1 q1 q3 q3 q1];
                        p1 = plot(obj.ah,bC+[-bW bW]/2,[q2 q2],args{:});
                end
                p2 = plot(obj.ah,xRect,yRect,args{:});
                p3 = plot(obj.ah,[bC bC],[q3 max(data)],args{:});
                p4 = plot(obj.ah,[bC bC],[q1 min(data)],args{:});
                obj.PlotHandles(end+(1:4)) = [p1 p2 p3 p4];
                nOut = sum(iOutliers);
                if nOut > 0
                    obj.PlotHandles(end+(1)) = ...
                        plot(obj.ah,bC*ones(1,nOut),outliers,'color',...
                        theColor,'Marker','*','LineStyle','none');
                end
                % Render individual data points on top of bar
                if obj.showDataPts
                    obj.PlotHandles(end+1) = plot(obj.ah,...
                        bC * ones(1,length(data))+0.015*randn(1,length(data)),data,...
                        'linestyle','none',...
                        'marker','o','color',[0 0 0]);
                end
            end
            hold(obj.ah,'off');
            % Format the plot
            set(obj.ah,'xlim',[gC(1)-gW/2 gC(end)+gW/2]);
            set(obj.ah,'XTick',gC,'XTickLabel',grpLabels,...
                'fontsize',obj.fontsize)
            if ~isempty(obj.titleStr)
                title(obj.ah,obj.titleStr,'fontsize',obj.fontsize)
            end
            if ~isempty(obj.yLabelStr)
                ylabel(obj.ah,obj.yLabelStr,'fontsize',obj.fontsize);
            end
            if ~isempty(obj.xLabelStr)
                xlabel(obj.ah,obj.xLabelStr,'fontsize',obj.fontsize);
            end
            % Create a legend using the scribe.legend class to select
            % which objects to display - one entry for each color bar
            % on the plot
            leg_handles = zeros(1,nC);
            for iC = 1:nC
                hs = findobj(obj.PlotHandles,'color',...
                    obj.colors(iC,:));
                if ~isempty(hs)
                    leg_handles(iC) = hs(1);
                end
            end
            leg_handles = leg_handles(leg_handles ~= 0);
            if verLessThan('matlab', '7.11') % R2010b
                % Could probably just use legend for everything, but I know
                % this works with older versions and don't want to reverify
                propargs = {}; % linewidth and things like that?
                listen = false; % dynamic positioning
                lh = scribe.legend(obj.ah,'vertical',obj.legendLocation,-1,...
                    leg_handles,listen,legLabels,propargs{:});
            else
                lh = legend(obj.ah,leg_handles,legLabels,...
                    'Location',obj.legendLocation);
            end
            %obj.PlotHandles(end+1) = double(lh);
            obj.PlotHandles(end+1) = lh;
        end
        
        
        function renderLines(obj,grpLabels,legLabels,nG,nC)
            %             % Render as line plots
            %
            %             dataPoints = [];
            %             labels = {};
            %
            %             for iK = 1:numel(dataKeys)
            %                 % Figure out indici based on the dataKey and groupType
            %                 dataKey = dataKeys{iK};
            %                 data = obj.DataDict(dataKey);
            %
            %             end
            %             hold(obj.ah,'off');
            %             % Format the plot
            %             set(obj.ah,'xlim',[gC(1)-gW/2 gC(end)+gW/2]);
            %             set(obj.ah,'XTick',gC,'XTickLabel',grpLabels,...
            %                 'fontsize',obj.fontsize)
            %             if ~isempty(obj.titleStr)
            %                 title(obj.ah,obj.titleStr,'fontsize',obj.fontsize)
            %             end
            %             if ~isempty(obj.yLabelStr)
            %                 ylabel(obj.ah,obj.yLabelStr,'fontsize',obj.fontsize);
            %             end
            %             if ~isempty(obj.xLabelStr)
            %                 xlabel(obj.ah,obj.xLabelStr,'fontsize',obj.fontsize);
            %             end
            %             % Create a legend using the scribe.legend class to select
            %             % which objects to display - one entry for each color bar
            %             % on the plot
            %             leg_handles = zeros(1,nC);
            %             for iC = 1:nC
            %                 hs = findobj(obj.PlotHandles,'facecolor',...
            %                     obj.colors(iC,:));
            %                 if ~isempty(hs)
            %                     leg_handles(iC) = hs(1);
            %                 end
            %             end
            %             leg_handles = leg_handles(leg_handles ~= 0);
            %             propargs = {}; % linewidth and things like that?
            %             listen = false; % dynamic positioning
            %             lh = scribe.legend(obj.ah,'vertical','NorthEast',-1,...
            %                 leg_handles,listen,legLabels,propargs{:});
            %             obj.PlotHandles(end+1) = double(lh);
        end
        
    end
    
end

