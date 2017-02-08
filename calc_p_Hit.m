function [p_Hit] = calc_p_Hit(r,J)
% calculates the probability that the saccade target lands within the disk
% 
% R: radius of disk. can be a scalar or vector
% J: memory precision. can be a scalar or vector
% 
% ============ OUTPUT VARIABLES ===========
% P_HIT: an nR x nJ vector of p(Hit) for each combination of r and J. 

r = r(:); % r is vertical
J = J(:)'; % J is horizontal

p_Hit = bsxfun(@(x,sigma) 1-exp(-(x.^2)./(2*sigma.^2)),r,sqrt(1./J));