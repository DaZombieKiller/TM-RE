using System.Text;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;

unsafe
{
    if (args.Length < 1)
        goto Error;

    switch (args[0].ToUpperInvariant())
    {
    case "UNPACK":
        {
            if (args.Length < 3)
            {
                Console.WriteLine("bdd unpack input.bdd out_path");
                return;
            }

            // Convert paths to absolute
            args[1] = Path.GetFullPath(args[1]);
            args[2] = Path.GetFullPath(args[2]);

            // Read BDD file
            var buffer = File.ReadAllBytes(args[1]);

            // Ensure output directory exists.
            Directory.CreateDirectory(args[2]);

            for (int i = 0; i < buffer.Length && buffer[i] != 0; i += sizeof(BddEntry))
            {
                var entry = MemoryMarshal.Read<BddEntry>(buffer.AsSpan(i));
                var bytes = buffer.AsSpan(entry.Offset, entry.Length);

                // Construct the file name
                var name = Encoding.ASCII.GetString(TerminateSpan(entry.Name));
                var extension = Encoding.ASCII.GetString(TerminateSpan(entry.Extension));
                var output = Path.Combine(args[2], name + '.' + extension);

                // Save file
                File.WriteAllBytes(output, bytes.ToArray());
                File.SetCreationTimeUtc(output, DateTime.FromFileTimeUtc(entry.FileTime));
                File.SetLastWriteTimeUtc(output, DateTime.FromFileTimeUtc(entry.FileTime));
            }
            break;
        }
    case "PACK":
        {
            if (args.Length < 3)
            {
                Console.WriteLine("bdd pack output.bdd files...");
                return;
            }

            // Convert paths to absolute
            args[1] = Path.GetFullPath(args[1]);

            for (int i = 2; i < args.Length; i++)
                args[i] = Path.GetFullPath(args[i]);

            // Ensure output directory exists.
            if (Path.GetDirectoryName(args[1]) is { } directory)
                Directory.CreateDirectory(directory);

            var entries = new BddEntry[args.Length - 2];
            int position = AlignUp(sizeof(BddEntry) * entries.Length + 1, 0x10);

            for (int i = 0; i < entries.Length; i++)
            {
                var info = new FileInfo(args[i + 2]);
                Span<byte> name = Encoding.UTF8.GetBytes(Path.GetFileNameWithoutExtension(info.Name));
                Span<byte> extension = Encoding.UTF8.GetBytes(info.Extension ?? string.Empty);

                if (extension.StartsWith("."u8))
                    extension = extension[1..];

                // Truncate file name and extension if necessary
                name[..int.Min(name.Length, 19)].CopyTo(entries[i].Name);
                extension[..int.Min(extension.Length, 7)].CopyTo(entries[i].Extension);

                entries[i].Offset = position;
                entries[i].Length = (int)info.Length;
                entries[i].FileTime = info.LastWriteTimeUtc.ToFileTimeUtc();
                position = AlignUp(position + (int)info.Length, 0x10);
            }

            // Create output file
            var buffer = new byte[position];
            MemoryMarshal.AsBytes(entries.AsSpan()).CopyTo(buffer);

            for (int i = 0; i < entries.Length; i++)
            {
                var bytes = File.ReadAllBytes(args[i + 2]);
                bytes.CopyTo(buffer.AsSpan(entries[i].Offset, entries[i].Length));
            }

            // Write file
            File.WriteAllBytes(args[1], buffer);
            break;
        }
    default:
        goto Error;
    }

    return;
Error:
    Console.WriteLine("bdd <pack/unpack>");
}

static int AlignUp(int offset, int alignment)
{
    return (offset + (alignment - 1)) & ~(alignment - 1);
}

static ReadOnlySpan<byte> TerminateSpan(ReadOnlySpan<byte> span, byte terminator = 0)
{
    int length = span.IndexOf(terminator);
    return length >= 0 ? span[..length] : span;
}

[StructLayout(LayoutKind.Sequential, Pack = 4)]
public unsafe struct BddEntry
{
    public BddEntryName Name;
    public BddEntryExtension Extension;
    public int Offset;
    public int Length;
    public long FileTime;
}

[InlineArray(20)]
public struct BddEntryName
{
    public byte FirstByte;
}

[InlineArray(8)]
public struct BddEntryExtension
{
    public byte FirstByte;
}
