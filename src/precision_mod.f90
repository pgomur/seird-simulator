!! Module defining precision constants and small values
!! for safe numerical computations using double precision.
module precision_mod
    implicit none
    public

    !! Double precision kind parameter
    integer, parameter :: dp = kind(1.0d0)

    !! Small tolerance value for double precision
    !! Used to test numerical equality within floating-point accuracy
    real(dp), parameter :: epsilon_dp = 1.0e-12_dp

    !! Extremely small double precision constant
    !! Useful to prevent division by zero and similar numerical issues
    real(dp), parameter :: tiny_dp = 1.0e-30_dp

end module precision_mod
