function fit_parameters(model,subjnum,nStartVals,testmodel)
if nargin < 3; nStartVals = 1; end
if nargin < 4; testmodel = model; end % for model recovery
%
%
% ================= INPUT VARIABLES ==================
% MODEL: 1 (optimal priority placement) or 2 (not optimal)
% SUBJNUM: subject number. 1 - 11
% NSTARTVALS: optimization starting vals
% 
% -----------------------
%      Aspen H. Yoo
%   aspen.yoo@nyu.edu

% filepath = 'fits/';
filepath = '/home/ay963/spatialWM/fits/';

if subjnum <= 11
    load('cleandata.mat')
    subjdata = data{subjnum};
    filename = [filepath 'fits_model' num2str(model) '_subj' num2str(subjnum) '.mat'];
else
    load(['simdata_model' num2str(testmodel) '.mat'],'simdata')
    subjdata = simdata{subjnum - 11};
    filename = [filepath 'paramrecov_model' num2str(model) '_subj' num2str(subjnum-11) '.mat'];
end

rng(0);
% rng(str2double([num2str(model) num2str(subjnum)]));

lb = [1e-5 1e-3 1e-5]; % Jbar_total, tau, beta, lapse (ASPEN FIGURE OUT LAPSE STUFF)
ub = [50 10 5];
plb = [0.5 0.01 0.5];
pub = [20 5 1.5];
logflag = logical([1 1 0]);
if model == 2
    lb = [lb 0 0];
    ub = [ub 1 1];
    plb = [plb 0.3 0];
    pub = [pub 0.7 0.3];
    logflag = logical([logflag 0 0]);
end
nParams = length(logflag);
lb(logflag) = log(lb(logflag));
ub(logflag) = log(ub(logflag));
plb(logflag) = log(plb(logflag));
pub(logflag) = log(pub(logflag));

optimMethod = 'bps';
if strcmp(optimMethod,'fmincon')
        [A,b,Aeq,beq,nonlcon] = deal([]);
        options = optimset('Display','iter');
        if model == 2
            A = [0 0 0 1 1];
            b = 1;
        end
end

for istartvals = 1:nStartVals
    try load(filename); catch; ML_parameters = []; nLLVec = []; end
%     load(['simdata_model' num2str(model) '.mat'],'simtheta')
%     x0 = simtheta(subjnum-11,:);
%     x0(1:2) = log(x0(1:2));
    x0 = plb + rand(1,nParams).*(pub - plb);
    fun = @(x) calc_nLL(model,x,subjdata);
    switch optimMethod
        case 'bps'
            [x,fval] = bps(fun,x0,lb,ub,plb,pub);
        case 'fmincon'
            [x,fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options);
    end
    x(logflag) = exp(x(logflag));
    ML_parameters = [ML_parameters; x];
    nLLVec = [nLLVec fval];
    save(filename,'ML_parameters','nLLVec')
end