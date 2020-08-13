function k = checkbox_menu(xHeader,varargin)
%CHECKBOX_MENU   Generate a menu of choices for user input.
%
%   Modification of matlab menu function, creates a menu where multiple
%   options can be selected via checkboxes.
%
%   CHOICE = CHECKBOX_MENU(HEADER, ITEM1, ITEM2, ... ) displays the HEADER
%   string followed in sequence by the menu-item strings: ITEM1, ITEM2,
%   ... ITEMn. Returns the numbers of all selected menu-item as CHOICE,
%   a vector value. There is no limit to the number of menu items.
%
%   CHOICE = MENU(HEADER, ITEMLIST) where ITEMLIST is a string, cell
%   array is also a valid syntax.
%
%   On most graphics terminals MENU will display the menu-items as push
%   buttons in a figure window, otherwise they will be given as a numbered
%   list in the command window (see example, below).
%
%   Example:
%       K = menu('Choose a color','Red','Blue','Green')
%       %creates a figure with buttons labeled 'Red', 'Blue' and 'Green'
%       %The button clicked by the user is returned as K (i.e. K = 2
%       implies that the user selected Blue).
%
%   See also MENU, UICONTROL, UIMENU, GUIDE.


%=========================================================================
% Check input
%-------------------------------------------------------------------------
if nargin < 2,
    disp('MENU: No menu items to choose from.')
    k=0;
    return;
elseif nargin==2 && iscell(varargin{1}),
    ArgsIn = varargin{1}; % a cell array was passed in
else
    ArgsIn = varargin;    % use the varargin cell array
end

selections = zeros(1,length(ArgsIn)); % set elements to one when checkmark is selected

%-------------------------------------------------------------------------
% Check computer type to see if we can use a GUI
%-------------------------------------------------------------------------
useGUI   = 1; % Assume we can use a GUI

if isunix,     % Unix?
    % useGUI = length(getenv('DISPLAY')) > 0;
    useGUI = ~isempty(getenv('DISPLAY'));
end % if

%-------------------------------------------------------------------------
% Create the appropriate menu
%-------------------------------------------------------------------------
if useGUI,
    % Create a GUI menu to aquire answer "k"
    k = local_GUImenu( xHeader, ArgsIn );
end % if

%%#########################################################################
%   END   :  main function "menu"
%%#########################################################################


