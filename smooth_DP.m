function [dp_output_smooth,L2_cuts]= smooth_DP(d,c,a_data,out_width,bool)
    
     
    for i = 2:size(d,2)-1
    j = i+1;
    
    if(find(c > d(i)-20 & c< d(i)+20)) % no original cuts
        continue
    end
    pi = (a_data(d(i)) - a_data(d(i)-1));
    pj = (a_data(d(j)) - a_data(d(j)-1));
  
    bool(d(i)-20:d(i)+20,[1])=0;
    if d(j) - d(i) < 100
        if pi*pj == 1 % same direction the gaze shited, go to the new location              
            bool(d(i)-10:d(i)+10,[2])=0; % L1 norm is set to zero so that it can move to he next location smoothly 
        else          % location went and came back (just shift all gaze with W/3 limit)                
            if abs(a_data(d(i)) - a_data(d(i)-1) ) > out_width/6
                a_data( d(i):d(j)-1) = a_data(d(i):d(j)-1) - sign(pi)*out_width/6 ; % needs to be changed 
            end

        end
     end
    end

end