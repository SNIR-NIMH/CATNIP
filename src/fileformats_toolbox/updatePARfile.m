function updatePARfile(tarPar,srcPar)
% History: 5/2/06: Updated to support coronal files
par = loadPAR(srcPar);
newpar = loadPAR(tarPar);
par.scn.fov = newpar.scn.fov;
par.scn.recon_res = newpar.scn.recon_res;
par.scn.slicethk = newpar.scn.slicethk;
last = 0;
for j=1:length(par.img)
    q(j) = par.img(j).info.dynamic_scan_num;
    SRC_image_flip_angle(par.img(j).info.dynamic_scan_num) = par.img(j).special.image_flip_angle;
    SRC_diffusion_b_factor(par.img(j).info.dynamic_scan_num) = par.img(j).special.diffusion_b_factor;
    SRC_echo_time(par.img(j).info.dynamic_scan_num) = par.img(j).special.echo_time;
end
UQ = unique(q);
Nvol = length(UQ);
clear q;
for j=1:length(newpar.img)
    q(j) = newpar.img(j).info.dynamic_scan_num;
end
onevol = find(q==q(1));
par.img = [];
for j=1:Nvol
    for k=1:length(onevol)
        img = newpar.img(onevol(k));
        img.info.dynamic_scan_num = j;
        img.special.image_flip_angle = SRC_image_flip_angle(UQ(j));
        img.special.diffusion_b_factor = SRC_diffusion_b_factor(UQ(j));
        img.special.echo_time = SRC_echo_time(UQ(j));        
        if(isempty(par.img))
            par.img = img;
        else
        par.img(end+1) = img;
        end
    end
end

par.max.num_dynamics = length(par.img);
switch(par.img(1).orient.orient)
    case 'TRA'
        par.max.num_slices = par.scn.fov(2)/par.scn.slicethk;
    case 'COR'
        par.max.num_slices = par.scn.fov(1)/par.scn.slicethk;
    case 'SAG'
        par.max.num_slices = par.scn.fov(3)/par.scn.slicethk;
end
par.max.num_slices=round(par.max.num_slices);

savePAR(par, srcPar);