!! Module implementing the SEIRD epidemiological model equations.
!! It provides routines to compute the right-hand side (RHS)
!! of the SEIRD system for both single-population and batched simulations.
module seird_model_mod
    use precision_mod
    use parameters_mod
    implicit none
    public :: seird_rhs, seird_rhs_batch

contains

    !!----------------------------------------------------------------------
    !! Compute the time derivatives (RHS) of the SEIRD model
    !! for a single population.
    !!
    !! @param[in]  y   State vector (S, E, I, R, D)
    !! @param[out] dydt  Computed derivatives of the SEIRD system
    !! @param[in]  p   Model parameters of type `seird_params_type`
    !!
    !! @note
    !! The system assumes:
    !!  - Homogeneous mixing population
    !!  - Time-independent parameters
    !!  - Optional vaccination and immunity waning effects
    !!
    !! The equations are:
    !!   dS/dt = -βSI/N - vaccination + waning
    !!   dE/dt = βSI/N - σE
    !!   dI/dt = σE - (γ + μ)I
    !!   dR/dt = γI + vaccination - waning
    !!   dD/dt = μI + mortality_rate_severe * hospitalization_rate * I
    !!
    !! A small epsilon is used to avoid division by zero when N ≈ 0.
    !!----------------------------------------------------------------------
    subroutine seird_rhs(y, dydt, p)
        real(dp), intent(in)  :: y(:)
        real(dp), intent(out) :: dydt(size(y))
        type(seird_params_type), intent(in) :: p

        real(dp) :: S, E, I, R, D, N
        real(dp) :: infection, vaccinated, waned

        S = y(1)
        E = y(2)
        I = y(3)
        R = y(4)
        D = y(5)

        N = S + E + I + R
        if (N < epsilon_dp) N = epsilon_dp

        infection = p%beta * p%contact_rate * S * I / N
        vaccinated = p%vaccination_rate * S
        waned     = p%waning_immunity_rate * R

        dydt(1) = -infection - vaccinated + waned
        dydt(2) =  infection - p%sigma * E
        dydt(3) =  p%sigma * E - (p%gamma + p%mu) * I
        dydt(4) =  p%gamma * I + vaccinated - waned
        dydt(5) =  p%mu * I + p%mortality_rate_severe * p%hospitalization_rate * I
    end subroutine seird_rhs


    !!----------------------------------------------------------------------
    !! Compute the SEIRD RHS for multiple populations in parallel.
    !!
    !! @param[in]  y        2D array (5 × num_pop) of state vectors
    !! @param[out] dydt     2D array (5 × num_pop) of computed derivatives
    !! @param[in]  p        Common model parameters
    !! @param[in]  num_pop  Number of populations to simulate
    !!
    !! @details
    !! This routine evaluates the SEIRD equations for several populations
    !! independently, enabling coarse-grain parallelism.
    !!
    !! OpenMP directives (`!$omp parallel do`) are used for thread-level
    !! parallel execution when compiled with OpenMP enabled.
    !!----------------------------------------------------------------------
    subroutine seird_rhs_batch(y, dydt, p, num_pop)
        integer, intent(in) :: num_pop
        real(dp), intent(in)  :: y(5, num_pop)
        real(dp), intent(out) :: dydt(5, num_pop)
        type(seird_params_type), intent(in) :: p

        integer :: idx
        real(dp) :: S_val, E_val, I_val, R_val, D_val, N_val
        real(dp) :: infection, vaccinated, waned

!$omp parallel do private(idx,S_val,E_val,I_val,R_val,D_val,N_val,infection,vaccinated,waned)
        do idx = 1, num_pop
            S_val = y(1,idx)
            E_val = y(2,idx)
            I_val = y(3,idx)
            R_val = y(4,idx)
            D_val = y(5,idx)

            N_val = S_val + E_val + I_val + R_val
            if (N_val < epsilon_dp) N_val = epsilon_dp

            infection = p%beta * p%contact_rate * S_val * I_val / N_val
            vaccinated = p%vaccination_rate * S_val
            waned     = p%waning_immunity_rate * R_val

            dydt(1,idx) = -infection - vaccinated + waned
            dydt(2,idx) =  infection - p%sigma * E_val
            dydt(3,idx) =  p%sigma * E_val - (p%gamma + p%mu) * I_val
            dydt(4,idx) =  p%gamma * I_val + vaccinated - waned
            dydt(5,idx) =  p%mu * I_val + p%mortality_rate_severe * p%hospitalization_rate * I_val
        end do
!$omp end parallel do
    end subroutine seird_rhs_batch

end module seird_model_mod
