# My Shell
A base shell project programmed in Assembly x86-64 AT&T that works like a unix shell

## How To Use?
The string `myshell> ` will be print, the program will wait for the user to input the command and execute it

### Examples
- Write **ls** to list the files and print them
- Write **exit** to quit the shell

## Project Structure
- **Main loop**:  
  - Prints `myshell> ` at each iteration.  
  - Gets the command and checks if it is empty in the label `empty`, `cd`, or `exit` in the label `check_commands`.  
  - For other commands, a new process is created using `fork`.  

- **Child process**:  
  - Checks if the command can be executed directly, like executing a program or if it needs the `/bin/` path prefix.  
    - If we need to execute a program, we check if the file exists or have the permission and then we go to the label `execute`. And then copies the buffer in the label `copy_buffer`. 
    - If we need to the prefix `/bin/` for the command then we add it in the label strcat.
  - Constructs the argument array for the `execve` system call in the label `create_array`
  - Executes the command using `execve`, in the label `continue_child2` and returns to the main loop.  

- **Parent process**:  
  - Waits for the child process to finish.  
  - Cleans the buffer in `clean_buffer` for the next command.  


## Errors Handling

### Errors handled
  - **File or directory not found** - print the string `Error: No such file or directory`
  - **File can't be executed** - print the string `Error: Permission denied`
  - **Empty commands** - ignore it and wait for the next command
  - **System calls failures** - exit with 1 exit status

### Errors not handled
  - Not existing command
  - Pipe gestion
  - Command with a lot of spaces. For example: `cd      ..`
  - `clear` command don't work



