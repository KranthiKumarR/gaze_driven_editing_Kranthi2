clc
clear all
close all

%% Cut Detection and Path Optimization
load AllData

outwidth_all = [400 350 350 570 496 572 350 0 350];

idx_video = 9;
fps = AllData{idx_video}.fps;
Data = AllData{idx_video}.Data;
resolution = AllData{idx_video}.resolution;

AR = 4/3;  % Required Aspect Ratio

l = min([length(Data{1}(:,1)) length(Data{2}(:,1)) length(Data{3}(:,1))]);
st = 1;
ed = l;
AData = [(Data{1}(st:ed,1)) (Data{2}(st:ed,1)) (Data{3}(st:ed,1))];

l = length(AData);
data = median(AData');
data = data';

%load 4e_R_data.mat
%data = data_c*1366/320;

% nearest neighbour approx
% nn = 0;
% for i=1:length(data)
%     if data(i) >=0
%         nn = data(i);
%     else
%         data(i) = nn;
%     end
% end


out_width = AllData{idx_video}.resolution(2);
out_width = outwidth_all(idx_video)*AR;

size_data = size(data,1);
bool = ones(size_data,4); % all have equal weights

%% Finding cuts in gaze data

cut_dist = round(0.7*(out_width)); %was 150

N = size(data,1);
s_skip = 3;      % s-skip distance
fixtime = 24;    % Fixation time
k=24 ;      % no more than 1 cut in k frames

cuts_cvx = cut_detect_cvx(data,cut_dist,s_skip,fixtime,k);

figure,
%subplot(211)
plot(data,'.b')
hold on;
scatter(cuts_cvx,data(cuts_cvx),20,'*r')
% plot(abs(D1*data))
% plot(1:3600,ones(3600,1)*l2,'-k');
% plot(n3+1:N-n3,abs(D4*data.*(x(n3+1:N-n3))),'-m');
% plot(n3+1:N-n3,abs(D4*data),'-g');
% plot(n3+1:N-n3,abs(D4*data).*(x(n3+1:N-n3)) + (1-x(n3+1:N-n3))*(l2)-l2,'-g')
axis([0 l 0 1366])


%% DP
tic
[cuts_dp dp_output img] = cut_detect_DP(data,out_width,k,30,100,cut_dist,AData,1);
[cuts_dp_2 dp_output_2 img_2] = cut_detect_DP(data,out_width,k,30,100,cut_dist,AData,0);
toc
scatter(cuts_dp,data(cuts_dp),20,'ok');
scatter(cuts_dp_2,data(cuts_dp_2),20,'or');


plot(dp_output,'-k');
plot(dp_output_2,'-g');

pause
% plot(temp(:,1),'-g')
% plot(temp(:,2),'-m');
% plot(temp(:,3),'-k');

img2 = img(size(img,1):-1:1,:);
figure,imshow(img2,[])

%% Path Optimization

% load original cuts
A = importdata(['./original_cut_detection/' AllData{idx_video}.filename(1:end-4) '_shots.txt'], ' ');
cuts_org = A(:,1);
cuts = cuts_dp;
bool = ones(N,4);

% generate bool variables
% for original cuts

bool(cuts_org(1):cuts_org(1)+s_skip,1) = 0;
for i=2:length(cuts_org)
        bool(cuts_org(i):cuts_org(i)+s_skip,1) = 0;
        bool(cuts_org(i):cuts_org(i),2) = 0;
        bool(cuts_org(i)-1:cuts_org(i),3) = 0;
        bool(cuts_org(i)-2:cuts_org(i),4) = 0;
end
% for detected cuts
for i=1:length(cuts)
        bool(cuts(i):cuts(i)+s_skip,1) = 0;
        bool(cuts(i):cuts(i),2) = 0;
        bool(cuts(i)-1:cuts(i),3) = 0;
        bool(cuts(i)-2:cuts(i),4) = 0;
end
%bool(1:10,1) = 0;
bool(l-3:l,[0 2 3]+1) = 0;
bool(l-3:l,1) = 1;
bool = bool(1:l,:);


lambda0 = 0.005;
lambda1 = 50;
lambda2 = 5;
lambda3 = 30;
vc1 = 3;
vc2 = 3;

thresh = out_width*0.1;
[opt_data,temp1, temp2]=path_optimization_cvx(data,bool,lambda0,lambda1,lambda2,lambda3,vc1,vc2,thresh);

[opt_data_dp,temp1_dp, temp2_dp]=path_optimization_cvx(dp_output,bool,lambda0,lambda1,lambda2,lambda3,vc1,vc2,0);

figure,
%subplot(211)
plot(data,'.b')
hold on;
plot(dp_output,'-k')
%axis([0 l 0 1366])

plot(opt_data,'-g')
plot(opt_data_dp,'-r')
legend('Gaze Data', 'Track')

% subplot(212);
% plot(temp1,'-b')
% hold on
% plot(temp2,'-r')
% 
% plot(temp1_dp,'.k')
% hold on
% plot(temp2_dp,'.m')
% 
% axis([0 l 0 6])


fileID = fopen([AllData{idx_video}.filename(1:end-4) '_optpath.txt'],'w');
fprintf(fileID,'%f \n',opt_data');
fclose(fileID);