all: a4

a4: 
	ghc --make Assign4.hs

clean: 
	rm -f Assign4.hi Assign4.o
