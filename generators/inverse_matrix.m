function [result] = inverse_matrix(H)
  
   det = 1/(H(1,1)*H(2,2) - H(2,1)*H(1,2));
 
   result = det * [H(2,2), -H(1,2); -H(2,1), H(1,1)];

endfunction