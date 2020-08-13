function fh2 = resizeExistingFigure(fh1,varargin)

% Create the new figure by passing the variable argument list to
% CreateSizedFigure
fh2 = CreateSizedFigure(varargin{:});

% Copy all of the children from fh1 to fh2
kids = get(fh1,'Children');
for iK = 1:numel(kids)
    copyobj(kids(iK),fh2);
end


