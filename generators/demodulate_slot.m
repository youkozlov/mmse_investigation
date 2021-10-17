function [result] = demodulate_slot(ctx)
  
  ctx.buf.chests = zeros(ctx.bwp.num_scs / 2, ctx.frame.num_symbols, ctx.rf.num_ants, ctx.alloc.num_layers);

  ctx.buf.dft_chests = zeros(ctx.bwp.num_scs / 2, ctx.frame.num_symbols, ctx.rf.num_ants, ctx.alloc.num_layers);

  ctx.buf.interpolated_chests = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols, ctx.rf.num_ants, ctx.alloc.num_layers);

  ctx.buf.noise = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols, ctx.rf.num_ants, ctx.alloc.num_layers);

  ctx.buf.eq_data = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols);

  ctx.buf.foc_data = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols);

  ctx.dmrs.chestsIdx = zeros(1, ctx.frame.num_symbols);
  
  num_data_symbs = size(ctx.alloc.data, 2);
  
  num_dmrs_symbs = size(ctx.alloc.dmrs, 2);

  num_iqs = (num_data_symbs - num_dmrs_symbs) * ctx.bwp.num_scs * ctx.alloc.num_layers;
  
  ctx.buf.rxiqs = zeros(1, num_iqs);

  % chest estimation
  for symbol_number = 1 : ctx.frame.num_symbols
  
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

      % raw estimate
      for ant_idx = 1 : ctx.rf.num_ants
        
        ctx.buf.chests(:, symbol_number, ant_idx, 1) = ctx.rx.data(1:2:end, symbol_number, ant_idx) .* conj(ctx.buf.dmrs(:, symbol_number));
      
        ctx.buf.chests(:, symbol_number, ant_idx, 2) = ctx.rx.data(2:2:end, symbol_number, ant_idx) .* conj(ctx.buf.dmrs(:, symbol_number));
      
      endfor

      % to estimation
      raw_to = arg(sum(ctx.buf.chests(1:end-1, symbol_number, 1, 1) ./ ctx.buf.chests(2:end, symbol_number, 1, 1)));
      to = raw_to * 4096 / (2 * pi * 2)
      
      % idft filter
      win = reshape(1 - (ctx.ce.window * (1 - cos(2 * pi * [0:2047] / 2047))), [2048,1]);

      for ant_idx = 1 : ctx.rf.num_ants

        for layer_idx = 1 : ctx.alloc.num_layers

          idft_chest = ifft(ctx.buf.chests(:, symbol_number, ant_idx, layer_idx), 2048) .* win;
          
          ctx.buf.dft_chests(:, symbol_number, ant_idx, layer_idx) = fft(idft_chest)(1:ctx.bwp.num_scs / 2); 

        endfor
      
      endfor

      ctx.buf.dft_chests(1, symbol_number, :, :) = ctx.buf.dft_chests(2, symbol_number, :, :);
      
      ctx.buf.dft_chests(end, symbol_number, :, :) = ctx.buf.dft_chests(end-1, symbol_number, :, :);
 
      % linear interpolate
      ctx.buf.interpolated_chests(1:2:end, symbol_number, :, :) = ctx.buf.dft_chests(:, symbol_number, :, :);

      ctx.buf.interpolated_chests(2:2:end-2, symbol_number, :, :) = 0.5 * (ctx.buf.interpolated_chests(1:2:end-2, symbol_number, :, :)...
                                               + ctx.buf.interpolated_chests(3:2:end, symbol_number, :, :));

      ctx.buf.interpolated_chests(end, symbol_number, :, :) = 2.0 * ctx.buf.interpolated_chests(end - 1, symbol_number, :, :)...
                                                             - ctx.buf.interpolated_chests(end - 2, symbol_number, :, :);

      % measurements
      ctx.dmrs.power(symbol_number, :) = sum(abs(ctx.rx.data(1:2:end, symbol_number, :)) .^ 2) / (ctx.bwp.num_scs / 2);
      
      ctx.dmrs.noise(symbol_number, :, :) = sum(abs(ctx.buf.chests(:, symbol_number, :, :) - ctx.buf.dft_chests(:, symbol_number, :, :)) .^ 2) / (ctx.bwp.num_scs / 2);
                                                 
   end
  
  end

  % to comp
  for symbol_number = 1 : ctx.frame.num_symbols

    %toShifter = reshape(exp(-j * ctx.dmrs.to * [0:ctx.bwp.num_scs - 1]), [ctx.bwp.num_scs, 1]);
  
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

    elseif (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))

      %ctx.rx.data(:, symbol_number, 1) .*= toShifter;
      %ctx.rx.data(:, symbol_number, 2) .*= toShifter;

    end
  end
  
  % fo estimation
  if (size(ctx.alloc.dmrs, 2) > 1)
    
    chest1 = ctx.buf.chests(:, ctx.alloc.dmrs(1), 1, 1);
    
    chest2 = ctx.buf.chests(:, ctx.alloc.dmrs(2), 1, 1);
    
    ctx.dmrs.raw_foe = arg(sum(chest2 ./ chest1));

    ctx.dmrs.fo = ctx.dmrs.raw_foe / (ctx.alloc.dmrs(2) - ctx.alloc.dmrs(1));

  end

  ctx.dmrs.chestsIdx = [3 3 3 3 3 3 3 11 11 11 11 11 11 11];

  for symbol_number = 1 : ctx.frame.num_symbols

    if (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))

    end

  end  
  
  % eq
  for symbol_number = 1 : ctx.frame.num_symbols
  
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

    elseif (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))
      
      dmrsSymbol = ctx.dmrs.chestsIdx(symbol_number);
 
      if (ctx.ce.mmse)
        I = [ctx.dmrs.noise(dmrsSymbol, 1, 1) 0; 0 ctx.dmrs.noise(dmrsSymbol, 2, 2)];
      else
        I = [0 0; 0 0];
      end

      for sc = 1 : ctx.bwp.num_scs
      
        H = [ctx.buf.interpolated_chests(sc, dmrsSymbol, 1, 1) ctx.buf.interpolated_chests(sc, dmrsSymbol, 1, 2);...
             ctx.buf.interpolated_chests(sc, dmrsSymbol, 2, 1) ctx.buf.interpolated_chests(sc, dmrsSymbol, 2, 2)];
                
        F = H' * inverse_matrix(H * H' + I);

        X = F * reshape(ctx.rx.data(sc, symbol_number, :), [2, 1]);

        ctx.buf.eq_data(sc, symbol_number, 1) = X(1);

        ctx.buf.eq_data(sc, symbol_number, 2) = X(2);

      end
    
    end
        
  end

  % foc
  for symbol_number = 1 : ctx.frame.num_symbols
  
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

    elseif (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))
    
      dmrsSymbol = ctx.dmrs.chestsIdx(symbol_number);
    
      rotator = exp(j * ctx.dmrs.fo * (dmrsSymbol - symbol_number));
    
      for layer_number = 1 : ctx.alloc.num_layers
            
        ctx.buf.foc_data(:, symbol_number, layer_number) = ctx.buf.eq_data(:, symbol_number, layer_number) * rotator;
       
      end 
    
    end
        
  end
  
  
  % demap
  iq_offset = 0;

  for symbol_number = 1 : ctx.frame.num_symbols
  
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

    elseif (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))

    for sc = 1: ctx.bwp.num_scs

        ctx.buf.rxiqs(1 + iq_offset: 2 + iq_offset) = [ctx.buf.foc_data(sc, symbol_number, 1) ctx.buf.foc_data(sc, symbol_number, 2)];

        iq_offset += 2;

      end
    
    end
        
  end
    
  result = ctx;

endfunction 
  
