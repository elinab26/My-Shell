.section .data
    env: .quad 0
    error: .string "Error: No such file or directory\n"
    err_exec: .string "Error: Permission denied\n"
    shell: .string "myshell> "
    shellLen= .-shell
    path: .string "/bin/"

.section .bss
    buffer: .space 1024
    buffercopy: .space 1024

.section .text
.globl main
.type	main, @function 
main:
    # Enter
    pushq %rbp
    movq %rsp, %rbp  
    
 loop:  
    #print myshell>
    movq $1, %rax
    movq $1, %rdi
    movq $shell, %rsi
    movq $9, %rdx
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error

    #read command
    xorq %rax, %rax
    movq $0, %rdi
    movq $buffer, %rsi
    movq $1024, %rdx
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error

    #change \n by \0
    leaq buffer(%rax), %r13
    decq %r13
    movb $0, (%r13)
    
    #check if the command is empty
    movq $buffer, %rsi
    jmp empty

check_commands:
    #check if the command is the exit command
    movq $buffer, %rsi
    cmpb $'e', (%rsi)
    jne check_cd
    incq %rsi
    cmpb $'x', (%rsi)
    jne continue_loop
    incq %rsi
    cmpb $'i', (%rsi)
    jne continue_loop
    incq %rsi
    cmpb $'t', (%rsi)
    jne continue_loop
    incq %rsi
    cmpb $0, (%rsi)
    je exit

check_cd:
    #check if the command is the cd command
    movq $buffer, %rsi
    cmpb $'c', (%rsi)
    jne continue_loop
    incq %rsi
    cmpb $'d', (%rsi)
    jne continue_loop
    incq %rsi
    cmpb $32, (%rsi)
    je cd
 
continue_loop:
    #fork syscall
    xorq %rax, %rax
    movq $57, %rax
    syscall

    #check if pid==0
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error
    je child_process

parent_process:
    #wait syscall
    movq %rax, %rdi  #save pid in rdi
    xorq %rax, %rax
    movq $61, %rax
    xorq %rsi, %rsi
    xorq %rdx, %rdx
    xorq %r10, %r10
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error

    #clean the buffer for the next command
    movq $buffer, %r9
    movq $1024, %r10
    jmp clean_buffer

child_process:

    #add the /bin/ path to the command
    movq $path, %rdi
    movq $buffer, %rsi
    #check if the command is an execution of an executable file
    movq $buffer, %r13
    cmpb $'.', (%r13)
    jne strcat
    incq %r13
    cmpb $'/', (%r13)
    jne strcat
    incq %r13
    

    #access syscall to check if the file exists
    movq %r13, %rdi
    movq $0, %rsi
    movq $21, %rax
    syscall
    cmpq $0, %rax
    jne file_error

    #access syscall to check if the file have executions permissions
    movq %r13, %rdi
    movq $1, %rsi
    movq $21, %rax
    syscall
    cmpq $0, %rax
    jne exec_error

    jmp execute
continue_child1:
    movb $0, (%r14)     #add \0 to the end of the concatenated string
    
    #create the array to pass to the execve system call
    movq $path, %r15
    movq %rdi, %rbx
    xorq %r14, %r14
    jmp create_array

continue_child2:
    #execve syscall
    movq %r12, %rsi
    movq %r15, %rdi
    movq $0, %rdx
    movq $59, %rax
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error
    
execute:
    #copy the buffer
    movq $buffer, %r15
    movq $buffercopy, %r14
    jmp copy_buffer

execute1:
    #create the array for the executable file to pass to the execve system call
    movq $buffer, %r15
    movq $buffercopy, %rbx
    movq $buffercopy, %rdi    
    xorq %r14, %r14
    jmp create_array

copy_buffer:
    #copy buffer loop
    cmpb $0, (%r15)
    je execute1
    movb (%r15), %r8b
    movb %r8b, (%r14)
    incq %r14
    incq %r15
    jmp copy_buffer

create_array:
    #rbx = buffer
    #r14 = counter words
count_words:
    #count how many words there is in the command
    cmpb $0, (%rbx)
    je alloc
    cmpb $32, (%rbx)
    je plus
    incq %rbx

plus:
    incq %r14
    incq %rbx
    jmp count_words

alloc:
    #allocate memory in stack
    incq %r14
    imulq $8, %r14
    subq %r14, %rsp

    movq %rsp, %r12
    movq %rdi, %rbx
    xorq %r13, %r13

Aloop:
    cmpb $0, (%rbx)
    je done

    cmpb $32, (%rbx)
    je space

    movq %rbx, (%r12, %r13, 8)
    incq %r13

A2loop:
    cmpb $0, (%rbx)
    je done
    cmpb $32, (%rbx)
    je endarg
    incq %rbx
    jmp A2loop

endarg:
    #change the space by \0
    movb $0,(%rbx)
    incq %rbx
    jmp Aloop

space:
    incq %rbx
    jmp Aloop

done:
    movq $0, (%r12, %r13, 8)
    jmp continue_child2

cd:
    #cd command
    incq %rsi
    movq %rsi, %rdi
    mov $80, %rax               # Syscall chdir = 80
    syscall  
    #check if the file or directory exists
    cmpq $0, %rax
    jne file_error
    
    jmp loop

file_error:
    movq $1, %rax
    movq $2, %rdi
    movq $error, %rsi
    movq $33, %rdx
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error
    jmp loop

exec_error:
    movq $1, %rax
    movq $2, %rdi
    movq $err_exec, %rsi
    movq $25, %rdx
    syscall
    cmpq $0, %rax   #check if the syscall is done successfully
    jl sys_error
    jmp loop

strcat:
    #concatenate strings
    xorq %r14, %r14
    leaq 5(%rdi), %r14
    looop:
        cmpb $0, (%rsi)
        je continue_child1
        movb (%rsi), %r8b
        movb %r8b, (%r14)
        incq %rsi
        incq %r14
        jmp looop

empty:
    #check if the command have only spaces or \0
    cmpb $0, (%rsi)
    je loop
    cmpb $32, (%rsi)
    jne check_commands
    incq %rsi
    jmp empty

clean_buffer:
    #put \0 in all the buffer to clean it
    cmpq $0, %r10
    je loop
    movb (%r9), %r8b
    movb $0, %r8b
    movb %r8b, (%r9)
    incq %r9
    decq %r10
    jmp clean_buffer

sys_error:
    movq $60, %rax      
    movq $1, %rdi       # exit status
    syscall  

exit:
    movq $60, %rax      
    movq $0, %rdi       # exit status
    syscall            
    

