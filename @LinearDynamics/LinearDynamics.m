classdef LinearDynamics < Dynamics
    %LinearDynamics is a sub-class of Dynamics class
    
    properties
        
    end
    
    methods
        function o = LinearDynamics( CONTROL, CLOCK, id )
            o@Dynamics(CONTROL, CLOCK, id );
        end
        
        o = get( o, varargin );
    end
    
end

