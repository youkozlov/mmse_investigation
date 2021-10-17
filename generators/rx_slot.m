function [result] = rx_slot(ctx)

  ctx.rx.data = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols, ctx.rf.num_ants);
  
  gap = (ctx.frame.fft - ctx.bwp.num_scs) / 2;

  dcSc = ctx.bwp.num_scs / 2;
  
  offset = 0;

  for symbol_number = 1 : ctx.frame.num_symbols

    cp_len = ctx.frame.cp_len(symbol_number);
    
    symb_len = cp_len + ctx.frame.fft;
  
    for ant_number = 1 : ctx.rf.num_ants
  
      fft_in = ctx.ch.data(1 + cp_len - ctx.rx.shift + offset: cp_len + ctx.frame.fft - ctx.rx.shift + offset, ant_number);
    
      fft_out = 1/sqrt(ctx.frame.fft) * fftshift(fft(fft_in));
    
      ctx.rx.data(:, symbol_number, ant_number) = fft_out(1 + gap : ctx.bwp.num_scs + gap);
    
    end
    
    offset += symb_len;
    
  endfor

  result = ctx;
  
endfunction
