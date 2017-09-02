function [opt_data, vc1_opt, vc2_opt] = path_optimization_cvx(array,bool,lambda0,lambda1,lambda2,lambda3,vc1,vc2,thresh)

N = size(array,1);
e = ones(N,1);
D1 = spdiags([-e e], 0:1, N-1, N);
D2 = spdiags([e -2*e e], 0:2, N-2, N);
D3 = spdiags([-e 3*e -3*e e], 0:3, N-3, N);

in = find(bool(:,2)==0);
D1(in,:)=0;
in = find(bool(:,3)==0);
D2(in,:)=0;
in = find(bool(:,4)==0);
D3(in,:)=0;


% cvx_begin
% variable g(N,1)
% 
% minimise(lambda0*sum_square(bool(1:N,1).*(g(1:N)-array(1:N)))...
%     + lambda1*norm( (D1*g),1)+ lambda2*norm((D2*g),1) + lambda3*norm((D3*g),1)...
%     )
% subject to
% abs(D1*g) <= vc1;
% abs(D2*g) <= vc2;
% cvx_end

cvx_begin
variable g(N,1)
variable temp(N,1);

minimise(lambda0*sum((bool(1:N,1).*(relu_cvx(g(1:N)-array(1:N),thresh,2))))...
    + lambda1*norm( (D1*g),1)+ lambda2*norm((D2*g),1) + lambda3*norm((D3*g),1)...
    )
subject to
abs(D1*g) <= vc1;
abs(D2*g) <= vc2;

% for i=1:N-2
%     if (temp(i)<=0)
%         if (temp(i+1)<=0)
%         
%         else
%             temp(i) == temp(i+1);
%         end
%     end
% end

cvx_end

opt_data=g;
vc1_opt = abs(D1*g);
vc2_opt = abs(D2*g);
