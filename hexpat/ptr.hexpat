import std.mem;

struct improved_reloc
{
    // 4 * step[i]
    u16 step[while(std::mem::read_unsigned($, 2, std::mem::Endian::Little) != 0)];
    u16;
    
    // 4 * step_next
    u32 step_next;
    padding[6];

    if (step_next == 0)
    {
        break;
    }
};

struct obsolete_reloc
{
    u32 count;
    u32 offsets[count];
};

struct ptr_header
{
    u32 magic;
    
    if (magic == 0xFFFFFFFF)
        improved_reloc relocs[];
    else
        obsolete_reloc relocs;
};

ptr_header header @ 0 [[inline]];
