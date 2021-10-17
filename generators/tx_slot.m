
function [result] = tx_slot(ctx)
  
  ctx.tx.data = zeros(ctx.frame.slot_len, ctx.rf.num_ants);
  
  gap = (ctx.frame.fft - ctx.bwp.num_scs) / 2;

  dcSc = ctx.bwp.num_scs / 2;
  
  offset = 0;

  for symbol_number = 1 : ctx.frame.num_symbols

    cp_len = ctx.frame.cp_len(symbol_number);
    
    symb_len = cp_len + ctx.frame.fft;
  
    for ant_number = 1 : ctx.rf.num_ants
  
      fft_in = [zeros(gap, 1) ;ctx.buf.data(1: end, symbol_number, ant_number); zeros(gap, 1)];
    
      fft_out = sqrt(ctx.frame.fft) * ifft(fftshift(fft_in));
    
      ctx.tx.data(1 + offset : symb_len + offset, ant_number) = [fft_out(end - cp_len + 1: end); fft_out];
    
    end
    
    offset += symb_len;
    
  endfor

  result = ctx;
  
endfunction
