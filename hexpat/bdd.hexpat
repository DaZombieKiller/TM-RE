import type.time;

struct bdd_entry
{
    char name[20];
    char extension[8];
    u32 offset;
    u32 size;
    type::FILETIME time;
};

bdd_entry entries[while($[$] != 0)] @ 0 [[inline]];
