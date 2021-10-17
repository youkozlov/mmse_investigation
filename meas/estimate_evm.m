
function [percent db] = estimate_evm(sig, ref)

  assert(size(sig, 2) == size(ref, 2), "Size of sig and ref should equal");

  err = abs(sig .- ref);

  errSum = sum(err .* err);

  refSum = sum(abs(ref) .* abs(ref));

  evm = sqrt(errSum / refSum);

  percent = evm * 100;

  db = 20 * log10(evm);

endfunction
