function w = Wx(pix_vect,A,p)
%This function calculates the deformed position of a given pixel for a
%given basis function matrix (A) and deformation vector (p)
w = pix_vect(1,:)' +(A*p);
end