function savePARRECavw16bit(parrec, idx,filename,orient)
% Updated Apr 27 2006 - now handles Coronal images
if(~exist('orient','var'))
    a  = [parrec.hdr.img(:).orient];
    orient = unique({a(:).orient});
    if(length(orient)>1)
        error('savePARRECavw: Multiple slice orientations not supported within a single file');
    end
    orient=orient{1};
end
avw = parrec.avw;
%  Analyze: 
% 	orient: 
% 			0 - transverse unflipped
% 			1 - coronal unflipped
% 			2 - sagittal unflipped
% 			3 - transverse flipped
% 			4 - coronal flipped
% 			5 - sagittal flipped

switch upper(orient)
    case 'TRA'
        % Axial
        avw.hdr.hist.orient = 0;
        avw.img = parrec.scans{idx}(:,end:-1:1,:);% AVW is R->L,P->A, REC is R->L,A->P
    case 'SAG'
        % Sag
        avw.hdr.hist.orient = 0;
        avw.img = parrec.scans{idx}(:,end:-1:1,:);% AVW is R->L,P->A, REC is R->L,A->P        
        warning('savePARRECavw: Orient SAG not tested. Contact bennett@bme.jhu.edu with example data and we will correct this problem.')
    case 'COR'
        % Coronal
        avw.hdr.hist.orient = 0;
        avw.img = parrec.scans{idx}(:,end:-1:1,:);% AVW is R->L,P->A, REC is R->L,A->P        
    otherwise
        error('savePARRECavw: Unknown orientation.')
end
% Remove Nan and Inf values
avw.img(find(~isfinite(parrec.avw.img(:))))=0;
avw.img = round(avw.img * parrec.hdr.img(1).vis.scale_slope); % assume constant quanitzer
avw.hdr.dime.datatype = 4; % 16 bits
avw_img_write(avw,filename);