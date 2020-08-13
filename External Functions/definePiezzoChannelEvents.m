function traceIndici = definePiezzoChannelEvents(stimEventValues,...
    eventValues,traceIndici)

% This function looks for the first instance of an event value in a
% sequence - so, for instance, if the flip and flop for a particular
% startle had event values of 1 and 2 with a 3 indicating a return to gray,
% the eventValues array would have stretches that look like [1 2 1 ... 3]
% This function should select only the first "1" value
%
% Note: this fails to work correctly if the event is defined by a single
% event value (i.e. no stim definition default behavior)


nE = numel(stimEventValues);
sEV = stimEventValues(1);
if nE == 1
    traceIndici(eventValues==sEV) = true;
else
    otherStimValues = stimEventValues(2:end);
    for iE = 1:numel(eventValues)
        eV = eventValues(iE);
        indexValue = false;
        % Consider this a valid event if the stim event value matches the
        % actual event value and it is the first event in the session or it
        % is preceded by an event value that is not an element of its own
        % stimulus definition grouping
        if eV == sEV
            if iE == 1 % first event
                indexValue = true;
            else % preceded by an event that is not part of its own stim group
                if sum(lastValue == otherStimValues) == 0
                    %fprintf('lastValue = %i thisValue = %i\n',lastValue,eV);
                    indexValue = true;
                end
            end
            traceIndici(iE) = indexValue;
        end
        lastValue = eV;
    end
end

% figure
% plot(eventValues);
% steps = 1:numel(eventValues);
% hold on
% plot(eventValues)
% plot(steps(traceIndici),eventValues(traceIndici),'ro');
% disp('hi')



% if sum(traceIndici) > 0
%     fprintf('stimValue %i count %i\n',sEV,sum(traceIndici));
% end