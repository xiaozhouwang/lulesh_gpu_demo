PROJECT = lulesh.out
NVCC		= nvcc #/cm/shared/apps/cuda90/toolkit/9.0.176/bin/nvcc
FLAGS		= -arch=sm_35
DFLAGS	= -G -g -lineinfo
RFLAGS 	= -O3 -DNDEBUG 

MPI_INCLUDES := /cm/shared/apps/mvapich2/gcc/64/2.3b/include #/usr/lib/openmpi/include
MPI_LIBS := /cm/shared/apps/mvapich2/gcc/64/2.3b/lib #/usr/lib/openmpi/lib

#SILO_INCLUDES := /usr/local/silo-4.8/include
#SILO_LIBS := /usr/local/silo-4.8/lib

LINKFLAGS =  -L$(MPI_LIBS) -lmpi 
#LINKFLAGS += -L$(SILO_LIBS) -lsilo

INC_MPI:= -I$(MPI_INCLUDES)
#INC_SILO:= -I$(SILO_INCLUDES)

all: release 

debug: LINKFLAGS += -G -g

release: 	FLAGS += $(RFLAGS)
debug: 		FLAGS += $(DFLAGS)

release: $(PROJECT)
debug: $(PROJECT)

$(PROJECT): allocator.o lulesh.o
	$(NVCC) $(LINKFLAGS) allocator.o lulesh.o -o $@ 

allocator.o: allocator.cu vector.h
	$(NVCC) $(FLAGS) allocator.cu -I ./ $(INC_MPI) -c -o allocator.o

lulesh.o: lulesh.cu util.h vector.h texture_objAPI.h allocator.h
	$(NVCC) $(FLAGS) lulesh.cu -I ./ $(INC_MPI) $(INC_SILO) -c -o lulesh.o

clean: 
	rm -rf allocator.o  lulesh.o $(PROJECT)
