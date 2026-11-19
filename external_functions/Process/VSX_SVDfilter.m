function Dop=VSX_SVDfilter(IData,QData)
%% A function to compute Doppler
% Created by Baptiste Heiles on 2025/01/16
% Last modified by Baptiste Heiles on 2025/03/28
%
% VSX_SVDfilter();

% Check workspace for UserParam and CParam
if ~ evalin('base','exist("UserParam");')
    error(sprintf('     Error @VSX_SVDfilter : UserParam is undefined in base workspace'));
else
    UserParam=evalin('base','UserParam');
end

if ~evalin('base','exist("CParam");')
    error(sprintf('     Error @VSX_SVDfilter : CParam is undefined in base workspace'));
else
    CParam=evalin('base','CParam');
end

% Call SVDfilter function and execute
BFIQSVD=SVDfilter(squeeze(complex(IData,QData)),UserParam.SVD);

Dop = mean(abs(BFIQSVD(:,:,:)).^2,3);
Dop = (Dop - min(Dop(:)))./range(Dop(:));
if UserParam.displayMode==2
    % Display if you need
    f=figure(490217);
    if isempty(f.Children)
        
%         imagesc(sqrt(data.Dop));
        imagesc(interp2(sqrt(data.Dop),2));
        f.Color='white';title('Doppler');hold on;
        colormap hot(256);axis image;
        caxis([0.05 0.95]);
%         ax=gca;
%         ax.Children.Interpolation='bilinear';
    else
%         data.Dop = mean(abs(data.BFIQSVD(:,:,:)).^2,3);
%         data.Dop = (data.Dop - min(data.Dop(:)))./range(data.Dop(:));
% %         imagesc(sqrt(data.Dop));
%         imagesc(interp2(sqrt(data.Dop),2));
%     end

   
end
% Assign data back in base workspace
assignin('base','data',data);
