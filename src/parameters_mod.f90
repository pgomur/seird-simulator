!! Module defining parameters for the SEIRD epidemiological model.
!! It contains a derived type holding model parameters and a routine
!! to initialize them with default values.
module parameters_mod
    use precision_mod
    implicit none
    public :: seird_params_type, init_params

    !! Derived type containing all parameters for the SEIRD model.
    !!
    !! The parameters represent transmission, transition, and outcome
    !! rates within the population, as well as optional modifiers
    !! for vaccination and other effects.
    type :: seird_params_type
        !! Infection rate (contacts per person per time unit)
        real(dp) :: beta    = 0.5_dp

        !! Incubation rate (1 / average incubation period)
        real(dp) :: sigma   = 0.2_dp

        !! Recovery rate (1 / average infectious period)
        real(dp) :: gamma   = 0.1_dp

        !! Disease-induced mortality rate
        real(dp) :: mu      = 0.01_dp

        !! Total population size
        real(dp) :: N = 1000._dp

        !! Rate of vaccination (fraction vaccinated per time unit)
        real(dp) :: vaccination_rate = 0.0_dp

        !! Average number of contacts per person per time unit
        real(dp) :: contact_rate = 1.0_dp

        !! Rate at which immunity wanes (returns to susceptible state)
        real(dp) :: waning_immunity_rate = 0.0_dp

        !! Fraction of infections that are asymptomatic
        real(dp) :: asymptomatic_fraction = 0.0_dp

        !! Hospitalization rate among infected individuals
        real(dp) :: hospitalization_rate = 0.0_dp

        !! Mortality rate among severe (hospitalized) cases
        real(dp) :: mortality_rate_severe = 0.0_dp
    end type seird_params_type


contains

    !! Initialize the SEIRD model parameters with default values.
    !!
    !! This subroutine resets all fields of a `seird_params_type`
    !! instance to their default values, ensuring consistent
    !! initialization before simulation.
    !!
    !! @param p  SEIRD parameter structure to initialize.
    subroutine init_params(p)
        type(seird_params_type), intent(out) :: p

        p%beta    = 0.5_dp
        p%sigma   = 0.2_dp
        p%gamma   = 0.1_dp
        p%mu      = 0.01_dp

        p%N                     = 1000._dp
        p%vaccination_rate      = 0.0_dp
        p%contact_rate          = 1.0_dp
        p%waning_immunity_rate  = 0.0_dp
        p%asymptomatic_fraction = 0.0_dp
        p%hospitalization_rate  = 0.0_dp
        p%mortality_rate_severe = 0.0_dp
    end subroutine init_params

end module parameters_mod
