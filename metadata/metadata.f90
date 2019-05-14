      program bad_metadata
      implicit none
      include 'mpif.h'
      integer rank, size, ierror, tag, status(MPI_STATUS_SIZE)
      integer i,n
      real*8  start, finish
      character(len=1024) ffile,fil,bbpath   
      call MPI_INIT(ierror)
      call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierror)
      call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierror)
      write (ffile, "(A9,I1)") "metadata_", rank
!      call get_environment_variable("BBPATH", bbpath)
!      bbpath=trim(bbpath)
!      write (ffile, "(A,A9,I1)") bbpath,".metadata_", rank
      fil=trim(ffile)
      n=1000000
      start=MPI_Wtime()
      do i=1,n
        open(11,file=fil,position="append")
        write(11,*) 5
        close(11)
      end do
!      call MPI_Barrier(  MPI_COMM_WORLD, ierror)
      finish=MPI_Wtime()
      if (rank==0) THEN 
        write(6,'(A,f7.4)') 'Duration: ', finish - start
      end if
     call MPI_FINALIZE(ierror)

      end program bad_metadata