%%#########################################################################
%  BEGIN  :  local function local_GUImenu
%%#########################################################################
    function k = local_GUImenu( xHeader, xcItems )
        
        % local function to display a Handle Graphics menu and return the user's
        % selection from that menu as an index into the xcItems cell array
        
        %=========================================================================
        % SET UP
        %=========================================================================
        % Set spacing and sizing parameters for the GUI elements
        %-------------------------------------------------------------------------
        MenuUnits   = 'pixels'; % units used for all HG objects
        textPadding = [22 12];   % extra [Width Height] on uicontrols to pad text
        uiGap       = 5;       % space between uicontrols
        uiBorder    = 10;       % space between edge of figure and any uicontol
        winTopGap   = 60;       % gap between top of screen and top of figure **
        winLeftGap  = 30;       % gap between side of screen and side of figure **
        winWideMin  = 140;      % minimin window width necessary to show title
        
        % ** "figure" ==> viewable figure. You must allow space for the OS to add
        % a title bar (aprx 42 points on Mac and Windows) and a window border
        % (usu 2-6 points). Otherwise user cannot move the window.
        
        %-------------------------------------------------------------------------
        % Calculate the number of items in the menu
        %-------------------------------------------------------------------------
        numItems = length( xcItems ) + 1;
        
        %=========================================================================
        % BUILD
        %=========================================================================
        % Create a generically-sized invisible figure window
        %------------------------------------------------------------------------
        menuFig = figure( 'Units'       ,MenuUnits, ...
            'Visible'     ,'off', ...
            'NumberTitle' ,'off', ...
            'Name'        ,'MENU', ...
            'Resize'      ,'off', ...
            'Colormap'    ,[], ...
            'Menubar'     ,'none',...
            'Toolbar' 	,'none' ...
            );
        
        %------------------------------------------------------------------------
        % Add generically-sized header text with same background color as figure
        %------------------------------------------------------------------------
        hText = uicontrol( ...
            'style'       ,'text', ...
            'string'      ,xHeader, ...
            'units'       ,MenuUnits, ...
            'Position'    ,[ 100 100 100 20 ], ...
            'Horizontal'  ,'center',...
            'BackGround'  ,get(menuFig,'Color') );
        
        % Record extent of text string
        maxsize = get( hText, 'Extent' );
        textWide  = maxsize(3);
        textHigh  = maxsize(4);
        
        %------------------------------------------------------------------------
        % Add generically-spaced buttons below the header text
        %------------------------------------------------------------------------
        % Loop to add buttons in reverse order (to automatically initialize numitems).
        % Note that buttons may overlap, but are placed in correct position relative
        % to each other. They will be resized and spaced evenly later on.
        hBtn = zeros(numItems, 1);
        for idx = numItems : -1 : 2; % start from top of screen and go down
            n = numItems - idx + 1;  % start from 1st button and go to last
            % make a button
            hBtn(n) = uicontrol( ...
                'Style','Checkbox',...
                'units'          ,MenuUnits, ...
                'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
                'callback'       , {@checkbuttoncallback, n}, ...
                'string'         ,xcItems{n} );
        end % for
        n = numItems;
        hBtn(n) = uicontrol( ...
            'Style','pushbutton',...
            'units'          ,MenuUnits, ...
            'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
            'callback'       , @menucallback, ...
            'string'         ,'return' );
        
        %=========================================================================
        % TWEAK
        %=========================================================================
        % Calculate Optimal UIcontrol dimensions based on max text size
        %------------------------------------------------------------------------
        cAllExtents = get( hBtn, {'Extent'} );  % put all data in a cell array
        AllExtents  = cat( 1, cAllExtents{:} ); % convert to an n x 3 matrix
        maxsize     = max( AllExtents(:,3:4) ); % calculate the largest width & height
        maxsize     = maxsize + textPadding;    % add some blank space around text
        btnHigh     = maxsize(2);
        btnWide     = maxsize(1);
        
        %------------------------------------------------------------------------
        % Retrieve screen dimensions (in correct units)
        %------------------------------------------------------------------------
        screensize = get(0,'ScreenSize');  % record screensize
        
        %------------------------------------------------------------------------
        % How many rows and columns of buttons will fit in the screen?
        % Note: vertical space for buttons is the critical dimension
        % --window can't be moved up, but can be moved side-to-side
        %------------------------------------------------------------------------
        openSpace = screensize(4) - winTopGap - 2*uiBorder - textHigh;
        numRows = min( floor( openSpace/(btnHigh + uiGap) ), numItems );
        if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
        numCols = ceil( numItems/numRows );
        
        %------------------------------------------------------------------------
        % Resize figure to place it in top left of screen
        %------------------------------------------------------------------------
        % Calculate the window size needed to display all buttons
        winHigh = numRows*(btnHigh + uiGap) + textHigh + 2*uiBorder;
        winWide = numCols*(btnWide) + (numCols - 1)*uiGap + 2*uiBorder;
        
        % Make sure the text header fits
        if winWide < (2*uiBorder + textWide),
            winWide = 2*uiBorder + textWide;
        end
        
        % Make sure the dialog name can be shown
        if winWide < winWideMin %pixels
            winWide = winWideMin;
        end
        
        % Determine final placement coordinates for bottom of figure window
        bottom = screensize(4) - (winHigh + winTopGap);
        
        % Set figure window position
        set( menuFig, 'Position', [winLeftGap bottom winWide winHigh] );
        
        %------------------------------------------------------------------------
        % Size uicontrols to fit everyone in the window and see all text
        %------------------------------------------------------------------------
        % Calculate coordinates of bottom-left corner of all buttons
        xPos = ( uiBorder + (0:numCols-1)'*( btnWide + uiGap )*ones(1,numRows) )';
        xPos = xPos(1:numItems); % [ all 1st col; all 2nd col; ...; all nth col ]
        yPos = ( uiBorder + (numRows-1:-1:0)'*( btnHigh + uiGap )*ones(1,numCols) );
        yPos = yPos(1:numItems); % [ rows 1:m; rows 1:m; ...; rows 1:m ]
        
        % Combine with desired button size to get a cell array of position vectors
        allBtn   = ones(numItems,1);
        uiPosMtx = [ xPos(:), yPos(:), btnWide*allBtn, btnHigh*allBtn ];
        cUIPos   = num2cell( uiPosMtx( 1:numItems, : ), 2 );
        
        % adjust all buttons
        set( hBtn, {'Position'}, cUIPos );
        
        %------------------------------------------------------------------------
        % Align the Text and Buttons horizontally and distribute them vertically
        %------------------------------------------------------------------------
        
        % Calculate placement position of the Header
        textWide = winWide - 2*uiBorder;
        
        % Move Header text into correct position near the top of figure
        set( hText, ...
            'Position', [ uiBorder winHigh-uiBorder-textHigh textWide textHigh ] );
        
        %=========================================================================
        % ACTIVATE
        %=========================================================================
        % Make figure visible
        %------------------------------------------------------------------------
        set( menuFig, 'Visible', 'on' );
        
        %------------------------------------------------------------------------
        % Wait for choice to be made (i.e UserData must be assigned)...
        %------------------------------------------------------------------------
        waitfor(menuFig,'userdata')
        
        %------------------------------------------------------------------------
        % Selection has been made or figure has been deleted.
        % Assign k and delete the Menu figure if it is still valid.
        %------------------------------------------------------------------------
        if ishandle(menuFig)
            k = find(selections > 0);
            if isempty(k)
                k = 0;
            end
            %     k = get(menuFig,'userdata');
            delete(menuFig)
        else
            % The figure was deletd without a selection. Return 0.
            k = 0;
        end
    end

%%#########################################################################
%   END   :  local function local_GUImenu
%%#########################################################################
    function checkbuttoncallback(~, ~, index)
        if selections(index)
            selections(index) = 0;
        else
            selections(index) = 1;
        end
    end


    function menucallback(btn, evd)                                 %#ok
        set(gcbf, 'UserData', 1);
    end

end