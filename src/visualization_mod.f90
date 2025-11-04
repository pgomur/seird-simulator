!! Module providing ASCII-based visualization utilities
!! for SEIRD model results. It displays population compartments
!! as horizontal bar charts with additional summary statistics.
module visualization_mod
    use precision_mod
    use parameters_mod
    implicit none
    public :: render_ascii

contains

    !!----------------------------------------------------------------------
    !! Render SEIRD model state as an ASCII table with proportional bars
    !!
    !! @param[in] y    State vector containing SEIRD components
    !!                 in the order (S, E, I, R, D)
    !! @param[in] day  Simulation day or time step index
    !! @param[in] p    Model parameters of type `seird_params_type`
    !!
    !! @details
    !! This routine prints the SEIRD compartment values in a compact
    !! ASCII format. Each component (Susceptible, Exposed, Infectious,
    !! Recovered, Deceased) is displayed as a horizontal bar whose length
    !! is proportional to its percentage of the total population.
    !!
    !! Additional derived quantities printed include:
    !!  - Active population (S + E + I + R)
    !!  - Estimated infection ratio (% of active infected)
    !!  - Daily vaccination estimate
    !!  - Contact rate and waning immunity rate
    !!
    !! The subroutine ensures all compartments are non-negative and
    !! uses a small epsilon to avoid division by zero when total ≈ 0.
    !!----------------------------------------------------------------------
    subroutine render_ascii(y, day, p)
        !! Print SEIRD values as ASCII bars and summary statistics.
        real(dp), intent(in) :: y(:)
        integer, intent(in) :: day
        type(seird_params_type), intent(in) :: p

        real(dp) :: total, active, pct
        real(dp) :: infected_ratio, vaccinated_est
        integer :: bar_len, max_bar_len
        character(len=50) :: bar
        real(dp) :: S_disp, E_disp, I_disp, R_disp, D_disp

        !--------------------------------------------------
        ! Ensure all components are non-negative
        !--------------------------------------------------
        S_disp = max(0.0_dp, y(1))
        E_disp = max(0.0_dp, y(2))
        I_disp = max(0.0_dp, y(3))
        R_disp = max(0.0_dp, y(4))
        D_disp = max(0.0_dp, y(5))

        total  = max(epsilon_dp, S_disp + E_disp + I_disp + R_disp + D_disp)
        active = max(epsilon_dp, min(S_disp + E_disp + I_disp + R_disp, p%N))

        infected_ratio = merge(I_disp / active * 100.0_dp, 0.0_dp, active > epsilon_dp)
        vaccinated_est = S_disp * p%vaccination_rate  ! daily vaccination estimate

        max_bar_len = 50

        ! Header with day index
        write(*,'("SEIRD State - Day ",I0)') day
        write(*,'(A20,A12,A12,A)') "Component", "Value", "Percent(%)", "Visual"

        ! Susceptible
        pct = S_disp / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Susceptible", S_disp, pct, trim(bar)

        ! Exposed
        pct = E_disp / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Exposed", E_disp, pct, trim(bar)

        ! Infectious
        pct = I_disp / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Infectious", I_disp, pct, trim(bar)

        ! Recovered
        pct = R_disp / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Recovered", R_disp, pct, trim(bar)

        ! Deceased
        pct = D_disp / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Deceased", D_disp, pct, trim(bar)

        ! Vaccination per day (estimated)
        pct = vaccinated_est / total * 100.0_dp
        bar_len = max(0, min(int(pct / 100.0_dp * max_bar_len), max_bar_len))
        bar = repeat("|", bar_len)
        write(*,'(A20,F12.2,F12.2,1X,A)') "Vaccination/day", vaccinated_est, pct, trim(bar)

        ! Summary statistics
        write(*,'(A30,F10.2," people")') "Active population (S+E+I+R):", active
        write(*,'(A30,F10.2," %")') "Infected/Active ratio:", infected_ratio
        write(*,'(A30,F10.2," contacts/day")') "Contact rate:", p%contact_rate
        write(*,'(A30,F10.2," 1/day")') "Immunity waning rate:", p%waning_immunity_rate

        print *, ""  ! Visual separator
    end subroutine render_ascii

end module visualization_mod
