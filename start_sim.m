
function [result] = start_sim()

  clear;

  ctx = {};

  ctx.frame.num_slots     = 20;
  ctx.frame.num_symbols   = 14;
  ctx.frame.cp_len        = [352 288 288 288 288 288 288 288 288 288 288 288 288 288];
  ctx.frame.fft           = 4096;
  ctx.frame.num_prb_sc    = 12;
  ctx.frame.slot_len      = sum(ctx.frame.cp_len + ctx.frame.fft);
  ctx.frame.scs           = 30000;

  ctx.bwp.num_scs         = 3276;

  ctx.rf.num_ants         = 2;

  ctx.ch.snr              = -32;
  ctx.ch.to               = 0;
  ctx.ch.to_speed         = 2 * 0.0017857;
  ctx.ch.fo               = 200;
  ctx.ch.attenuation      = [0 30; 30 0];

  ctx.rx.shift            = 16;
  
  ctx.alloc.num_layers    = 2;
  ctx.alloc.start_rb      = 0;
  ctx.alloc.num_rbs       = 273;
  ctx.alloc.data          = 2:13;
  ctx.alloc.dmrs          = [3 11];
  ctx.alloc.precode       = 1/2 * [1 1; j -j];
  ctx.alloc.qm            = 256;

  ctx.ce.window           = 0.75;
  ctx.ce.mmse             = 1;

%  for i = 0:50:1000
%    i
%    ctx.ch.fo           = i;

    ctx = modulate_slot(ctx);  
    ctx = tx_slot(ctx);
    ctx = pass_slot(ctx);
    ctx = rx_slot(ctx);
    ctx = demodulate_slot(ctx);
    [evm_percentage evm_db] = estimate_evm(ctx.buf.rxiqs, ctx.buf.txiqs)
    ctx.meas.evm_percentage = evm_percentage;
    ctx.meas.evm_db = evm_db;
%  endfor

  result = ctx;

endfunction
