
% Target Localization Problem Script
% Particle Method based Mutual Information
%
% two agents in the problem: 1st - receiving info / 2nd - tracking and
% measure information
%
%
% X(t+1) ~ P_ta(X(t+1)|X(t))
% Y(t)   ~ P_se(Y(t)|X(t);s(t))
%
% - coded by Sangwoo Moon
% - Created: 4/3/2018
% - 1st revision: 4/18/2018
% - 2nd revision: 6/25/2018
%   X(t+1) = X(t) + W                               : 2D-static Linear Gaussian
%   Y(t) = {0,1} with respect to Sensing Region     : 2D on the ground, circle region for target detection
%   s(t+1) = f(s(t),u(t))                           : u(t) = [0 -omega +omega]


close all;
clear;
% clc;
format compact;
hold on;

D2R = pi/180;
nSim = 1; % for Monte-Carlo approach


for iSim = 1:nSim
    
    %-------------------------------
    %   sim setting
    %-------------------------------
    
    %----------------------
    % simulation structure
    sim(iSim).nAgent = 2;
    sim(iSim).nTarget = 1;
    
    sim(iSim).flagScene = 0; % 0: stationary ground station | 1: moving ground station
    sim(iSim).flagInfoCom = 1; % 0: Ryan's approach | 1: Our approach(consider all measurements)
    sim(iSim).flagDM = 0; % 0: determined decisions | 1: DM enabled
    sim(iSim).flagPDF = 0; % 0: no PDF draw | 1: PDF draw
    
    if sim(iSim).flagPDF == 0
        sim(iSim).flagDisp.before = 0;
        sim(iSim).flagDisp.after = 0;
    else
        sim(iSim).flagDisp.before = 1;
        sim(iSim).flagDisp.after = 1;
    end
    
    sim(iSim).param.plot.dClock = 15; % interval of snapshot
    %----------------------
    
    %----------------------
    % clock structure
    clock.nt = 50;
    clock.dt = 1;
    clock.hist.time = 0;
    %----------------------
    
    %----------------------
    % field structure
    field.boundary = [-500 500 -500 500];
    field.length = [sim(iSim).field.boundary(2)-sim(iSim).field.boundary(1) sim(iSim).field.boundary(4)-sim(iSim).field.boundary(3)];
    field.buffer = 50; % for particle initalization
    sim(iSim).field.bufferZone = [sim(iSim).field.boundary(1)+sim(iSim).field.buffer sim(iSim).field.boundary(2)-sim(iSim).field.buffer...
        sim(iSim).field.boundary(3)+sim(iSim).field.buffer sim(iSim).field.boundary(4)-sim(iSim).field.buffer];
    sim(iSim).field.zoneLength = [sim(iSim).field.bufferZone(2)-sim(iSim).field.bufferZone(1) sim(iSim).field.bufferZone(4)-sim(iSim).field.bufferZone(3)];
    %----------------------
    
    %----------------------
    % target structure
    sim(iSim).target.id = 1;
    sim(iSim).target.x = [250 250]'; % x_pos, y_pos
    sim(iSim).target.hist.x = sim(iSim).target.x;
    sim(iSim).target.nState = length(sim(iSim).target.x);
    sim(iSim).target.param.F = eye(length(sim(iSim).target.x));
    sim(iSim).target.param.Q = zeros(sim(iSim).target.nState); % certainly ideal
    %----------------------
    
    %----------------------
    % agent structure
    
    % specific setting
    if sim(iSim).flagScene == 0
        sim(iSim).agent(1).id = 1;
        sim(iSim).agent(1).s = [-100 -100 rand()*2*pi 0]';
        sim(iSim).agent(1).hist.s = sim(iSim).agent(1).s;
    else
        sim(iSim).agent(1).id = 1;
        sim(iSim).agent(1).s = [-100 -100 rand()*2*pi 15]';
        sim(iSim).agent(1).hist.s = sim(iSim).agent(1).s;
    end
    sim(iSim).agent(2).id = 2;
    sim(iSim).agent(2).s = [250 150 0*2*pi 15]'; % target tracking setting
    sim(iSim).agent(2).hist.s = sim(iSim).agent(2).s;
    %----------------------
    
    %----------------------
    % sensor structure
    for iSensor = 1:sim(iSim).nAgent
        sim(iSim).sensor(iSensor).id = iSensor;
        sim(iSim).sensor(iSensor).y = nan;
        sim(iSim).sensor(iSensor).hist.y(:,1) = sim(iSim).sensor(iSensor).y;
        sim(iSim).sensor(iSensor).param.regionRadius = 300; % sensing region radius
        sim(iSim).sensor(iSensor).param.detectBeta = 0.9; % bernoulli detection parameter
    end
    %----------------------
    
    %----------------------
    % communicaiton structure
    for iComm = 1:sim(iSim).nAgent
        sim(iSim).comm(iComm).id = iComm;
        sim(iSim).comm(iComm).beta = nan(sim(iSim).nAgent,1);
        sim(iSim).comm(iComm).bConnect = nan(sim(iSim).nAgent,1);
        sim(iSim).comm(iComm).hist.beta(:,1) = sim(iSim).comm(iComm).beta; % for all agent and agent itself
        sim(iSim).comm(iComm).hist.bConnect(:,1) = sim(iSim).comm(iComm).bConnect; % for all agent and agent itself
    end
    %----------------------
    
    %----------------------
    % filter structure (Particle Filter)
    for iPF = 1:sim(iSim).nAgent
        sim(iSim).PF(iPF).id = iPF;
        sim(iSim).PF(iPF).nPt = 100;
        sim(iSim).PF(iPF).w = ones(1,sim(iSim).PF(iPF).nPt)./sim(iSim).PF(iPF).nPt;
        for iPt = 1 : sim(iSim).PF(iPF).nPt
            sim(iSim).PF(iPF).pt(:,iPt) = ...
                [sim(iSim).field.bufferZone(1)+rand()*sim(iSim).field.zoneLength(1) sim(iSim).field.bufferZone(3)+rand()*sim(iSim).field.zoneLength(2)]';
        end
        sim(iSim).PF(iPF).hist.pt = sim(iSim).PF(iPF).pt;
        sim(iSim).PF(iPF).param.F = sim(iSim).target.param.F; % assume target is stationary in PF
        sim(iSim).PF(iPF).param.Q = diag([40^2,40^2]);
        sim(iSim).PF(iPF).param.field = sim(iSim).field;
        sim(iSim).PF(iPF).nState = sim(iSim).target.nState;
    end
    %----------------------
    
    %----------------------
    % planner structure
    
    for iPlanner = 1:sim(iSim).nAgent
        
        sim(iSim).planner(iPlanner).id = iPlanner;
        
        sim(iSim).planner(iPlanner).param.clock.dt = 3; % planning time-step horizon
        sim(iSim).planner(iPlanner).param.clock.nT = 3; % planning horizon
        sim(iSim).planner(iPlanner).param.sA = 1; % sampled action
        
        % action profile setting
        % scenario #1: Agent 1 is statationary
        if sim(iSim).flagScene == 0
            if iPlanner == 1
                [sim(iSim).planner(iPlanner).action,sim(iSim).planner(iPlanner).actionNum,sim(iSim).planner(iPlanner).actionSetNum,sim(iSim).planner(iPlanner).actionSet] = ...
                    GenerateOutcomeProfile(0,sim(iSim).planner(iPlanner).param.clock.nT);
            else
                [sim(iSim).planner(iPlanner).action,sim(iSim).planner(iPlanner).actionNum,sim(iSim).planner(iPlanner).actionSetNum,sim(iSim).planner(iPlanner).actionSet] = ...
                    GenerateOutcomeProfile(8*D2R,sim(iSim).planner(iPlanner).param.clock.nT);
            end
            % scenario #2: Agent 1 is mobile
        else
            [sim(iSim).planner(iPlanner).action,sim(iSim).planner(iPlanner).actionNum,sim(iSim).planner(iPlanner).actionSetNum,sim(iSim).planner(iPlanner).actionSet] = ...
                GenerateOutcomeProfile(8*D2R,sim(iSim).planner(iPlanner).param.clock.nT);
        end
        
        % measurement profile setting
        [sim(iSim).planner(iPlanner).meas,sim(iSim).planner(iPlanner).measNum,sim(iSim).planner(iPlanner).measSetNum,sim(iSim).planner(iPlanner).measSet] = ...
            GenerateOutcomeProfile([0 1],sim(iSim).planner(iPlanner).param.clock.nT);
        
        % communication profile setting
        [sim(iSim).planner(iPlanner).comm,sim(iSim).planner(iPlanner).commNum,sim(iSim).planner(iPlanner).commSetNum,sim(iSim).planner(iPlanner).commSet] = ...
            GenerateOutcomeProfile([0 1],sim(iSim).planner(iPlanner).param.clock.nT);
        
        
        sim(iSim).planner(iPlanner).nPt = sim(iSim).PF(iPlanner).nPt;
        sim(iSim).planner(iPlanner).pt = sim(iSim).PF(iPlanner).pt;
        sim(iSim).planner(iPlanner).w = sim(iSim).PF(iPlanner).w;
        sim(iSim).planner(iPlanner).nState = sim(iSim).PF(iPlanner).nState;
        
        sim(iSim).planner(iPlanner).input = nan(sim(iSim).planner(iPlanner).param.clock.nT,1);
        sim(iSim).planner(iPlanner).actIdx = nan;
        sim(iSim).planner(iPlanner).hist.input = sim(iSim).planner(iPlanner).input;
        sim(iSim).planner(iPlanner).hist.actIdx = sim(iSim).planner(iPlanner).actIdx;
        
        sim(iSim).planner(iPlanner).I = nan;
        sim(iSim).planner(iPlanner).hist.I = sim(iSim).planner(iPlanner).I;
        sim(iSim).planner(iPlanner).hist.Hbefore = nan(sim(iSim).planner(iPlanner).param.clock.nT,1);
        sim(iSim).planner(iPlanner).hist.Hafter = nan(sim(iSim).planner(iPlanner).param.clock.nT,1);
        
        sim(iSim).planner(iPlanner).param.pdf.dRefPt = 50;
        [sim(iSim).planner(iPlanner).param.pdf.refPt(:,:,1), sim(iSim).planner(iPlanner).param.pdf.refPt(:,:,2)] = ...
            meshgrid(sim(iSim).field.boundary(1):sim(iSim).planner(iPlanner).param.pdf.dRefPt:sim(iSim).field.boundary(2),...
                     sim(iSim).field.boundary(3):sim(iSim).planner(iPlanner).param.pdf.dRefPt:sim(iSim).field.boundary(4));
        
        sim(iSim).planner(iPlanner).param.plot.row = sim(iSim).planner(iPlanner).param.clock.nT;
        sim(iSim).planner(iPlanner).param.plot.col = 2;
        
        sim(iSim).planner(iPlanner).param.F = sim(iSim).target.param.F;
        sim(iSim).planner(iPlanner).param.Q = sim(iSim).target.param.Q;
        sim(iSim).planner(iPlanner).param.sensor.regionRadius = sim(iSim).sensor(iPlanner).param.regionRadius;
        sim(iSim).planner(iPlanner).param.sensor.detectBeta = sim(iSim).sensor(iPlanner).param.detectBeta;
        
        sim(iSim).planner(iPlanner).param.field = sim(iSim).field;
        
        % agent state is used for communication awareness
        for iAgent = 1:sim.nAgent
            sim(iSim).planner(iPlanner).agent(iAgent).s = sim(iSim).agent(iAgent).s;
        end
    end
    %----------------------
    
    
    %-----------------------------------
    % Sim Operation
    %-----------------------------------
    
    for iClock = 1:clock.nt
        
        %-----------------------------------
        % PF-based Mutual information Computation and decision-making
        %-----------------------------------
        
        % compute future information with respect to action profiles
        % 1. sample among action profile
        % 2. compute entropy/mutual information with respect to sampled action
        % profile
        %
        % Here assume agent 2 only takes measurement
        % distributed scheme to each agent:
        % COMPUTED INFORMATION IS DIFFERENT WITH RESPECT TO AGENT
        for iAgent = 1:sim(iSim).nAgent
            sActNumSet = nan(1,sim(iSim).planner(1).param.sA);
            for iSample = 1 : sim(iSim).planner(1).param.sA
                
                % sample among action profile: depends on whether the simulation
                % uses optimization
                if sim(iSim).flagDM == 0
                    sActNum = 1;
                else
                    bRealInput = ones(1,sim(iSim).nAgent);
                    % check whether decision has feasibility in terms of
                    % geofence
                    while (bRealInput)
                        sActNum = 1+floor(rand(1)*sim(iSim).planner(iAgent).actionSetNum);
                        state = UpdateAgentState(sim(iSim).agent(iAgent).s,sim(iSim).planner(iAgent).actionSet(1,sActNum(iAgent,1)),clock.dt);
                        if (state(1) <= sim(iSim).field.bufferZone(1) || state(1) >= sim(iSim).field.bufferZone(2)) ...
                                || (state(2) <= field.bufferZone(3) || state(2) >= field.bufferZone(4)) % out of geofence
                            bRealInput(iAgent) = 0;
                        end
                    end
                end
                sActNumSet(:,iSample) = sActNum;
                
                if sim.flagInfoCom == 0
                    % Ryan's approach-based Mutual Information computation: Measurement sampling-based
                    [planner(iAgent).candidate.Hbefore(:,iSample),planner(iAgent).candidate.Hafter(:,iSample),planner(iAgent).candidate.I(iSample)] = ...
                        ComputeInformation(planner(iAgent),agent,field,planner(iAgent).param.clock,sim,sActNum,iClock);
                elseif sim.flagInfoCom == 1
                    % Mutual Information computation: Consider all future measurements
                    % consider communicaiton awareness
                    [planner(iAgent).candidate.Hbefore(:,iSample),planner(iAgent).candidate.Hafter(:,iSample),planner(iAgent).candidate.I(iSample)] = ...
                        ComputeInformationMeasConsider(planner(iAgent),agent,field,planner(iAgent).param.clock,sim,sActNum,iClock,agent(iAgent).id);
                end
                
            end
            
            % decision making: maximize mutual information
            [~,planner(iAgent).actIdx] = max(planner(iAgent).candidate.I);
            planner(iAgent).input = planner(iAgent).actionSet(:,planner(iAgent).actIdx);
            
            planner(iAgent).I = planner(iAgent).candidate.I(planner(iAgent).actIdx);
            planner(iAgent).Hbefore = planner(iAgent).candidate.Hbefore(:,planner(iAgent).actIdx);
            planner(iAgent).Hafter = planner(iAgent).candidate.Hafter(:,planner(iAgent).actIdx);
        end
        
        
        
        %-----------------------------------
        % Actual Agent-Target Dynamics and Measurement
        %-----------------------------------
        
        % agent moving
        for iAgent = 1:sim.nAgent
            agent(iAgent).s = UpdateAgentState(agent(iAgent).s,planner(iAgent).input(1),clock.dt);
            agent(iAgent).hist.s(:,iClock+1) = agent(iAgent).s;
        end
        
        % target moving
        target.x = UpdateTargetState(target.x,target.param,clock.dt);
        target.hist.x(:,iClock+1) = target.x;
        
        % take measurement: ONLY AGENT 2 TAKES MEASUREMENT IN THIS SCENARIO
        for iSensor = 2:sim.nAgent
            sensor(iSensor).y = TakeMeasurement(target.x,agent(iSensor).s,sensor(iSensor).param);
            sensor(iSensor).hist.y(:,iClock+1) = sensor(iSensor).y;
        end
        
        % particle measurement and agent state sharing through communication
        for iComm = 1:sim.nAgent
            [comm(iComm).beta,comm(iComm).bConnect,planner(iComm).agent,comm(iComm).z] = ...
                ShareInformation(agent,sensor,planner(iComm).agent,PF(iComm).id);
            comm(iComm).hist.beta(:,iClock+1) = comm(iComm).beta;
            comm(iComm).hist.bConnect(:,iClock+1) = comm(iComm).bConnect;
            comm(iComm).hist.Z(:,iClock+1) = comm(iComm).z';
        end
        
        %-----------------------------------
        % Actual measurement and estimation: PF
        %-----------------------------------
        
        % PF is locally performend, and measurement information is delivered
        % under the communication probability
        for iPF = 1:sim.nAgent
            % particle state update
            PF(iPF).pt = UpdateParticle(PF(iPF).pt,PF(iPF).param,clock.dt);
            
            % particle weight update
            PF(iPF).w = UpdateParticleWeight(comm(iPF).z,PF(iPF).pt,planner(iPF).agent,sensor(iPF).param);
            
            % resample particle
            [PF(iPF).pt,PF(iPF).w] = ResampleParticle(PF(iPF).pt,PF(iPF).w,field);
            
            % particle filter info update/store
            PF(iPF).xhat = (PF(iPF).w*PF(iPF).pt')';
            PF(iPF).hist.pt(:,:,iClock+1) = PF(iPF).pt;
            PF(iPF).hist.xhat(:,iClock+1) = PF(iPF).xhat;
            
            % update planner initial info
            planner(iPF).x = PF(iPF).xhat;
            planner(iPF).w = PF(iPF).w;
            planner(iPF).pt = PF(iPF).pt;
            
            % store optimized infomation data
            for iPlanner = 1:sim.nAgent
                planner(iPlanner).hist.actIdx(iClock+1) = planner(iPlanner).actIdx;
                planner(iPlanner).hist.input(:,iClock+1) = planner(iPlanner).input;
                planner(iPlanner).hist.I(:,iClock+1) = planner(iPlanner).I;
                planner(iPlanner).hist.Hafter(:,iClock+1) = planner(iPlanner).Hafter';
                planner(iPlanner).hist.Hbefore(:,iClock+1) = planner(iPlanner).Hbefore';
            end
            
            % take decision making for agent input
            for iAgent = 1:sim.nAgent
                agent(iAgent).vel = planner(iAgent).input(1);
            end
        end
        
        % clock update
        clock.hist.time(:,iClock+1) = iClock*clock.dt;
        
        fprintf('iClock = %d\n',iClock);
        
    end
    
    %%
    %----------------------------
    % Sim Result Plot
    %----------------------------
    
    % pick one of simulation set
    rSim = ceil(rand(1)*nSim);
    
    % aircraft trajectories and estimated target location
    figure(1)
    plot(target.hist.x(1,:),target.hist.x(2,:),'r-','LineWidth',2); hold on;
    plot(target.hist.x(1,1),target.hist.x(2,1),'ro','LineWidth',2); hold on;
    plot(target.hist.x(1,end),target.hist.x(2,end),'rx','LineWidth',2); hold on;
    
    for iAgent = 1:sim.nAgent
        clr = rand(1,3);
        plot(agent(iAgent).hist.s(1,:),agent(iAgent).hist.s(2,:),'-','LineWidth',2,'color',clr); hold on;
        plot(agent(iAgent).hist.s(1,1),agent(iAgent).hist.s(2,1),'o','LineWidth',2,'color',clr); hold on;
        plot(agent(iAgent).hist.s(1,end),agent(iAgent).hist.s(2,end),'x','LineWidth',2,'color',clr); hold on;
        
        clr = rand(1,3);
        plot(PF(iAgent).hist.xhat(1,:),PF(iAgent).hist.xhat(2,:),'--','LineWidth',2,'color',clr); hold on;
        plot(PF(iAgent).hist.xhat(1,1),PF(iAgent).hist.xhat(2,1),'o','LineWidth',2,'color',clr); hold on;
        plot(PF(iAgent).hist.xhat(1,end),PF(iAgent).hist.xhat(2,end),'x','LineWidth',2,'color',clr); hold on;
    end
    
    
    xlabel('time [sec]'); ylabel('position [m]');
    
    title('Target Tracking Trajectory and Estimates');
    legend('true pos','true pos (start)','true pos (end)',...
        'GS pos','GS pos (start)','GS pos (end)',...
        'GS estimated pos','GS estimated pos (start)','GS estimated pos (end)',...
        'Agent 2 pos','Agent 2 pos (start)','Agent 2 pos (end)',...
        'Agent 2 estimated pos','Agent 2 estimated pos (start)','Agent 2 estimated pos (end)');
    
    axis equal; axis(field.boundary);
    
    % snapshots and particles
    figure(2)
    
    nSnapshot = floor(clock.nt/sim.param.plot.dClock)+2; % initial, during(dClock/each), final
    nCol = 3;
    nRow = ceil(nSnapshot/nCol);
    
    clr = [0 1 0; 0 0 1; 0 1 1];
    ptClr = [0 0.5 0; 0 0 0.5];
    
    for iSnapshot = 1:nSnapshot
        subplot(nRow,nCol,iSnapshot)
        if iSnapshot == 1
            SnapTime = 1;
        elseif iSnapshot == nSnapshot
            SnapTime = clock.nt+1;
        else
            SnapTime = (iSnapshot-1)*sim.param.plot.dClock+1;
        end
        
        % target position
        for iTarget = 1:sim.nTarget
            plot(target(iTarget).hist.x(1,1:SnapTime),target(iTarget).hist.x(2,1:SnapTime),'r-','LineWidth',2); hold on;
            plot(target(iTarget).hist.x(1,1),target(iTarget).hist.x(2,1),'ro','LineWidth',2); hold on;
            plot(target(iTarget).hist.x(1,SnapTime),target(iTarget).hist.x(2,SnapTime),'rx','LineWidth',2); hold on;
        end
        
        % agent position
        for iAgent = 1:sim.nAgent
            plot(agent(iAgent).hist.s(1,1:SnapTime),agent(iAgent).hist.s(2,1:SnapTime),'-','LineWidth',2,'color',clr(iAgent,:)); hold on;
            plot(agent(iAgent).hist.s(1,1),agent(iAgent).hist.s(2,1),'o','LineWidth',2,'color',clr(iAgent,:)); hold on;
            plot(agent(iAgent).hist.s(1,SnapTime),agent(iAgent).hist.s(2,SnapTime),'x','LineWidth',2,'color',clr(iAgent,:)); hold on;
            
            % particle plotting
            plot(squeeze(PF(iAgent).hist.pt(1,:,SnapTime)),squeeze(PF(iAgent).hist.pt(2,:,SnapTime)),'.','LineWidth',2,'color',ptClr(iAgent,:)); hold on;
        end
        
        axis equal; axis(field.boundary);
        xlabel(['t =',num2str((SnapTime-1)*clock.dt),' sec'],'fontsize',12);
    end
    
    
    % utility profile
    figure(3)
    plot(clock.hist.time,planner(1).hist.I,'b-','LineWidth',3); hold on;
    plot(clock.hist.time,planner(2).hist.I,'r-','LineWidth',3);
    xlabel('time [sec]'); ylabel('utility [sum of M.I.]');
    legend('Ground Station','Agent 2');
    title('Utility Profile');
    
    
    % entropy profile
    figure(4)
    [timePlanProfile,timeProfile] = meshgrid(1:planner(1).param.clock.nT,clock.hist.time);
    mesh(timePlanProfile,timeProfile,planner(2).hist.Hbefore');
    surface(timePlanProfile,timeProfile,planner(1).hist.Hbefore');
    xlabel('planned time [sec]'); ylabel('actual time [sec]'); zlabel('entropy');
    legend('particle-H[P(x_t|y_{k+1:t-1})]','particle-H[P(x_t|z_{k+1:t-1})]');
    view(3);
    title('Entropy of Prior Probability');
    
    % entropy profile
    figure(5)
    [timePlanProfile,timeProfile] = meshgrid(1:planner(2).param.clock.nT,clock.hist.time);
    mesh(timePlanProfile,timeProfile,planner(2).hist.Hafter');
    surface(timePlanProfile,timeProfile,planner(1).hist.Hafter');
    xlabel('planned time [sec]'); ylabel('actual time [sec]'); zlabel('entropy');
    legend('particle-H[P(x_t|y_{k+1:t})]','particle-H[P(x_t|z_{k+1:t})]');
    view(3);
    title('Entropy of Posterior Probability');
    
end
