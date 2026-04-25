warning('off');
s='WHS_SD_rat_atlas_v4.label';
fp=fopen(s,'r');
x=fgetl(fp);
L=[];
NAME={};
count=1;
try
while ~isempty(x)
    if ~strcmp(x(1),'#')
        a=strrep(x,' ','_');

        for i=1:100
            a=strrep(a,'__','_');
        end
        b=strsplit(a,'_');
        N=length(b);
        if isempty(b{1})
            L(count)=str2num(b{2});
            
            B=[];
            for j=9:N
                B=[B '_' b{j}];
            end
            B=B(2:end); % remove extra underscore in the beginning
            B=strrep(B,'"','');
            B=strrep(B,',','');
            NAME{count}=B;
            count=count+1;
        else
            L(count)=str2num(b{1});
            B=[];
            for j=9:N
                B=[B '_' b{j}];
            end
            B=B(2:end); % remove extra underscore in the beginning
            B=strrep(B,'"','');
            B=strrep(B,',','');
            NAME{count}=B;
            count=count+1;
        end
        
        x=fgetl(fp);
%         disp(x);
    else
        x=fgetl(fp);
%         disp(x);
    end

end
end
fclose(fp);


fp=fopen('atlas_info.txt','w');
for i=1:length(L)
    fprintf(fp,'%d,%s\n',L(i),NAME{i});
end
fclose(fp);