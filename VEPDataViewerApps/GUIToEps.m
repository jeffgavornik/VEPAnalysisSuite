function fh = GUIToEps(handles)

fh = CreateSizedFigure(7.5,5.5,'vis=false');
% titlestr = '';

newHandles = zeros(size(handles));
for ii = 1:numel(handles)
    newHandles(ii) = copyobj(handles(ii),fh);
end

set(fh,'Visible','on');