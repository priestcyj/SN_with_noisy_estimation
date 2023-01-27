clc
clear
%-----------------读取图片-------------------------%
image1=imread('D:\数据\image\image\160_N7F0.bmp');
[row,column]=size(image1);
image123=imread('D:\数据\image\image\ground160.bmp');
im1=double(image1);
im1=im1/max(im1(:));
Y=[im1(:)']; 
epsilon=0.00001; 
%---------------------------------------------------%
%----------------Initialization--------------------------%
h=0.6; %h=0.3,N3;h=0.9,N5;h=0.6,N7;
alpha=0.06; %alpha=0.4,N3;alpha=0.2,N5;alpha=0.06;
% alpha=0.5;%natual
% r=4; %r=1.3,N3;r=0.5,N5;r=0.5,N7;
a=2.7;
K=4;%class
[n,m]=size(Y);%n-Dimension



Img=reshape(Y,[row,column]);
ROI=ones(row,column);
index = find(ROI ==1);

yy = Img(index);
yy = sort(yy,'descend');
% K-means for initialization
[IDX,C] = kmeans(yy,K,'Start','cluster', ...
    'Maxiter',100, ...
    'EmptyAction','drop', ...
    'Display','off');
while sum(isnan(C))>0
    [IDX,C] = kmeans(yy,K,'Start','cluster', ...
        'Maxiter',100, ...
        'EmptyAction','drop', ...
        'Display','off');
end
V = sort(C);
Dis_k = zeros(row,column,K);

for k = 1:K
    Dis_k(:,:,k) = (Img - V(k)).^2;
end
Sigma=zeros(K,1);
for k = 1:K
    [e_min,IDX] = min(Dis_k,[],3);
    IDX_ROI = IDX.*ROI;
    Sigma(k) = var(Img(IDX_ROI==k));%Initialize Sigma 
end
Mu=V';%Initialize mu
Lambda=zeros(n,K)+0.1;%Initialize lambda
%--Initialize delta------%
delta=zeros(n,K);
  for i=1:K
      delta(:,i)=Lambda(:,i)/((1+Lambda(:,i)'*Lambda(:,i))^(1/2)+eps);
  end
%-------------------%
%--Initialize Delta------%
Delta=zeros(n,K);
  for i=1:K
    Delta(:,i)=sqrt(Sigma(i))*delta(:,i);
  end
%------------------%
%---Initialize T---------%
T=zeros(K,n);
  for i=1:K
      T(i)=Sigma(i)-Delta(:,i)*Delta(:,i)';
  end
sigma=zeros(K,1);
varepsilon=normpdf(0,sigma);
%-------------------%
t1_ij=zeros(K,m);t2_ij=zeros(K,m);
Pi=ones(m,K)/K;
I=eye(K,m);
%----------------------alpha_ij initialization------------------------%
tic
X=zeros(1,2,9);
X(:,:,1)=[-1,1];X(:,:,2)=[-1,0];X(:,:,3)=[-1,-1];X(:,:,4)=[0,1];X(:,:,5)=[0,0];
X(:,:,6)=[0,-1];X(:,:,7)=[1,1];X(:,:,8)=[1,0];X(:,:,9)=[1,-1];
X1=[zeros(row,3),im1,zeros(row,3)];
X1=[zeros(3,column+6);X1;zeros(3,column+6)];
alpha_ij=zeros(3,3,row+6,column+6);
Pij=zeros(3,3,row+6,column+6);
V_u=zeros(2,1,row+6,column+6);
L=zeros(2,1,row+6,column+6);

for i=4:row+3
    for j=4:column+3
        p1=(X1(i-1-1:i-1+1,j-1-1:j-1+1));
        p2=(X1(i-1:i+1,j-1-1:j-1+1));
        p3=(X1(i+1-1:i+1+1,j-1-1:j-1+1));
        p4=(X1(i-1-1:i-1+1,j-1:j+1));
        p5=(X1(i-1:i+1,j-1:j+1));
        p6=(X1(i+1-1:i+1+1,j-1:j+1));
        p7=(X1(i-1-1:i-1+1,j+1-1:j+1+1));
        p8=(X1(i-1:i+1,j+1-1:j+1+1));
        p9=(X1(i+1-1:i+1+1,j+1-1:j+1+1));
        Pij(:,:,i,j)=[sum(sum(abs(p1-p5))),sum(sum(abs(p4-p5))),sum(sum(abs(p7-p5)));sum(sum(abs(p2-p5))),sum(sum(abs(p5-p5))),sum(sum(abs(p8-p5)));sum(sum(abs(p3-p5))),sum(sum(abs(p6-p5))),sum(sum(abs(p9-p5)))];
        Pij(:,:,i,j)=exp(-Pij(:,:,i,j)/h);
        p=Pij(:,:,i,j);
        %------------------------------%
        if p(5)/(sum(p(:))+eps)>=0.8
            p(5)=0;
        end
        Pij(:,:,i,j)=p;
         Pij(:,:,i,j)=Pij(:,:,i,j)/(sum(p(:))+eps);
       Ix2=(X1(i,j+1)-X1(i,j-1))/2;
       Iy2=(X1(i-1,j)-X1(i+1,j))/2;
       Ixy=Ix2*Iy2;
       J=[Ix2^2,Ixy;Ixy,Iy2^2];
       Dx=(X1(i+1,j)-X1(i-1,j))/2;
       Dy=(X1(i,j+1)-X1(i,j-1))/2;
       G=Dx+Dy;
       r=a*exp(-G/h);
        L1=0.5*(J(1,1)+J(2,2)+sqrt((J(1,1)-J(2,2))^2+4*(J(1,2)^2)));
        L2=0.5*(J(1,1)+J(2,2)-sqrt((J(1,1)-J(2,2))^2+4*(J(1,2)^2)));
        L(:,:,i,j)=[L1;L2];
        costhta=2*J(1,2);
        sinthta=J(2,2)-J(1,1)+sqrt((J(1,1)-J(2,2))^2+4*(J(1,2)^2));
        V1=[costhta;sinthta];
        V_u(:,:,i,j)=V1/(sqrt(V1(1)^2+V1(2)^2)+eps);
    end
end

for i=4:row+3
    for j=4:column+3
        p=Pij(:,:,i,j);
        p=p(:);
        mu_A=p(1)*V_u(:,:,i-1,j-1)+p(2)*V_u(:,:,i,j-1)+p(3)*V_u(:,:,i+1,j-1)+p(4)*V_u(:,:,i-1,j)+p(5)*V_u(:,:,i,j)+p(6)*V_u(:,:,i+1,j)+p(7)*V_u(:,:,i-1,j+1)+p(8)*V_u(:,:,i,j+1)+p(9)*V_u(:,:,i+1,j+1);
        mu_A=mu_A/(sqrt(mu_A(1)^2+mu_A(2)^2)+eps);
        mu_Q=zeros(2,1);
        mu_Q(1)=-mu_A(2);
        mu_Q(2)=mu_A(1);
        lambda1=p(1)*L(1,1,i-1,j-1)+p(2)*L(1,1,i,j-1)+p(3)*L(1,1,i+1,j-1)+p(4)*L(1,1,i-1,j)+p(5)*L(1,1,i,j)+p(6)*L(1,1,i+1,j)+p(7)*L(1,1,i-1,j+1)+p(8)*L(1,1,i,j+1)+p(9)*L(1,1,i+1,j+1);
        lambda2=p(1)*L(2,1,i-1,j-1)+p(2)*L(2,1,i,j-1)+p(3)*L(2,1,i+1,j-1)+p(4)*L(2,1,i-1,j)+p(5)*L(2,1,i,j)+p(6)*L(2,1,i+1,j)+p(7)*L(2,1,i-1,j+1)+p(8)*L(2,1,i,j+1)+p(9)*L(2,1,i+1,j+1);
        f_1=1/r^2;f_2=1/(r+lambda1*100+lambda2)^2;
        D=f_1*(mu_A*mu_A')+f_2*(mu_Q*mu_Q');            
        alpha_ij(:,:,i,j)=exp(-[(X(:,:,1)*D)*X(:,:,1)',(X(:,:,4)*D)*X(:,:,4)',(X(:,:,7)*D)*X(:,:,7)';(X(:,:,2)*D)*X(:,:,2)',(X(:,:,5)*D)*X(:,:,5)',(X(:,:,8)*D)*X(:,:,8)';(X(:,:,3)*D)*X(:,:,3)',(X(:,:,6)*D)*X(:,:,6)',(X(:,:,9)*D)*X(:,:,9)']);
        alpha_ij(:,:,i,j)=alpha_ij(:,:,i,j).*Pij(:,:,i,j);
        p=alpha_ij(:,:,i,j);
        p(5)=0;
        alpha_ij(:,:,i,j)=p;
        alpha_ij(:,:,i,j)=alpha_ij(:,:,i,j)/(sum(sum(alpha_ij(:,:,i,j)))+eps);
    end
end
toc
index=1;
alpha_ij_1=zeros((row)*(column),9);
for j=4:column+3
    for i=4:row+3
        p=alpha_ij(:,:,i,j);       
        alpha_ij_1(index,:)=p(:)';
        index=index+1;
    end
end
%-----------------------------------------------------------------------------------------------------%
ROI=ROI(:);
tic

for t=1:200
    %-------------Update parameter----------------%
    
        M=1./(1+Delta'.*((sigma+T).^(-1.0)).*Delta'+eps);
        mu_ij=repmat(Delta',1,m).*((T+sigma).^(-1.0)).*M.*(repmat(Y,K,1)-repmat(Mu',1,m)).*repmat(ROI',K,1);
        t1_ij=mu_ij+(normpdf(mu_ij)./(normcdf(mu_ij)+eps)).*(M.^(1/2)).*repmat(ROI',K,1);
        t2_ij=mu_ij.^2+M+(normpdf(mu_ij)./(normcdf(mu_ij)+eps)).*(M.^(1/2)).*mu_ij.*repmat(ROI',K,1);
        Tb_ij=(T.^(-1)+(sigma+eps).^(-1)).^(-1).*repmat(ROI',K,1);
        r_ij=Tb_ij.*((sigma+eps).^(-1)).*(repmat(Y,K,1)-repmat(Mu',1,m)).*repmat(ROI',K,1);
        s_ij=(I-Tb_ij.*((sigma+eps).^(-1))).*repmat(Delta',1,m).*repmat(ROI',K,1);
        x_ij=(r_ij+s_ij.*t1_ij).*repmat(ROI',K,1);
        ou_ij=(Tb_ij+s_ij.^2.*(t2_ij-(t1_ij.^2))).*repmat(ROI',K,1);
        t_ij=(r_ij.*t1_ij+s_ij.*t2_ij).*repmat(ROI',K,1);   
  
    %---------------------------------------------------------%
    
    %-------------------Update Z--------------------------%
    phi=1./((sqrt(2*pi*repmat(Sigma,1,m)))+eps).*exp(-1/2*((repmat(Y,K,1)-repmat(Mu',1,m)).^2).*(1./(repmat(Sigma,1,m)+eps))).*repmat(ROI',K,1);
    psi=normcdf(repmat(Lambda',1,m).*repmat(Sigma.^(-1.0/2),1,m).*(repmat(Y,K,1)-repmat(Mu',1,m))).*repmat(ROI',K,1);

    Z=2*Pi'.*phi.*psi.*repmat(ROI',K,1);  
    Z=Z./(repmat(sum(Z),K,1)+eps).*repmat(ROI',K,1);
    p1_ik=Z';
    %---------------------------------------------------------%
    
    %--------------------Update p1n_ik,Pin---------------------------%
    
    p1n_ik=zeros(m,K);Pin=zeros(m,K);
    for k=1:K
    p1_ik_reshape=reshape(p1_ik(:,k),[row,column]);  
    Pi_reshape=reshape(Pi(:,k),[row,column]);
    A1=[zeros(row,1),p1_ik_reshape,zeros(row,1)];
    B1=[zeros(1,column+2);A1;zeros(1,column+2)];
    A2=[zeros(row,1),Pi_reshape,zeros(row,1)];
    B2=[zeros(1,column+2);A2;zeros(1,column+2)];
    p1n_ik(:,k)=(sum(alpha_ij_1'.*im2col(B1, [3,3], 'sliding')))';
    Pin(:,k)=(sum(alpha_ij_1'.*im2col(B2, [3,3], 'sliding')))';
    end
    p1n_ik=p1n_ik./(repmat(sum(p1n_ik,2),1,K)+eps).*repmat(ROI,1,K);
    Pin=Pin./(repmat(sum(Pin,2),1,K)+eps).*repmat(ROI,1,K);
    %---------------------------------------------------------------% 
    
    %-----------------------Update s1_ik--------------------------------%
    s1_ik=Pi.*Pin;
    s1_ik=s1_ik./(repmat(sum(s1_ik,2),1,K)+eps);
    %----------------------------------------------------------------%
    %-----------------------Update q1_ik--------------------------------%
    q1_ik=p1_ik.*p1n_ik;
    q1_ik=q1_ik./(repmat(sum(q1_ik,2),1,K)+eps);
    %----------------------------------------------------------------%
    %--------------------Update s1n_ik,q1n_ik------------------------------------%
    s1n_ik=zeros(m,K);q1n_ik=zeros(m,K);
    for k=1:K
        s1_ik_reshape=reshape(s1_ik(:,k),[row,column]);  
        q1_ik_reshape=reshape(q1_ik(:,k),[row,column]);
        A1=[zeros(row,1),s1_ik_reshape,zeros(row,1)];
        B1=[zeros(1,column+2);A1;zeros(1,column+2)];
        A2=[zeros(row,1),q1_ik_reshape,zeros(row,1)];
        B2=[zeros(1,column+2);A2;zeros(1,column+2)];
        s1n_ik(:,k)=(sum(alpha_ij_1'.*im2col(B1, [3,3], 'sliding')))';
        q1n_ik(:,k)=(sum(alpha_ij_1'.*im2col(B2, [3,3], 'sliding')))';
    end
    s1n_ik=s1n_ik./(repmat(sum(s1n_ik,2),1,K)+eps).*repmat(ROI,1,K);
    q1n_ik=q1n_ik./(repmat(sum(q1n_ik,2),1,K)+eps).*repmat(ROI,1,K);
    %---------------------------------------------------------------%
    
    %------------------------------Update parameter--------------------------%
    Mu_old=Mu;
    Pi=(1/(1+2.*alpha+eps))*((1/2)*(q1_ik+q1n_ik)+alpha*(s1_ik+s1n_ik)).*repmat(ROI,1,K);
    Mu=sum((q1_ik'+q1n_ik').*(repmat(Y,K,1)-x_ij),2)./(sum((q1_ik'+q1n_ik'),2)+eps);
    Delta=sum((q1_ik'+q1n_ik').*t_ij,2)./(sum((q1_ik'+q1n_ik').*t2_ij,2)+eps);
    sigma=((q1_ik'+q1n_ik').*(repmat(Y,K,1)-repmat(Mu,1,m)-x_ij).^2+ou_ij)./(sum((q1_ik'+q1n_ik'),2)+eps);
    T=sum((q1_ik'+q1n_ik').*(ou_ij+x_ij.^2-2.*t_ij.*repmat(Delta,1,m)+t2_ij.*repmat(Delta,1,m).^2),2)./(sum((q1_ik'+q1n_ik'),2)+eps);
    Sigma=T+Delta.^2;

    Lambda=(Sigma.^(-1/2).*Delta).*(1.0./((1-Delta.*Sigma.^(-1).*Delta).^(1/2)+eps));
    Lambda=Lambda';
    Mu=Mu';
    Delta=Delta';

    %----------------------------------------------------------------%
    if sqrt(sum(sum((Mu_old-Mu).^2)))<=epsilon
        break;
    end
    Mu_old=Mu;
        [~,nn]=max(Z);
      [~,wz]=sort(Mu(1,:));
      nn=reshape(nn,[row,column]);
      out2=nn;
      for i=1:K
        out2(nn==wz(i))=50*(i-1);
      end 
      iterNums=['segmentation: ',num2str(t), ' iterations'];
%     
    imshow(out2,[]),title(iterNums); colormap(gray);
   pause(0.1)
  

end

[~,nn]=max(Z);
      [~,wz]=sort(Mu);
      nn=reshape(nn,[row,column]);
      out2=nn;
      for i=1:K
        out2(nn==wz(i))=50*(i-1);
      end      
imshow(out2.*reshape(ROI,[row,column]),[]);
B=out2.*reshape(ROI,[row,column]);
imwrite(uint8(B),'wij13_243.bmp');
    c=0;ccc=0;cc1=0;cc_1=0;cc_2=0;cc_3=0;cc2=0;cc3=0;b=0;

[row,column]=size(image123);
for i=1:row
    for j=1:column
        if image123(i,j)==50||B(i,j)==50
            cc1=cc1+1;
        end        
        if image123(i,j)==50&&B(i,j)==50
            cc_1=cc_1+1;
        end  
        if image123(i,j)==100||B(i,j)==100
            cc2=cc2+1;
        end
        if image123(i,j)==100&&B(i,j)==100
            cc_2=cc_2+1;
        end
        
        if image123(i,j)==150||B(i,j)==150
            cc3=cc3+1;
        end
        
        if image123(i,j)==150&&B(i,j)==150
            cc_3=cc_3+1;
        end
        
    end
end

c1_cor=cc_1/(cc1)*100;
c2_cor=cc_2/(cc2)*100;
c3_cor=cc_3/(cc3)*100;
    c=0;ccc=0;
for i=1:row
    for j=1:column  
            if (image123(i,j)-B(i,j))==0
                c=c+1;
            end
    end
end
for i=1:row
    for j=1:column
        
            if image123(i,j)==0
            ccc=ccc+1;
            else 
                ccc=ccc;
            end
       
    end
end
for i=1:row
    for j=1:column  
            if (image123(i,j)-B(i,j))~=0
                b=b+1;
            end
    end
end
c=(c-ccc)/((row*column-ccc)*2-(c-ccc))*100; 
MCR=b/(row*column-ccc)*100;
c_cor=[c3_cor;c2_cor;c1_cor;MCR]'