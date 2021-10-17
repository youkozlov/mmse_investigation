
function [result] = modulate_slot(ctx)

  ctx.buf.data = zeros(ctx.bwp.num_scs, ctx.frame.num_symbols, ctx.rf.num_ants);

  ctx.buf.dmrs = zeros(ctx.bwp.num_scs / 2, ctx.frame.num_symbols);
  
  num_data_symbs = size(ctx.alloc.data, 2);
  
  num_dmrs_symbs = size(ctx.alloc.dmrs, 2);
  
  num_iqs = (num_data_symbs - num_dmrs_symbs) * ctx.bwp.num_scs * ctx.alloc.num_layers;
  
  ctx.buf.txiqs = rand_qammod(num_iqs, ctx.alloc.qm);

  iq_offset = 0;
  
  for symbol_number = 1 : ctx.frame.num_symbols
    
    if (~isempty(ctx.alloc.dmrs(ctx.alloc.dmrs == symbol_number)))

      ctx.buf.dmrs(1:end, symbol_number) = rand_qammod(size(ctx.buf.dmrs, 1), 4);
      
      dmrs = zeros(ctx.bwp.num_scs, ctx.alloc.num_layers);
      
      dmrs(1:2:end, 1) = ctx.buf.dmrs(1:end, symbol_number);

      dmrs(2:2:end, 2) = ctx.buf.dmrs(1:end, symbol_number);
      
      for sc = 1: ctx.bwp.num_scs
        
        ctx.buf.data(sc, symbol_number, 1) = dmrs(sc, 1) * ctx.alloc.precode(1, 1) + dmrs(sc, 2) * ctx.alloc.precode(1, 2);
        
        ctx.buf.data(sc, symbol_number, 2) = dmrs(sc, 1) * ctx.alloc.precode(2, 1) + dmrs(sc, 2) * ctx.alloc.precode(2, 2);
      
      end

    elseif (~isempty(ctx.alloc.data(ctx.alloc.data == symbol_number)))

      for sc = 1: ctx.bwp.num_scs
        
        iq = ctx.buf.txiqs(1 + iq_offset: 2 + iq_offset);
        
        ctx.buf.data(sc, symbol_number, 1) = iq(1) * ctx.alloc.precode(1, 1) + iq(2) * ctx.alloc.precode(1, 2);
        
        ctx.buf.data(sc, symbol_number, 2) = iq(1) * ctx.alloc.precode(2, 1) + iq(2) * ctx.alloc.precode(2, 2);

        iq_offset += 2;
      
      end
        
    end
      
  end

  result = ctx;
 
endfunction
