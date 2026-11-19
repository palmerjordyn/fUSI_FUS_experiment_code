function BFIQSVD = SVDfilter(BFIQ,cutoff)
%% function IQf = SVDfilter(IQ,cutoff)
% SVD of a n-dim matrix
% the temporal dimension has to be the last dimension

initsize = size(BFIQ);
if cutoff(end)>initsize(end)
    cutoff = cutoff(1):initsize(end);
end
if numel(cutoff)==1
    cutoff = cutoff(1):initsize(end);
elseif numel(cutoff)==2
    cutoff = cutoff(1):cutoff(2);
end
    
if or(isequal(cutoff,1:size(BFIQ,3)),cutoff(1)<2)
    BFIQSVD = BFIQ;
    return
end

X = reshape(BFIQ,prod(initsize(1:end-1)),initsize(end)); % Reshape into Casorati matric
[U,~] = svd(X'*X);% calculate svd of the autocorrelated Matrix
V = X*U;% Calculate the singular vectors.
Reconst = V(:,cutoff)*U(:,cutoff)'; % Singular value decomposition

BFIQSVD = reshape(Reconst,initsize); % Reconstruction of the final filtered matrix


end
