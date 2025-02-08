#Executable name
EXEC = myshell

# name of the code
SRC = myshell.s

# compiler
CC = gcc

all: $(EXEC)

# compile
$(EXEC): $(SRC)
	$(CC)  $(SRC) -o $(EXEC)

#clean
clean:
	rm -f myshell.o $(EXEC)

.PHONY: all clean
