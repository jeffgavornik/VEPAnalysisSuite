classdef figureObject_v2 < handle
    
    properties
        
        fh % handle of figure
        sps % handles of each subplot
        phs % handles to plots 
        % rows and cols define the number of subplots on the figure
        rows 
        cols 
    end
    
    methods
        
        % Constructor
        function obj = figureObject_v2(varargin)
            % Parse varargin
            % if an argument is passed with the form 'nPlots=x'
            % read the value of x and remove this argment from the
            % varargin cell array
            indici = true(1,length(varargin));
            for ii = 1:length(varargin)
                if isa(varargin,'cell')
                    arg = varargin{ii};
                else
                    arg = varargin;
                end
                if isa(arg,'char')
                    if ~isempty(strfind(lower(arg),'np')) % if nPlots=x
                        tmp = regexp(arg,'=','split');
                        nPlots = str2double(tmp{2});
                        indici(ii) = false;
                    end
                end
            end
            varargin = varargin(indici);
            if ~exist('nPlots','var')
                nPlots = 0;
            end
            
            % Create the figure window and create subplots
            obj.fh = CreateSizedFigure(varargin);
            obj.sps = [];
            obj.createSubplots(nPlots);
            
        end
        
        % Create subplots on the figure window
        function createSubplots(obj,nPlots)
            if nPlots > 2
                obj.cols = 3;
                obj.rows = ceil(nPlots/3);
            else
                obj.cols = nPlots;
                obj.rows = 1;
            end
            for ii = 1:nPlots
                obj.sps(ii) = subplot(obj.rows,obj.cols,ii);
                obj.phs{ii} = [];
            end
        end
        
        % Create axes and save
        function ah = makeAxes(obj,varargin)
            obj.makeCurrent;
            plotNumber = length(obj.sps) + 1;
            ah = axes(varargin{:});
            obj.sps(plotNumber) = ah;
            obj.phs{plotNumber} = [];
        end
            
        
        % Issue plot command and save handles
        function ph = plot(obj,axn,varargin)
            if nargin < 2
                error('figureObject.plot: must specify subplot number');
            end
            sp = obj.sps(axn);
            nextPlot = get(sp,'NextPlot');
            if strcmp(nextPlot,'add') % hold is on, add plot handles to existing
                existing_handles = obj.phs{axn};
            else
                existing_handles = []; % hold is off, replace existing plot handles
            end
            ph = plot(sp,varargin{:});
            obj.phs{axn} = [existing_handles ph];
        end
        
        % Make this figure, and specified subplot, current but do not raise
        % or make visible
        function makeCurrent(obj,axn)
            set(0,'CurrentFigure',obj.fh);
            if nargin > 1
                set(gcf,'CurrentAxes',obj.sps(axn));
            end
        end
        
        % Set line widths and font sizes for presentation
        function makePresentable(obj)
            set_all_properties(obj.fh,'line','linewidth',2);
            set_all_properties(obj.fh,'text','fontsize',15);
            set_all_properties(obj.fh,'axes','fontsize',12);
        end
        
        function toggleVisibility(obj)
            curr = get(obj.fh,'visible');
            switch curr
                case 'on'
                    set(obj.fh,'visible','off');
                case 'off'
                    set(obj.fh,'visible','on');
            end
        end
        
        
        % Set the background color for all subplots
        function setAxesBGColor(obj,color)
            whitebg(obj.fh,color);
            set(obj.fh,'inverthardcopy','off');
        end
        
    end
    
    
end