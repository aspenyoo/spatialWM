% CALC_NLL(JBAR_TOTAL,TAU,BETA)
%
% CALC_NLL: calculates negative log likelihood of parameter combination for
% the optimal model
% JBAR_TOTAL: total amount of resources across priorities
% TAU: second parameter of gamma noise distribution

Theta = [15 1 1];
Jbar_total = Theta(1);
tau = (2);
beta = (3);

% data stuff
priorityVec = [0.6 0.3 0.1];
nPriorities = length(priorityVec);

% calculate the optimal proportions given the parameters
calc_ntotalEU = @(x) -(0.6*calc_E_EU([Jbar_total*x(1),tau,beta]) ...
    + 0.3*calc_E_EU([Jbar_total*x(2),tau,beta])...
    + 0.1*calc_E_EU([Jbar_total*x(3),tau,beta]));

Aeq = [1 1 1];
beq = 1;
[A,b,nonlcon] = deal([]);
options = optimset('Display','iter');
lb = [1e-5 1e-5 1e-5];
ub = [1 1 1];
[pVec, totalEU] = fmincon(calc_ntotalEU,rand(1,3),A,b,Aeq,beq,lb,ub,nonlcon,options);

% loading JVec;
[JVec,rVec] = loadvar('JVec','rVec');
nJs = length(JVec);
rVec = rVec(:); % vertical

nLL = 0;
for ipriority = 1:nPriorities
    Jbar = Jbar_total*pVec(ipriority); % Jbar for current trial
    JbarVec = linspace(0.5,5,50);
    
    % p(J|Jbar,tau)
    Jpdf = gampdf(JVec,Jbar/tau,tau);
    Jpdf = Jpdf./sum(Jpdf); % normalize
    
    % p(Shat|S,J)
    data_distance = rand(1,3);
    nTrials = length(data_distance);
    Sigma = zeros(1,2,nJs*nTrials);
    Sigma(1,:,:) = sort(repmat(sqrt(1./JVec(:)),nTrials,2),'descend')'; % in descending order to keep J ascending
    p_Shat = mvnpdf(repmat([data_distance(:) zeros(nTrials,1)],nJs,1),0,Sigma);
    p_Shat = reshape(p_Shat,nTrials,nJs);
    
    % p(Shat|S) = \int p(Shat|S,J) p(J) dJ
    p_Shat = sum(bsxfun(@times,p_Shat,Jpdf),2);
    

    % get pdf of p(r|Jbar,tau,beta)
    pdf_r = calc_pdf_r(beta, JVec);
    pdf_r = bsxfunandsum(@times,pdf_r,Jpdf,2);
    
    % p(r): probability of responding r given the parameters
    data_r = rand(1,3)*3; % ASPEN: data would go here with radius of disk
    data_r = data_r(:)';  % make sure it is horizontal vector
    firstidxs = bsxfun(@(x,y) x == x(find((x-y)<=0,1,'last')),rVec,data_r);
    lastidxs = bsxfun(@(x,y) x == x(find((x-y)>=0,1,'first')),rVec,data_r);
    
    % linearly interpolate
    slope = (sum(bsxfun(@times,pdf_r,lastidxs)) - sum(bsxfun(@times,pdf_r,firstidxs)))./diff(rVec(1:2));
    p_r = slope.*(data_r - sum(bsxfun(@times,rVec,firstidxs))) + sum(bsxfun(@times,pdf_r,firstidxs));
    
    nLL = nLL -sum(log(p_Shat)+log(p_r));
end

% calculate nLL