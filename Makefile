all: a5

a5: 
	ghc --make Assign5.hs

clean: 
	rm -f Assign5.hi Assign5.o
