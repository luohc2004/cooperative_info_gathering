function [ptNext,wNext] = ResampleParticle(ptNow,wNow,field)

nPt = length(ptNow(1,:));
ptNext = nan(2,nPt);

for iPt = 1:nPt
    bSample = 1;
    while (bSample)
        ptNext(:,iPt) = ptNow(:,find(rand <= cumsum(wNow),1));
        if IsParticleInBoundary(ptNext(:,iPt),field.boundary) % if the new particle is not on the field
            bSample = 0;
        end
    end
end

% update weight: uniform because particles lose info
wNext = (1/nPt)*ones(1,nPt);

end

% discrimation of the situation whether the reampled particle is on the
% field
function bLoc = IsParticleInBoundary(pt,fieldBound)
    bLocX = pt(1) >= fieldBound(1) && pt(1) <= fieldBound(2);
    bLocY = pt(2) >= fieldBound(3) && pt(2) <= fieldBound(4);
    
    bLoc = bLocX && bLocY;
end