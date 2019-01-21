function sensor = InitializeSensor(sim, iAgent, iTarget, regionRadius, detectBeta, agent, target, R)

sensor.id = [iAgent,iTarget];
property = sim.flagSensor;
flagPlot = sim.flagPlot;

switch property
    case 'PosLinear'
        dimension = length(target.x);
        
        sensor.y = nan(dimension,1);
        sensor.hist.y(:,1) = sensor.y;
        
        sensor.param.H = eye(dimension); % directly observe (linear/gaussian)
        
        if flagPlot
            if dimension == 2 % 2D
                sensor.plot.y = plot(sensor.y(1),sensor.y(2),'rx');
                sensor.param.R = R(1:2,1:2);
                sensor.param.H = eye(2);
            elseif dimension == 3 % 3D
                sensor.plot.y = plot3(sensor.y(1),sensor.y(2),sensor.y(3),'rx');                
                sensor.param.R = R;
                sensor.param.H = eye(3);
            end
        end
        
    case 'range_bear'
    
    case 'detection'
        sensor.y = nan;
        sensor.hist.y(:,1) = sensor.y;
        
        sensor.param.regionRadius = regionRadius; % sensing region radius
        sensor.param.detectBeta = detectBeta; % bernoulli detection parameter
        
        if flagPlot && iTarget == 1
            % plotting parameter setting
            sensor.plot.clr.detect = [0 1 0]; % green
            sensor.plot.clr.noDetect = [1 0 0]; % red
            sensor.plot.clr.opaqueValue = 0.1; % transparent value
            sensor.plot.bDetect = 0; % binary value for sening alarm
            sensor.plot.hist.bDetect(:,1) = sensor.plot.bDetect;
            
            % field of view plot
            [sensor.plot.data.x,sensor.plot.data.y,sensor.plot.fov] = ...
                GetCircleData(agent.s(1),agent.s(2),...
                sensor.param.regionRadius,...
                sensor.plot.clr.noDetect,...
                sensor.plot.clr.opaqueValue); hold on;
            sensor.plot.hist.data.x(:,1) = sensor.plot.data.x';
            sensor.plot.hist.data.y(:,1) = sensor.plot.data.y';
        end
        
end

end