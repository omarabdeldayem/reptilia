SECTIONS
{
    .text 0x0000 : 
    {
        *(.text.init) _etext = . ;
    }
}