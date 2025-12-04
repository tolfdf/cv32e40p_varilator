
int glitch()
{
    asm(
            "li x18, 18\n"
            "li x19, 19\n"
            "li x20, 20\n"
            "li x21, 21\n"
       );

    asm(
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
       );

    asm(
            "add x18, x18, 1\n"
            "add x19, x19, 1\n"
            "add x20, x20, 1\n"
            "add x21, x21, 1\n"
       );


    asm(
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
            "ADDI x0, x0, 0\n"
       ); 

    volatile int* exit = 0x20000004;
    *exit = 0;

    return *exit;
}

int main()
{
    return glitch();
}
