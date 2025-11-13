function y = range(x,dim)
%RANGE  Sample range.
%   Y = RANGE(X) returns the range of the values in X.  For a vector input,
%   Y is the difference between the maximum and minimum values.  For a
%   matrix input, Y is a vector containing the range for each column.  For
%   N-D arrays, RANGE operates along the first non-singleton dimension.
%
%   RANGE treats NaNs as missing values, and ignores them.
%
%   Y = RANGE(X,'all') operates on all the dimensions of X.
%
%   Y = RANGE(X,DIM) operates along the dimension DIM.
%
%   Y = RANGE(X,VECDIM) operates along all the dimensions specified in VECDIM.
%
%   See also BOUNDS, MIN, MAX, IQR, MAD, STD.

%   Copyright 1993-2018 The MathWorks, Inc.

if nargin < 2
    y = max(x) - min(x);
else
    y = max(x,[],dim) - min(x,[],dim);
end
