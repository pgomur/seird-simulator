!! Module providing basic input/output routines
!! for saving and loading numerical data in text files.
module io_mod
    use precision_mod
    use parameters_mod
    implicit none
    public :: save_output, load_input

contains

    !! Write a real-valued array to a text file.
    !!
    !! Each element of the array `y` is written on a separate line
    !! in the file specified by `filename`.
    !!
    !! @param filename  Name of the output file to create or replace.
    !! @param y         Array of double precision values to be saved.
    subroutine save_output(filename, y)
        character(len=*), intent(in) :: filename
        real(dp), intent(in) :: y(:)
        integer :: i
        open(unit=10, file=filename, status='replace')
        do i = 1, size(y)
            write(10,*) y(i)
        end do
        close(10)
    end subroutine save_output


    !! Read real-valued data from a text file into an array.
    !!
    !! Each line of the file is expected to contain one numerical value.
    !! The data are read sequentially into the array `y`.
    !!
    !! @param filename  Name of the input file to read from.
    !! @param y         Array where the read values will be stored.
    subroutine load_input(filename, y)
        character(len=*), intent(in) :: filename
        real(dp), intent(out) :: y(:)
        integer :: i
        open(unit=11, file=filename, status='old')
        do i = 1, size(y)
            read(11,*) y(i)
        end do
        close(11)
    end subroutine load_input

end module io_mod
