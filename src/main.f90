!! Main program for running SEIRD epidemiological model simulations.
!!
!! This driver coordinates parameter initialization, time integration,
!! output management, and optional visualization. It can be executed
!! with command-line arguments to override default simulation settings.
!!
!! ### Command-line arguments (optional):
!! 1. Simulation days
!! 2. Integration method (`Euler`, `RK4`, `RK45`)
!! 3–7. Initial values: S, E, I, R, D
!! 8–18. Model parameters (β, σ, γ, μ, N, vaccination_rate, contact_rate,
!!       waning_immunity_rate, asymptomatic_fraction,
!!       hospitalization_rate, mortality_rate_severe)
!!
!! Example:
!! ```
!! ./seird_main 200 RK45 999 1 0 0 0 0.4 0.25 0.1 0.02 1000 0.001 1.0 0.0 0.0 0.0 0.0
!! ```
program seird_main
    use precision_mod
    use parameters_mod
    use seird_model_mod
    use numerics_mod
    use io_mod
    use visualization_mod
    implicit none

    !! Model parameters
    type(seird_params_type) :: p

    !! State vector: [S, E, I, R, D]
    real(dp), dimension(5) :: y

    !! Integration control parameters
    real(dp) :: dt, abstol, reltol

    !! Time loop variables
    integer :: day, days, nargs

    !! Integration method name (Euler, RK4, RK45)
    character(len=10) :: method

    !! Structure for adaptive step statistics
    type(integration_stats_type) :: stats

    !! Temporary variable for command-line arguments
    character(len=32) :: arg

    !! --- CSV Output variables ---
    integer :: csv_unit
    character(len=128) :: csv_file
    real(dp) :: active, infected_ratio, vaccinated_est


    !! ----------------------------------------
    !! Default values
    !! ----------------------------------------
    days = 100
    method = "RK45"
    y = [990._dp, 10._dp, 0._dp, 0._dp, 0._dp]
    dt = 1._dp
    abstol = 1.0e-8_dp
    reltol = 1.0e-6_dp
    stats = integration_stats_type()
    call init_params(p)


    !! ----------------------------------------
    !! Parse command-line arguments
    !! ----------------------------------------
    nargs = command_argument_count()

    if (nargs >= 1) then
        call get_command_argument(1, arg)
        read(arg,*) days
    end if
    if (nargs >= 2) then
        call get_command_argument(2, arg)
        read(arg,*) method
    end if
    if (nargs >= 3) then
        call get_command_argument(3, arg)
        read(arg,*) y(1)
    end if
    if (nargs >= 4) then
        call get_command_argument(4, arg)
        read(arg,*) y(2)
    end if
    if (nargs >= 5) then
        call get_command_argument(5, arg)
        read(arg,*) y(3)
    end if
    if (nargs >= 6) then
        call get_command_argument(6, arg)
        read(arg,*) y(4)
    end if
    if (nargs >= 7) then
        call get_command_argument(7, arg)
        read(arg,*) y(5)
    end if
    if (nargs >= 8) then
        call get_command_argument(8, arg)
        read(arg,*) p%beta
    end if
    if (nargs >= 9) then
        call get_command_argument(9, arg)
        read(arg,*) p%sigma
    end if
    if (nargs >=10) then
        call get_command_argument(10,arg)
        read(arg,*) p%gamma
    end if
    if (nargs >=11) then
        call get_command_argument(11,arg)
        read(arg,*) p%mu
    end if
    if (nargs >=12) then
        call get_command_argument(12,arg)
        read(arg,*) p%N
    end if
    if (nargs >=13) then
        call get_command_argument(13,arg)
        read(arg,*) p%vaccination_rate
    end if
    if (nargs >=14) then
        call get_command_argument(14,arg)
        read(arg,*) p%contact_rate
    end if
    if (nargs >=15) then
        call get_command_argument(15,arg)
        read(arg,*) p%waning_immunity_rate
    end if
    if (nargs >=16) then
        call get_command_argument(16,arg)
        read(arg,*) p%asymptomatic_fraction
    end if
    if (nargs >=17) then
        call get_command_argument(17,arg)
        read(arg,*) p%hospitalization_rate
    end if
    if (nargs >=18) then
        call get_command_argument(18,arg)
        read(arg,*) p%mortality_rate_severe
    end if


    !! ----------------------------------------
    !! Open CSV output file
    !! ----------------------------------------
    csv_file = "data/seird_output.csv"
    open(newunit=csv_unit, file=csv_file, action="write", status="replace", form="formatted")
    write(csv_unit,'(A)') "Day,Susceptibles,Expuestos,Infectados,Recuperados,Muertos,Vacunacion,Activos,RatioInfectados,ContactRate,WaningImmunity"


    !! ----------------------------------------
    !! Initial output formatting
    !! ----------------------------------------
    print *, "=== SEIRD Model Simulation ==="
    print *, " Method: ", trim(method)
    print *, " Duration:", days, " days"
    print *, ""
    print *, " Initial conditions:"
    write(*,'(A20,F10.2)') "   Susceptible:", y(1)
    write(*,'(A20,F10.2)') "   Exposed    :", y(2)
    write(*,'(A20,F10.2)') "   Infected   :", y(3)
    write(*,'(A20,F10.2)') "   Recovered  :", y(4)
    write(*,'(A20,F10.2)') "   Deceased   :", y(5)
    print *, ""
    print *, " Model parameters:"
    write(*,'(A40,F10.4)') "   Transmission rate (β, 1/day):", p%beta
    write(*,'(A40,F10.4)') "   Incubation rate  (σ, 1/day):", p%sigma
    write(*,'(A40,F10.4)') "   Recovery rate    (γ, 1/day):", p%gamma
    write(*,'(A40,F10.4)') "   Mortality rate   (μ, 1/day):", p%mu
    write(*,'(A40,F10.2)') "   Population size  (N):", p%N
    write(*,'(A40,F10.4)') "   Vaccination rate (per person/day):", p%vaccination_rate
    write(*,'(A40,F10.4)') "   Contact rate     (contacts/day):", p%contact_rate
    write(*,'(A40,F10.4)') "   Waning immunity  (1/day):", p%waning_immunity_rate
    write(*,'(A40,F10.4)') "   Asymptomatic fraction:", p%asymptomatic_fraction
    write(*,'(A40,F10.4)') "   Hospitalization rate:", p%hospitalization_rate
    write(*,'(A40,F10.4)') "   Severe-case mortality rate:", p%mortality_rate_severe
    print *, ""


    !! ----------------------------------------
    !! Main simulation loop
    !! ----------------------------------------
    do day = 1, days
        select case(method)
        case("Euler")
            call euler_step(y, dt, p)
        case("RK4")
            call rk4_step(y, dt, p)
        case("RK45")
            call rk45_step(y, dt, p, abstol, reltol, stats)
        end select

        !! Compute derived indicators
        active = max(0.0_dp, y(1) + y(2) + y(3) + y(4))
        if (active > 0.0_dp) then
            infected_ratio = y(3)/active*100.0_dp
        else
            infected_ratio = 0.0_dp
        end if
        vaccinated_est = y(1)*p%vaccination_rate

        !! Write results to CSV
        write(csv_unit,'(I6,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2,1X,F10.2)') &
            day, y(1), y(2), y(3), y(4), y(5), vaccinated_est, active, infected_ratio, p%contact_rate, p%waning_immunity_rate

        !! Display partial results every 10 days
        if (mod(day,10) == 0 .and. day /= days) then
            call render_ascii(y, day, p)
        end if
    end do


    !! ----------------------------------------
    !! Final output
    !! ----------------------------------------
    call render_ascii(y, days, p)
    print *, "Total steps:    ", stats%steps_taken
    print *, "Rejected steps: ", stats%rejected_steps
    print *, "Max error:      ", stats%max_error

    close(csv_unit)
    print *, "Results exported to: data/seird_output.csv"

end program seird_main
