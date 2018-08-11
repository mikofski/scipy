from __future__ import division, print_function, absolute_import
import warnings
import cython
cimport cpython
from . cimport c_zeros

cdef double TOL = 1.48e-8
cdef int MAXITER = 50


# the new standard callback function that uses the params struct instead of tuple
@staticmethod
cdef double scipy_zeros_functions_func(double x, c_zeros.scipy_zeros_parameters *params):
    cdef c_zeros.scipy_zeros_parameters *myparams
    cdef tuple args
    cdef callback_type_tup f

    myparams = params
    args = <tuple> myparams.args if myparams.args is not NULL else ()
    f = myparams.function

    return f(x, args)  # recall callback_type takes a double and a tuple


@cython.cdivision(True)
cdef double newton(callback_type_tup func, double p0, callback_type_tup fprime, tuple args):
    # Newton-Rapheson method
    cdef double fder, fval, p
    for iter in range(MAXITER):
        fder = fprime(p0, args)
        if fder == 0:
            msg = "derivative was zero."
            warnings.warn(msg, RuntimeWarning)
            return p0
        fval = func(p0, args)
        # Newton step
        p = p0 - fval / fder
        if abs(p - p0) < TOL:  # np_abs(p - p0).max() < tol:
            return p
        p0 = p
    msg = "Failed to converge after %d iterations, value is %s" % (MAXITER, p)
    raise RuntimeError(msg)


# cythonized way to call scalar bisect
cdef double bisect(callback_type_tup f, double xa, double xb, tuple args, double xtol, double rtol, int iter):
    cdef c_zeros.scipy_zeros_parameters myparams
    # create params struct
    myparams.args = <cpython.PyObject *> args
    myparams.function = f
    return c_zeros.bisect(scipy_zeros_functions_func, xa, xb, xtol, rtol, iter, <c_zeros.default_parameters *> &myparams)
