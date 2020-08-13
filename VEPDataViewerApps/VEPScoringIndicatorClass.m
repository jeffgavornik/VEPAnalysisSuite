classdef VEPScoringIndicatorClass < handle
    % Object that manages a VEP score indicator.  Uses VEPScoreTickClass
    % objects to mark positive and negative score locations.  Associated
    % with a single plot instance.  Adjusts size of indicators based on the
    % yaxis
    
    
   properties
       voltagePlotHandle
       negMarker
       posMarker
       listenerHandles
       scoreStruct
       scoreStruct0
       scoreChanged
   end
   
   events
       ScoreChanged
   end
   
   methods
       
       function obj = VEPScoringIndicatorClass(voltagePlotHandle)
           obj.voltagePlotHandle = voltagePlotHandle;
           plotAxesHandle = get(voltagePlotHandle,'Parent');
           obj.negMarker = VEPScoreTickClass(voltagePlotHandle,...
               plotAxesHandle,[0 1],[0 1]);
           obj.negMarker.setVisible('off');
           obj.posMarker = VEPScoreTickClass(voltagePlotHandle,...
               plotAxesHandle,[0 1],[0 1]);
           obj.posMarker.setVisible('off');
           lh1 = addlistener(obj.negMarker,'DropComplete',...
               @obj.dropping_Callback);
           lh2 = addlistener(obj.posMarker,'DropComplete',...
               @obj.dropping_Callback);
           obj.listenerHandles = [lh1,lh2];
       end
       
       function delete(obj)
           delete(obj.listenerHandles);
       end
       
       % Update the score following a drag event
       function dropping_Callback(obj,varargin)
           obj.scoreStruct.iNeg = obj.negMarker.index;
           obj.scoreStruct.vNeg = obj.negMarker.vVal;
           obj.scoreStruct.negLatency = obj.negMarker.tVal;
           obj.scoreStruct.iPos = obj.posMarker.index;
           obj.scoreStruct.vPos = obj.posMarker.vVal;
           obj.scoreStruct.posLatency = obj.posMarker.tVal;
           obj.scoreStruct.vMag = obj.scoreStruct.vPos - ...
               obj.scoreStruct.vNeg;
           notify(obj,'ScoreChanged');
           obj.scoreChanged = true;
       end
       
       % Set the tick mark positions based on the passed score structure
       function setScore(obj,score)
           ah = get(obj.voltagePlotHandle,'Parent');
           yLim = get(ah,'YLim');
           scoreSize = 0.05*range(yLim);
           % fprintf('setScore range = %f, size = %f\n',range(yLim),scoreSize);
           obj.negMarker.setYData(scoreSize*[-1 1]+score.vNeg);
           obj.negMarker.setXData(score.negLatency*[1 1]);
           obj.negMarker.setScoreInfo(score.iNeg,score.vNeg,...
               score.negLatency);
           obj.posMarker.setYData(scoreSize*[-1 1]+score.vPos);
           obj.posMarker.setXData(score.posLatency*[1 1]);
           obj.posMarker.setScoreInfo(score.iPos,score.vPos,...
               score.posLatency);
           obj.scoreStruct = score;
           obj.scoreStruct0 = score;
           obj.scoreChanged = false;
           
       end
       
       % Return a score structure based on the current tick mark locations
       function scoreStruct = getScore(obj)
           scoreStruct = obj.scoreStruct;
       end
       
       % Build a string that contains scoring information
       function [scoreStr,vMag,neg,pos,negLat,posLat] = getScoreStr(obj)
           score = obj.scoreStruct;
           scoreStr = sprintf('Mag=%1.2f uV\n',score.vMag);
           scoreStr = sprintf('%sNeg:%1.2f@%i ms\n',scoreStr,...
               score.vNeg,round(1000*score.negLatency));
           scoreStr = sprintf('%sPos:%1.2f@%i ms\n',scoreStr,...
               score.vPos,round(1000*score.posLatency));
           vMag = score.vMag;
           neg = score.vNeg;
           pos = score.vPos;
           negLat = 1000*score.negLatency;
           posLat = 1000*score.posLatency;
       end
       
       % Turn visibility on or off
       function setVisible(obj,visible)
           obj.negMarker.setVisible(visible);
           obj.posMarker.setVisible(visible);
       end
       
       function toggleVisibility(obj)
           obj.negMarker.toggleVisible;
           obj.posMarker.toggleVisible;
       end
       
       % Make the tick marks dragable or static
       function enableScoring(obj,enable)
           if enable
               obj.negMarker.makeDragable;
               obj.posMarker.makeDragable;
           else
               obj.negMarker.makeStatic;
               obj.posMarker.makeStatic;
           end
       end
       
       % Reset original tick mark locations
       function restoreOriginalPosition(obj)
           obj.negMarker.restoreOriginalPosition();
           obj.posMarker.restoreOriginalPosition();
           obj.scoreStruct = obj.scoreStruct0;
           obj.scoreChanged = false;
       end
       
       % Return the x or y data for the tick marks
       function data = getData(obj,dataKey,PosOrNeg)
           % dataKey should be 'XData' or 'YData'
           switch PosOrNeg
               case 'pos'
                   dataSrc = obj.posMarker;
               case 'neg'
                   dataSrc = obj.negMarker;
           end
           data = dataSrc.getData(dataKey);
           obj.scoreChanged = false;
       end
        
       
   end
   
end