!------------------------------------------------------------------------
!  grads_sfc
!
!       This subroutine reads the .tmp file and outputs the iscatter and
!       horizontal GrADS data files.
!------------------------------------------------------------------------

subroutine grads_sfc(fileo,ifileo,nobs,nreal,iscater,igrads,isubtype,subtype,list)

   use generic_list
   use data

   implicit none

   type(list_node_t), pointer   :: list
   type(list_node_t), pointer   :: next => null()
   type(data_ptr)               :: ptr
 
   integer ifileo, obs_ctr, nreal_m2, ctr
   real(4),allocatable,dimension(:,:)  :: rdiag_m2
   character(8),allocatable,dimension(:) :: cdiag
   character(8) :: stid
   character(ifileo) :: fileo
   character(30) :: files,filein,filegrads
   character(2) :: subtype
   integer nobs,nreal,nlfag,nflg0,nlev,nlev0,iscater,igrads
   real(4) rtim,xlat0,xlon0,rlat,rlon
 
   integer(4):: isubtype
   integer i,j,ii,ilat,ilon,ipres,itime,iweight,ndup

   rtim=0.0
   nflg0=0
   xlat0=0.0
   xlon0=0.0
   nlev0=0
   stid='        '

   print *, '--> BEGIN grads_sfc'  
   print *, 'nobs=',nobs
   print *, 'fileo=',fileo

!   write(subtype,'(i2)') isubtype
   filein=trim(fileo)//'_'//trim(subtype)//'.tmp'

   allocate(cdiag(nobs))
   nreal_m2 = nreal - 2
   allocate(rdiag_m2(nreal-2,nobs))        ! this will contain rdiag except for
                                           ! for the first 2 fields (type and subtype

   !---------------------------------------------
   ! Retrieve data from the linked list and load
   !   into the cdiag and rdiag arrays
   !
!   print *, 'Associated(list)   = ', associated( list )
   obs_ctr = 0
   next => list

   do while ( associated( next ) == .TRUE. )
      ptr = transfer(list_get( next ), ptr)
!      print *, 'node data:', ptr%p
      next => list_next( next )

      obs_ctr = obs_ctr + 1
      cdiag( obs_ctr ) = ptr%p%stn_id
      do i=3, nreal
         rdiag_m2(i-2, obs_ctr) = ptr%p%rdiag( i )
      end do
   end do

   print *, 'obs_ctr (list) = ', obs_ctr


!   open(11,file=filein,form='unformatted')
!   rewind(11)
!
!   do i=1,nobs
!      read(11) cdiag(i),rdiag(1:nreal,i)
!   enddo

   !-------------------------------
   !  write the scatter data file
   !
   print *, 'begin writing scatter data file'

   if(iscater ==1) then 
      files=trim(fileo)//'_'//trim(subtype)//'.scater'
      open(51,file=files,form='unformatted')

      write(51) nobs,nreal_m2
      write(51) rdiag_m2

      close(51)
   endif

   print *, 'end writing scatter data file'


   !-------------------------------
   !  write the horiz data file
   !
   if (igrads ==1 .AND. nobs > 0) then 
      filegrads=trim(fileo)//'_'//trim(subtype)//'_grads'

      open(21,file=filegrads,form='unformatted',status='new')    ! open output file

      ilat      = idx_obs_lat -2       ! modified position of lat
      ilon      = idx_obs_lon -2       ! modified position of lon
      ipres     = idx_pres -2          ! modified position of pressure
      itime     = idx_time -2          ! modified position of relative time
      iweight   = idx_rwgt -2          ! modified position of weight 

      !------------------------------
      !  rm any duplicate data
      !
      call rm_dups( rdiag_m2,nobs,nreal_m2,ilat,ilon,ipres,itime,iweight,ndup )

      ctr = 0
      ii=0
      do  i=1,nobs

         if(rdiag_m2(iweight,i) >0.0) then
            ii=ii+1
            stid=cdiag(i)
            rlat=rdiag_m2(ilat,i)
            rlon=rdiag_m2(ilon,i)
            write(21) stid,rlat,rlon,rtim,1,1

            !---------------------------------------------------------------
            ! note this writes the rdiag_m2 record starting at station
            ! elevation; lat and lon are written in the line above with
            ! the station id info
            write(21) rdiag_m2(3:nreal,i)

            ctr = ctr + 1

!            !  really not sure of this j=3,nreal write
!            write(21) (rdiag(j,i),j=3,nreal)
         endif
      enddo

      !------------------------------ 
      !  the end of file marker
      !
      stid='        '
      write(21) stid,xlat0,xlon0,rtim,nlev0,nflg0 
      
      print *, 'num recs written to GrADS file = ', ctr 
      close(21)
!      close(11)
   else
      write(6,*) "No output file generated, nobs, igrads = ", nobs, igrads
   endif

   deallocate(rdiag_m2,cdiag)

   print *, '<--- END grads_sfc'
   return 
end


  
