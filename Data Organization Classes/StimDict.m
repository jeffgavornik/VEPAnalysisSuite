classdef StimDict < containers.Map
  % Extend containers.Map to included a method to copy the map contents
  
  methods
    
    function obj = StimDict
      obj = obj@containers.Map;
    end
    
    function newObj = copy(obj)
      newObj = StimDict;
      for iK = 1:length(obj)
        subsasgn(newObj,substruct('()',obj.keys{iK}),obj.values{iK});
      end
    end
    
  end
  
end