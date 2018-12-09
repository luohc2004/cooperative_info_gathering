function o = TakeAction( o )
%TAKEACTION Summary of this function goes here
%   Detailed explanation goes here

[U,I] = max(o.utilCnd);

o.s = o.act(I,:)';
o.util = U;
o.actIdx = I;

o.hist.s(:,end+1) = o.s;
o.hist.util(end+1) = o.util;
o.hist.actIdx(end+1) = o.actIdx;

end
