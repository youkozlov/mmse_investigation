
function [result] = pass_slot(ctx)
  
  ctx.ch.data = zeros(ctx.frame.slot_len, ctx.rf.num_ants);

  ctx.ch.data_shifted = zeros(ctx.frame.slot_len, ctx.rf.num_ants);

  ctx.ch.noise = awgn_noise(ctx.tx.data, ctx.ch.snr);
  
  % apply TO speed
  if (ctx.ch.to_speed > 0)

    offset = 0;

    for symbol_number = 1 : ctx.frame.num_symbols

      cp_len = ctx.frame.cp_len(symbol_number);
      
      symb_len = cp_len + ctx.frame.fft;

      a = ctx.ch.to_speed * (symbol_number - 1) / ctx.frame.fft * (2 * pi);
      
      to_shifter = reshape(exp(j * a * [0:ctx.frame.fft - 1]), [ctx.frame.fft, 1]);
      
      for ant_number = 1 : ctx.rf.num_ants
    
        fft_in = ctx.tx.data(1 + cp_len + offset: cp_len + ctx.frame.fft + offset, ant_number);
      
        fft_out = sqrt(ctx.frame.fft) * ifft(fftshift(1 / sqrt(ctx.frame.fft) * fftshift(fft(fft_in)) .* to_shifter));
      
        ctx.ch.data_shifted(1 + offset : symb_len + offset, ant_number) = [fft_out(end - cp_len + 1: end); fft_out];
      
      end
      
      offset += symb_len;
      
    endfor

  else

    ctx.ch.data_shifted = ctx.tx.data;
  
end  
  
  multipler11 = 1 / (10 ^ (ctx.ch.attenuation(1, 1) / 20));
  multipler12 = 1 / (10 ^ (ctx.ch.attenuation(1, 2) / 20));
  multipler21 = 1 / (10 ^ (ctx.ch.attenuation(2, 1) / 20));
  multipler22 = 1 / (10 ^ (ctx.ch.attenuation(2, 2) / 20));

  data = zeros(ctx.frame.slot_len + 128, ctx.rf.num_ants);
  data(1 + 64: end - 64, 1) = ctx.ch.data_shifted(:,1) * multipler11 + ctx.ch.data_shifted(:,2) * multipler21;  
  data(1 + 64: end - 64, 2) = ctx.ch.data_shifted(:,1) * multipler12 + ctx.ch.data_shifted(:,2) * multipler22;

  foexp = exp(-j * [0:ctx.frame.slot_len - 1] * pi * ctx.ch.fo / (ctx.frame.fft * ctx.frame.scs));
  
  for layer_number = 1 : ctx.alloc.num_layers
        
    data(1 + 64: end - 64, layer_number) = data(1 + 64: end - 64, layer_number) .* reshape([foexp], [ctx.frame.slot_len, 1]);
   
  end   

  ctx.ch.data = data(1 + 64 + ctx.ch.to: ctx.frame.slot_len + 64 + ctx.ch.to, :) + ctx.ch.noise;
  
  result = ctx;

endfunction
