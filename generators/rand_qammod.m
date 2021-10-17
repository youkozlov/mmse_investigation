
function [qam gen] = rand_qammod(numIqs, mod = 4)
  
  gen = rand(1, numIqs * log2(mod)) < 0.5;
  
  switch mod
    case 4
      s = gen(1:2:end) * 2 + gen(2:2:end);
      scale = 1/sqrt(2);
 
    case 16
      s = gen(1:4:end) * 8 + gen(2:4:end) * 4 + gen(3:4:end) * 2 + gen(4:4:end);
      scale = 1/sqrt(10);

    case 64
      s = gen(1:6:end) * 32 + gen(2:6:end) * 16 + gen(3:6:end) * 8 + gen(4:6:end) * 4 + gen(5:6:end) * 2 + gen(6:6:end);
      scale = 1/sqrt(42);

    case 256
      s = gen(1:8:end) * 128 + gen(2:8:end) * 64 + gen(3:8:end) * 32 + gen(4:8:end) * 16 + gen(5:8:end) * 8 + gen(6:8:end) * 4 + gen(7:8:end) * 2 + gen(8:8:end);
      scale = 1/sqrt(170);

    case 1024
      s = gen(1:10:end) * 512 + gen(2:10:end) * 256 + gen(3:10:end) * 128 + gen(4:10:end) * 64 + gen(5:10:end) * 32 + gen(6:10:end) * 16 + gen(7:10:end) * 8 + gen(8:10:end) * 4 + gen(9:10:end) * 2 + gen(10:10:end);
      scale = 1/sqrt(680);
      
    otherwise
      assert(0, 'unsupported case');  
  end

  qam = scale * qammod(s, mod);
  
endfunction
