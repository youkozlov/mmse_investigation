
function [result] = awgn_noise(sig, snr_db)

  len = size(sig, 1);

  num_stream = size(sig, 2);

  noise = zeros(len, num_stream);

  for i = 1 : num_stream
    
    Ps = sum(abs(sig(:, i)) .^ 2) / len;
    
    Pn = Ps / (10 ^ (-snr_db / 10));
    
    noise = sqrt(Pn) * 1 / sqrt(2) * (randn(len, num_stream) + j * randn(len, num_stream));
  
  end

  result = noise;
   
endfunction
