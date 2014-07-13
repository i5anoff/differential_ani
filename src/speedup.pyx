#!/usr/bin/python

from __future__ import division

import numpy as np
from numpy.random import random
cimport numpy as np
cimport cython

from libc.math cimport sqrt
from libc.math cimport pow
from libc.math cimport fabs


DINT = np.int
ctypedef np.int_t DINT_t
DDOUBLE = np.double
ctypedef np.double_t DDOUBLE_t

@cython.cdivision(True)
cdef inline double get_force(double lim,double a, double b):
  cdef double dd = sqrt(pow(a,2)+pow(b,2))
  if dd <= 0.:
    return 0.
  else:
    return (lim-dd)/dd

@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
def pyx_collision_reject(l,np.ndarray[double, mode="c",ndim=2] sx,double farl):

  cdef unsigned int vnum = l.vnum

  cdef np.ndarray[double, mode="c",ndim=1] X = l.X[:vnum,0].ravel()
  cdef np.ndarray[double, mode="c",ndim=1] Y = l.X[:vnum,1].ravel()

  near = l.get_all_near_vertices(farl)

  cdef unsigned int k
  cdef unsigned int c
  cdef unsigned int j
  cdef unsigned int ind

  cdef double x
  cdef double y
  cdef double dx
  cdef double dy
  cdef double force
  cdef double resx
  cdef double resy

  for j in range(vnum):
    k = <unsigned int>len(near[j])
    resx = 0.
    resy = 0.
    x = X[j]
    y = Y[j]
    for c in range(k):
      ind = <unsigned int>near[j][c]
      if ind == k:
        continue
      dx = x-X[ind]
      dy = y-Y[ind]
      force = get_force(farl,dx,dy)
      resx += dx*force
      resy += dy*force

    sx[j,0] += resx
    sx[j,1] += resy

@cython.cdivision(True)
cdef dist_scale(double a, double b):
  cdef double ad
  cdef double bd 
  cdef double dd = sqrt(pow(a,2)+pow(b,2))
  if dd <= 0.:
    return 0.,0.,0.
  else:
    ad = a/dd
    bd = b/dd
    return dd,ad,bd

@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
def pyx_growth(l,near_limit):

  cdef unsigned int sind = l.sind
  cdef unsigned int vnum = l.vnum

  cdef np.ndarray[long, mode="c",ndim=2] SV = l.SV[:sind,:]
  cdef dict SS = l.SS

  cdef np.ndarray[long, mode="c",ndim=1] SVMASK = l.SVMASK[:sind]

  cdef np.ndarray[double, mode="c",ndim=1] X = l.X[:vnum,0].ravel()
  cdef np.ndarray[double, mode="c",ndim=1] Y = l.X[:vnum,1].ravel()

  cdef unsigned int i
  cdef unsigned int s1
  cdef unsigned int s2

  cdef double dx1
  cdef double dy1
  cdef double dx2
  cdef double dy2
  cdef double dd1
  cdef double dd2
  cdef double kappa2

  grow = []
  for i in range(sind):

    if SVMASK[i]<1:
      continue

    s1 = SS[i][0]
    s2 = SS[i][1]

    dd1,dx1,dy1 = dist_scale(X[SV[s1,0]]-X[SV[s1,1]],Y[SV[s1,0]]-Y[SV[s1,1]])
    dd2,dx2,dy2 = dist_scale(X[SV[s2,0]]-X[SV[s2,1]],Y[SV[s2,0]]-Y[SV[s2,1]])
    
    kappa2 = sqrt(1.-fabs(dx1*dx2+dy1*dy2))

    if random()<kappa2 and (dd1+dd2)*0.5>near_limit:
      grow.append(i)

  new_vertices = []
  cdef unsigned int g
  cdef unsigned int newv
  for g in grow:
    newv,_ = l.split_segment(g)
    new_vertices.append(newv)

  return new_vertices
