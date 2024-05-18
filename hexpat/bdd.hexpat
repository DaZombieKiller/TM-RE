import std.time;

struct bdd_entry
{
    char name[20];
    char extension[8];
    u32 offset;
    u32 size;
    u64 time [[format("format_filetime")]];
};

fn format_filetime(u64 time)
{
    return std::time::format(std::time::to_utc(std::time::filetime_to_unix(time)));
};

bdd_entry entries[while($[$] != 0)] @ 0 [[inline]];
