!! Module providing numerical integration methods for SEIRD model equations.
!!
!! This module implements explicit numerical integration schemes for solving
!! systems of ordinary differential equations (ODEs) used in epidemiological
!! modeling. It includes simple fixed-step and adaptive methods.
!!
!! ### Available integrators
!! - `euler_step`: Simple first-order explicit Euler method.
!! - `rk4_step`: Classical fourth-order Runge–Kutta method.
!! - `rk45_step`: Adaptive Dormand–Prince (Runge–Kutta 4(5)) method.
!!
!! ### Statistics tracking
!! The `integration_stats_type` stores step counts, rejected steps,
!! and maximum local truncation errors, useful for monitoring adaptive integrators.
module numerics_mod
    use precision_mod
    use seird_model_mod
    use parameters_mod
    implicit none
    public :: euler_step, rk4_step, rk45_step, integration_stats_type

    !! Type containing statistics about the integration process.
    type :: integration_stats_type
        integer :: steps_taken = 0       !! Number of total steps taken.
        integer :: rejected_steps = 0    !! Number of steps rejected due to large error.
        real(dp) :: max_error = 0._dp    !! Maximum local error encountered.
    end type integration_stats_type

contains

    !! -----------------------------------------------------------------------
    !! Perform a single explicit Euler step.
    !!
    !! A first-order integration method, useful for quick tests but not
    !! recommended for stiff or long simulations due to limited accuracy.
    !!
    !! @param[inout] y  State vector to update (e.g. [S, E, I, R, D])
    !! @param[in]    dt Time step size
    !! @param[in]    p  Model parameters (of type `seird_params_type`)
    !! -----------------------------------------------------------------------
    subroutine euler_step(y, dt, p)
        real(dp), intent(inout) :: y(:)
        real(dp), intent(in) :: dt
        type(seird_params_type), intent(in) :: p
        real(dp), allocatable :: dydt(:)

        allocate(dydt(size(y)))
        call seird_rhs(y, dydt, p)
        y = y + dt * dydt
        deallocate(dydt)
    end subroutine euler_step


    !! -----------------------------------------------------------------------
    !! Perform a single classical 4th-order Runge–Kutta (RK4) integration step.
    !!
    !! Provides good accuracy for non-stiff problems using four intermediate
    !! evaluations per step. Fixed time step only.
    !!
    !! @param[inout] y  State vector (updated in place)
    !! @param[in]    dt Time step
    !! @param[in]    p  Model parameters
    !! -----------------------------------------------------------------------
    subroutine rk4_step(y, dt, p)
        real(dp), intent(inout) :: y(:)
        real(dp), intent(in) :: dt
        type(seird_params_type), intent(in) :: p

        integer :: n
        real(dp), allocatable :: k1(:), k2(:), k3(:), k4(:)

        n = size(y)
        allocate(k1(n), k2(n), k3(n), k4(n))

        call seird_rhs(y, k1, p)
        call seird_rhs(y + 0.5_dp*dt*k1, k2, p)
        call seird_rhs(y + 0.5_dp*dt*k2, k3, p)
        call seird_rhs(y + dt*k3, k4, p)

        y = y + dt*(k1 + 2._dp*k2 + 2._dp*k3 + k4)/6._dp

        deallocate(k1, k2, k3, k4)
    end subroutine rk4_step


    !! -----------------------------------------------------------------------
    !! Perform an adaptive Dormand–Prince Runge–Kutta 4(5) integration step.
    !!
    !! The method estimates both 4th- and 5th-order solutions to adapt the
    !! time step based on a user-defined tolerance, ensuring stability and
    !! precision with minimal computational cost.
    !!
    !! @param[inout] y       State vector (updated to next accepted step)
    !! @param[inout] dt      Current time step (adaptively adjusted)
    !! @param[in]    p       Model parameters
    !! @param[in]    abstol  Absolute error tolerance
    !! @param[in]    reltol  Relative error tolerance
    !! @param[inout] stats   Structure storing integration statistics
    !!
    !! The method updates:
    !! - `stats%steps_taken`
    !! - `stats%rejected_steps`
    !! - `stats%max_error`
    !! -----------------------------------------------------------------------
    subroutine rk45_step(y, dt, p, abstol, reltol, stats)
        real(dp), intent(inout) :: y(:)
        real(dp), intent(inout) :: dt
        type(seird_params_type), intent(in) :: p
        real(dp), intent(in) :: abstol, reltol
        type(integration_stats_type), intent(inout) :: stats

        integer :: n
        real(dp) :: error, factor
        real(dp), allocatable :: k(:,:), y5(:), y4(:)

        n = size(y)
        allocate(k(n,7), y5(n), y4(n))

        !! Compute Dormand–Prince intermediate stages
        call seird_rhs(y, k(:,1), p)
        call seird_rhs(y + dt*(1._dp/5._dp*k(:,1)), k(:,2), p)
        call seird_rhs(y + dt*(3._dp/40._dp*k(:,1) + 9._dp/40._dp*k(:,2)), k(:,3), p)
        call seird_rhs(y + dt*(44._dp/45._dp*k(:,1) - 56._dp/15._dp*k(:,2) + 32._dp/9._dp*k(:,3)), k(:,4), p)
        call seird_rhs(y + dt*(19372._dp/6561._dp*k(:,1) - 25360._dp/2187._dp*k(:,2) + 64448._dp/6561._dp*k(:,3) - 212._dp/729._dp*k(:,4)), k(:,5), p)
        call seird_rhs(y + dt*(9017._dp/3168._dp*k(:,1) - 355._dp/33._dp*k(:,2) + 46732._dp/5247._dp*k(:,3) + 49._dp/176._dp*k(:,4) - 5103._dp/18656._dp*k(:,5)), k(:,6), p)
        call seird_rhs(y + dt*(35._dp/384._dp*k(:,1) + 500._dp/1113._dp*k(:,3) + 125._dp/192._dp*k(:,4) - 2187._dp/6784._dp*k(:,5) + 11._dp/84._dp*k(:,6)), k(:,7), p)

        !! Compute 5th- and 4th-order estimates
        y5 = y + dt*(35._dp/384._dp*k(:,1) + 500._dp/1113._dp*k(:,3) + 125._dp/192._dp*k(:,4) - 2187._dp/6784._dp*k(:,5) + 11._dp/84._dp*k(:,6))
        y4 = y + dt*(5179._dp/57600._dp*k(:,1) + 7571._dp/16695._dp*k(:,3) + 393._dp/640._dp*k(:,4) - 92097._dp/339200._dp*k(:,5) + 187._dp/2100._dp*k(:,6) + 1._dp/40._dp*k(:,7))

        !! Compute local truncation error and update statistics
        error = maxval(abs(y5 - y4))
        stats%max_error = max(stats%max_error, error)
        stats%steps_taken = stats%steps_taken + 1

        !! Accept or reject the step based on error tolerance
        if (error <= max(abstol, reltol*maxval(abs(y)))) then
            y = y5
            factor = 0.9_dp * (max(abstol, error)/error)**0.2_dp
            factor = min(5._dp, max(0.1_dp, factor))
        else
            stats%rejected_steps = stats%rejected_steps + 1
            factor = 0.9_dp * (max(abstol, error)/error)**0.2_dp
            factor = max(0.1_dp, factor)
        end if

        !! Adjust next time step within allowed range
        dt = max(dt*factor, 1.0e-8_dp)

        deallocate(k, y5, y4)
    end subroutine rk45_step

end module numerics_mod
