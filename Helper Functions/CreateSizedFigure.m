function fh = CreateSizedFigure(varargin)
% fh = CreateSizedFigure(varargin)
%
% Function to create a figure window with specified dimensions 
% 
% A variable number of arguments can be passed to specify the figure
% parameters
%
% If the numeric arguments are passed, the first will be interpreted as the
% desired width and the second as the height.  Default dimensions are the 
% same as for a normal matlab figure (5.5 x 4)
% 
% Valid string argument pairs should be joined with a '='
%   {'vis' 'visibility'}={'true' 'false' '0' '1'}: default visible
%   'units'={'in' 'inches' 'cm' 'centimeters'}: default inches
%
% For examples, to create an invisible figure that is 4x5 cm
%   fh = CreateSizeFigure(4,5,'units=cm','vis=false')

% Parse varargin - note: need to do some checking so that everything
% behaves the same if args are passed form the command line or from a
% function
if isa(varargin,'cell') && numel(varargin)==1
    args = varargin{1};
else
    args = varargin;
end
numcount = 0;
for ii = 1:length(args)
    if isa(args,'cell')
        arg = args{ii};
    else
        arg = args;
    end
    if isa(arg,'numeric')
        if numcount == 0;
            width = arg;
            numcount = 1;
        elseif numcount == 1
            height = arg;
            numcount = 2;
        else
            error('CreateSizedFigure: too many numeric arguments');
        end
    elseif isa(arg,'char')
        if ~isempty(strfind(lower(arg),'vis'))
            tmp = regexp(arg,'=','split');
            visible = tmp{2};
            switch lower(visible)
                case {'true' '1'}
                    visible = true;
                case {'false' '0'}
                    visible = false;
                otherwise
                    error('CreateSizedFigure: unknown visibility flag %s',visible);
            end
        elseif ~isempty(strfind(lower(arg),'units'))
            tmp = regexp(arg,'=','split');
            switch lower(tmp{2})
                case {'inches' 'in'}
                    units = 'inches';
                case {'centimeters' 'cm'}
                    units = 'centimeters';
                otherwise
                    error('CreateSizedFigure: unknown visibility flag %s',tmp{2});
            end
        else
            error('CreateSizedFigure: unknown argument %s',arg);
        end
    end
end

% Set default values
if ~exist('width','var')
    width = 5.5;
end
if ~exist('height','var')
    height = 4;
end
if ~exist('units','var')
    units = 'inches';
end
if ~exist('visible','var')
    visible = true;
end

% Create a figure window which is in the middle of the screen and sized
% correctly
screen_units = get(0,'Units');
set(0,'Units',units);
ScreenSize = get(0,'ScreenSize');
set(0,'Units',screen_units);
new_figure_size = [(ScreenSize(3)/2-width/2),(ScreenSize(4)/2-height/2),...
    width,height];
if ScreenSize(3) > 24 % correct position in dual screen mode
    new_figure_size = new_figure_size - [new_figure_size(1)/2 new_figure_size(2)/2 0 0];
end
fh = figure('Visible','off');
% set(fh,'Visible','off'); %,'Menubar','none');
set(fh,'Units',units);
set(fh,'PaperUnits',units);
% set(fh,'Menubar','none');
if width>height
    set(fh,'PaperOrientation','landscape'); % default is portrait
end
set(fh,'Position',new_figure_size);
set(fh,'PaperSize',[width height]);
set(fh,'PaperPosition',[0 0 width height]);

if visible
    set(fh,'Visible','on');
end

% 
% % Put some data in the figure and save as an EPS
% t = linspace(0,2*pi,100);
% y = sin(t);
% plot(t,y);
% print -depsc sin_4x3.eps