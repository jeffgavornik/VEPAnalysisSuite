figure(1); clf

% load carsmall
% boxplot(MPG,Origin)
% data = MPG(Origin(:,1)=='G');
% data = data(~isnan(data));


data = rand(1,100);
data(1) = 1.5;
data(2) = -1.5;
data = sort(data);
grps = ones(size(data));
% grps(rand(size(data))>0.5) = 0;
grps(1:50) = 0;
boxplot(data,grps,'notch','on')

data = data(grps==0);

q2 = median(data);
q1 = median(data(data < q2));
q3 = mean(data(data > q2));


W = 1.5;
iOutPlus = data > q3+W*(q3-q1);
iOutMinus = data < q1-W*(q3-q1);
iOutliers = iOutPlus | iOutMinus;

validData = data(~iOutliers);
q2 = median(validData);
q1 = median(validData(validData < q2));
q3 = mean(validData(validData > q2));


xlim = get(gca,'XLim');
hold on
plot(xlim,q2*[1 1],'b:')
plot(xlim,q1*[1 1],'r:')
plot(xlim,q3*[1 1],'r:')
plot(xlim,min(validData)*[1 1],'k:')
plot(xlim,max(validData)*[1 1],'k:')
plot(mean(xlim)*ones(1,sum(iOutliers)),data(iOutliers),'r+');