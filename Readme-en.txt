################
## LZX Packer ##
################

 (c) Busy soft & hard
 http://busy.speccy.cz

 Version: 02d (15.09.2021)

 Licenses:
   LzxPack / LzxList ... GPLv3
   DecLzx02 ............ MIT

 LzxPack is a compression system allowing more powerful computers
 compress up to 64kB files especially for the some target 8-bit computer.

 It includes following parts:

  - Packer: LzxPack
  - Depacker / lister: LzxList
  - Decompression written in assembler for decompress file on target computer

 Typical use:

 Compress a file by LzxPack, then transfer compressed file to target computer
 where decompress the file using decompression routine.

 Compression system is based on LZ compression. It achieve compression by replacing repeated
 occurrences of data with references to a single copy of that data existing earlier
 in the uncompressed data stream.

 Example for illustrating the principle of LZ compression:

    Let the original file looks like this:

	abc12345678def12345678ghi

    Compressed file will look like this:

	abc12345678def<repetitive sequence length=8 offset=11>ghi

 After copying of letter 'f', decompressor copies 8 bytes from distance 11 bytes back (offset).
 If information about the length and offset of sequence needs (i.e.) 2 bytes, the final compressed
 length is reduced by 6 bytes since the original 8-byte sequence was replaced by 2-bytes of information.

 The system allows to use more different ways to encode information about length and offset
 and it always be able to choose the most effective way for compression.



%%%%%%%%%%%%%
%% LzxPack %%
%%%%%%%%%%%%%

 Universal LZX packer for files up to 64kB

  - Tries set of predefined compressions and selects the best one
  - For selecting the best compression, it is possible to include length of decompression routine
  - User allows to select some of the used compressions
  - Optional generating statistical information about tested compressions for comparison

 Use: LzxPack filename <options>

 Options:
  -s ............ Show statistics of all compressions used (default: do not show)
  -a ............ Save all compressed files (default: save only the best result)
  -i ............ Generate include file with compression type and parameters
  -o <file> ..... Set output file (default: input file + compression type + .lzx)
  -d <file> ..... File with depacker lengths to incorporate them into statistics
  -l <limit> .... Select maximum dictionary size (default: no limit for size)
  -e <number> ... Select additonal effort to improve compress ratio (default: 0)
  -tnXYcNoAoB ... Select desired compression (default: 'n' and trying all options)
  -trXYcNoAoB ... The 'r' instead of 'n' forces reverse direction of depacking

 All options are optional.
 Parameter of option can be closely to the option or separated by spaces.
 The only exception is option -t where selecting compression must follow immediatelly,
 without any spaces.


Option -s

 View statistics of all types of tested compressions in a summary table.
 Meaning of table columns:

   Compression ..... type of compression
   NumSek .......... number of sequences copied during decompression
   Packed .......... number of bytes in these copied sequences
   NoPck ........... number of uncompressed bytes what are not in any sequences
   Overhead ........ number of bytes needed to store sequence information (lengths and offsets)
   Packed length ... total length of output compressed file
   With depacker ... sum of length of file and length of decompression routine


Option -a

 In general, LzxPack tests all selected compressions and then uses the best one.
 But with the -a option, all compressions is really used and more output files
 will be saved => one output file for each compression. Set of used compressions
 can be specified by option -t (see below).


Option -i

 Generate include file "<filename>.inc" for depacker. The include file keeps all information
 about used compression needed for depacker. It is enough to include this file in source
 code of depacker and then depacker can depack the data compressed by used compression.
 More info below in part about depacker.


Option -o <file>

 Name of output file with packed data is normally generated from input file name
 by adding compresion identification -tnXYcNoAoB and extension lzx". If you use
 this option, the parameter <file> of this option will be used as output file name.
 Note ! If you use option -o together with -a, the compression identification will
 be added into selected output name anyway.


Option -d <file>

 Determine the best compression with including length of decompressing routine.
 To know length of decompressor, LzxPack needs read a special file containing
 definitions of these lengths. An example of this file is "spd0lens" included in archive.

 Example usage of this file: LzxPack -d spd0lens <file_to_packing>

 If you will write some new decompress routines for another platform, you can write length
 of this routine to a new text file, use this file with -d option and LzxPack will be able
 to select best compression for using on this platform.


Option -l <limit>

 Restriction of maximum size of dictionary for LZ compression.
 This option explicitly delimites maximal size of offsets used for copying sequences.
 It can be used in special cases when depacked data are written to some output stream
 what is not available for reading. In this case, depacker should write depacked data
 into special buffer. Size of this buffer must be at least the same as size
 of maximal offset used in compression.


Option -e <number>

 Select additonal effort to improve compress ratio.
 This option forces the packer to make more effort for searching best sequences.
 Default value is 0. Higher value causes bigger chance to save some next
 additional bytes in packed data but in this case compression takes more time.
 Usable values can be about up to 32. The maximal sensemaking value is half
 of total size of the input data.


Option -tnXYcNoAoB

 Selecting required compression or set of compressions:

   n ... direction of compress: n=forward (default), r=backward or reverse
   X ... compression type: 0=any 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
   Y .... offset encoding: 0=any 1=OF1 2=OF2 3=OF3 4=OF4       6=OV1 7=OV2 8=OV3 9=OV4
   N ... byte match offset bit-width used in BLX ZX9 BX1 BX2 BX3 SX1
   A .... 1st match offset bit-width used in OF1 OF2 OF3 OF4 OV2 OV3 OV4
   B .... 2nd match offset bit-width used in OF2 and OV3 only

 If any of these values are zero, it means LzxPack can try all sensemaking
 values for searching compression with the best compression ratio.

   Select compression X

     1 ... BLX ... Simple block compression with packing standalone (solo) bytes
     2 ... BLC ... Simple block compression with packing 2+ byte length sequences
     3 ... ZX9 ... Compression similar to known ZX7 with with packing standalone bytes
     4 ... ZX8 ... Compression similar to known ZX7 with better coding of 2+ byte sequences
     5 ... BS2 ... Compression optimized to short sequences and long blocks of unpackable data
     6 ... BX1 ... Sophisticated compres for solo bytes and reused offsets, good for short sequences
     7 ... BX2 ... Sophisticated compres for solo bytes and reused offsets, good compromise BX1 and BX3
     8 ... BX3 ... Sophisticated compres for solo bytes and reused offsets, optimized for solo bytes
     9 ... SX1 ... Special compression optimized for very sparse data (many sequences, a bit unpacked)

   Offset codings Y

     1 ... OF1 ... One offset of fixed bit width (A = bit width of offset)
     2 ... OF2 ... Two offsets of fixed bit width (A = width of the 1st, B = width of the 2nd offset)
     3 ... OF3 ... Three offsets of fixed bit width (A = bit width of the shortest offset)
     4 ... OF4 ... Four offsets of different bit width (A = bit width of the shortest offset)
     6 ... OV1 ... Variable bit width offset without any limitations (no need to enter A and B)
     7 ... OV2 ... One variable and one fixed width offset (A = bit width of the fixed offset)
     8 ... OV3 ... One variable and two fixed width offsets (A = width of 1st offset, B = 2nd)
     9 ... OV4 ... One variable and three fixed width offsets (A = bit width of shortest offset)

 If the "-o" is used and "-a" not, output file is explicitly given. In all other cases
 the output compressed file will have ".lzx" extension and his name will be extended
 by used compression specification in this form: "-tnXYcNoAoB" (the same as option -t).
 If the option -a is used, filenames will differ in this compression specification,
 even in case of "-o" option is used.


Tip for speed-up compression process

 Depends to data, the compression of data can take a longer time, even on powerful computers.
 When you have LzxPack included in some "makefile" and you do compilation very often,
 it can slow-down the process. In this case, you can speed up compression by this way:

 Try one time what compression is the best for your data by not using the option -t
 LzxPack finds the best compression for your data and shows what compression -t is used.
 Then add option for this compression -t... into LzxPack command line in your makefile.
 With this, LzxPack skips trying all compressions, forces using one selected compression only
 and whole packing process will be very quick.

 Sometimes, especially after bigger changes in your data and before final production, try
 LzxPack without option -t and check, if some another compression is better for your new data.


%%%%%%%%%%%%%
%% LzxList %%
%%%%%%%%%%%%%

 Universal lister and decompressor for files compressed by LzxPack

  - Automatically detects used type of compression due filename part  -tnXYcNoAoB
  - Displays of "Pack model" - a structure of compressed file and its brief statistic
  - Displays detailed statistic of packed data - number and lengths of sequences and unpacked blocks
  - Allows to specify multiple files at a time to decompress and displaying their pack model

 Usage: LzxList <options> file1 file2 file3 ...

 Options:
  -l ............ Output listing of packed files to stdout
  -s ............ Output detailed statistics of packed files to stdout
  -d ............ Depack and output files with extension .out (or set by -e)
  -u ............ Same as -d but with compression info -tXX.. removed from the filename
  -e <ext> ...... Set output file extension for depacked output (default extension: out)
  -o <file> ..... Set file name for depacked data (default: input file + extension .out)
  -tnXYcNoAoB ... Select compression manually (if no compression type -tXY.. in filename)
  -trXYcNoAoB ... The 'r' instead of 'n' forces reverse direction of depacking

 You can use wildcards in filenames to process more files at once.

 LzxList also checks the data integrity of compressed file, especially is the sequences
 will not be copied from area outside of valid data during decompression.



%%%%%%%%%%%%%%
%% DecLzx02 %%
%%%%%%%%%%%%%%

 Universal LZX decompression routine (depacker) for Z80.

 Source code of depacker can be used by these ways:

  1. Standalone self-sufficient source code for compiling
     It is enough to fill prepared definition at begin of source code by required values
     (addresses and compression parameters) and compilation of source code generates
     standalone self-sufficient code of depacker, callable e.i. by USR from basic.

  2. Included into biger project with all needed parameters
     assigned outside of depacker source code. This second way allows
     to use depacker source code as-is, without any modification.

 Before using this depacker, there is need to specify two sets of parameters:

  - User parameters
    These parameters must be set by user or program what includes the depacker.

        ORG  ... execute address or address where the depacker will work
      srcadd ... begin of source packed data
      dstadd ... begin of destination area for depacked data
      lzxspd ... selected optimalization for code (value 0) length or speed (value 1)

  - Pack parameters
    Values for these parameters are generated by compress program LzxPack.

    Parameters derived from selected or used compression -tnXYcNoAoB

      Label    Value   Meaning
      =====    =====   =======
      revers .. 0/1 .. Direction of compression: 0 = normal -tn.. / 1 = reversed -tr..
      typcom ... X ... Compres type: 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
      typpos ... Y ... Offset coding:  1=OF1 2=OF2 3=OF3 4=OF4 6=OV1 7=OV2 8=OV3 9=OV4
      bytcop ... N ... Bit width of offset for standalone bytes
      ofset1 ... A ... Bit width of 1st offset for sequences
      ofset2 ... B ... Bit width of 2nd offset for sequences

    Additional parameters used for information or data overlay check

      mindst ... minimal distance between source packed data and destination area for unpacked data
      maxdct ... maximal dictionary length selected by -l option in LzxPack
      deplen ... length of depacker (only for info, not used in depacker)
      pcklen ... length of packed data
      totlen ... length of unpacked data

    Parameter "mindst" (minimal distance) is value, how many bytes must be
    between end of area for destination unpacked data and end of source packed data.
    This is prevention of rewriting source packed data before by unpacked data before using.
    This is data overlay check - if there is a threat to damage data, compilation of depacker fails.


Setting of user parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~
 There are two posibilities how the user parameter can be set:

  1. Direct editing of source code DecLzx02.asm and fill all needed values manually

  2. Including source code into bigger project where all user parameters are defined
     In this case, these is needed to comment out definition of these parameters
     in depacker source code, or define symbol "declzx_user_params" in bigger project:

       srcadd  =  ...
       dstadd  =  ...
       lzxspd  =  0 or 1
         DEFINE  declzx_user_params
         INCLUDE DecLzx02.asm

     Depacker contains setting of HL and DE registers to addresses "srcadd" and "dstadd".
     In case of calling the depacker with HL and DE already set in calling program
     (e.g. whole program is optimized for length), it is enough to comment out setting
     of addresses in depacker, or to define symbol "declzx_init_addres":

         ld      hl,srcadd
         ld      de,dstadd
         DEFINE  declzx_init_addres
         INCLUDE DecLzx02.asm

     Note: For reversed decompresson (revers = 1) it is needed to set the registres HL and DE
     to last byte of packed data and last byte of area for depacked data.


Setting of pack parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~
 There are three posibilities how the user parameter can be set:

  1. Direct editing of source code DecLzx02.asm and fill all needed values manually

  2. Use include file with pack parameters generated by LzxPack with option -i.
     In this case, it is need to remove comment - delete semicolons in these
     two lines in depacker source code and fill proper name of include file:

         ;   INCLUDE  filename.inc
         ;   DEFINE   declzx_pack_params

  3. Including both depacker source code and include file into bigger project
     allows not needed to modify depacker source code itself. Definition
     of symbol "declzx_pack_params" forces reading parameters from include file.

         DEFINE  declzx_pack_params
         INCLUDE <incfile>.inc
         INCLUDE DecLzx02.asm


Code length and speed optimization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 There two versions of depacker can be generated: optimize for code length and for speed.
 Setting of user parameter "lzxspd" determines what version of depacker will be generated:

   lzxspd = 0 ... optimized for minimal code length, but slower depacking
   lzxspd = 1 ... optimized for maximal speed, but longer code


Best compression ratio with included depacker length
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 LzxPack can automatically select compression with the best compression ratio,
 where length of depacker can be included into this ratio. To reach this goal,
 LzxPack needs to know how long the depacker is.

 Length of depacker depends to these parameters:

  - selected compression (typcom)
  - offset coding (typpos)
  - direction setting (revers)
  - optimization setting (lzxspd)

 For the depacked "DecLzx02.asm", there are two additional files in the package:

   spd0lens ... lengths of depacker optimized for code length (setting  lzxspd = 0)
   spd1lens ... lengths of depacker optimized for speed       (setting  lzxspd = 1)

 One of these files can be used in -d option of LzxPack:

   LzxPack -d spd0lens <input_file>

 In this case, LzxPack will use compression what gives the shortest sum
 of packed data and depacker length, where depacker is optimized for code length.


Include file
~~~~~~~~~~~~
 The include file keeps label definitions about used compression needed for depacker
 and some next definition what can be usable in general. It can be used to specify
 used compression for depacker.

 This file is generated by LzxPack with using option -i.

 Label definitions about used compression -tnXYcNoAoB

      revers = 0/1  Direction of compression: 0 = normal -tn.. / 1 = reversed -tr..
      typcom = X    Compres type: 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
      typpos = Y    Offset coding:  1=OF1 2=OF2 3=OF3 4=OF4 6=OV1 7=OV2 8=OV3 9=OV4
      bytcop = N    Bit width of offset for standalone bytes
      ofset1 = A    Bit width of 1st offset for sequences
      ofset2 = B    Bit width of 2nd offset for sequences

 Next useful definitions

      mindst = ?    minimal distance between source packed data and destination area for unpacked data
      maxdct = ?    maximal dictionary length selected by -l option in LzxPack
      deplen = ?    length of depacker (only for info, not used in depacker)
      pcklen = ?    length of packed data
      totlen = ?    length of unpacked data

 Length of depacker is taken from file "spd*lens" specified in option -d.
 In case if -d is not used, deplen is defined to zero by default.



%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compression formats %%
%%%%%%%%%%%%%%%%%%%%%%%%%

 This part describes structure of packed data.
 

Common format of compressed file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  BLX and BLC:         <block> <block> <block> ... <block> <end_mark>
   All others:  <byte> <block> <block> <block> ... <block> <end_mark>

  All others (ZX9 ZX8 BS2 BX1 BX2 BX3 SX1) begins with one unpacked data byte allways.

  Each <block> can contain uncompressed data or copying sequence.

    Uncompressed Data:  <id> <data..>
    Copying sequence:   <id> <offset>
    Copying one byte:   <id>

  <id> is identification of block and its format depends on type of compression (typcom).
       This identification includes the number of bytes of uncompressed data,
       length of sequence and offset for packing standalone byte (bytcop) if needed.

  <offset> means on how many bytes will be returned to the tial able to copy sequence.
           Format depends on offset coding (typpos,ofset1,ofset2)

           Note: Offset for copying one standalone byte is part of relevant <Id>.
           If the <id> means copying this byte, the <offset> is not used in this case.

  <end_mark> determines end of packed data. Depacker stops activity when <end_mark> occured.
             Internally it is some <id> what keeps length above 65535, what causes overflow
             in 16 bit and depacker knows that no valid data follows.

  The <id> <offset> <end_mark> allways are stored in bitstream, a separate stream of bytes
  of data what are reading bit-by-bit, always how many bits are currently needed.

  The uncompressed data <data ..> is not part of the bitstream, it is stored in the next bytes.



Format <id>
~~~~~~~~~~~

BLX - Simple block compression with packing standalone bytes

  <length> 1 ............ uncompressed data
  <length> 0 ............ length > 1 ... sequence 2+ bytes long
  <length> 0 <offset> ... length = 1 ... standalone byte

  Standalone byte is special case of sequence with 1 byte long.
  It does not use standart offset (see offset coding below)
  but own small offset what is part of the <id> format item.
  Bit width of <offset> is allway parameter "bytcop".


BLC - Simple block compression with packing 2+ byte length sequences

  1 <length> ...... uncompressed data
  0 <length+1b> ... sequence 2+ bytes length (length>= 2)

  BLC is very simple compression, and in conjunction with Elias-Gamma offset coding
  allows to reach very short decompression routine with good compression ratio.


ZX9 - Compression similar to known ZX7 with with packing standalone bytes

  1 ..................... one uncompressed byte
  0 <length> ............ length > 1 ... sequence 2+ bytes long
  0 <length> <offset> ... length = 1 ... standalone byte


ZX8 - Compression similar to known ZX7 with better coding of 2+ byte sequences

  1 ............... one uncompressed byte
  0 <length+1b> ... sequence 2+ bytes long (length >= 2)

  In ZX8 and ZX9 compressions, the <Block> with uncompressed content can keep only one byte,
  so there is needed separate <block> for each byte of uncompressed data. It means that all
  bytes from source file, what are not compressed in sequences, takes 9 bits in compressed file.

  This ZX8 is very similar to known compress program ZX7 but there is a littke difference
  in <length> encoding - ZX7 uses normal Elias-Gamma and then length increments by 1.


BS2 - Compression optimized to short sequences and long blocks of unpackable data

  1 .......................... one uncompressed byte
  01 ......................... 2 bytes long sequence
  001 ........................ 3 bytes long sequence
  0001 <length+2b> ........... 4+ bytes long sequence
  00001 <BYTE> <length+1b> ... one uncompressed byte and sequence with reused offset
  00000 <length+3b> .......... 10+ bytes of uncompressed data

  The combination 00001 covers one BYTE what is directly copied from input to output data
  and then a compressed sequence follows. Offset used for copying sequence is not taken from
  following <offset> structure, but the previous used offset is applied for this sequence again.

  Uncopressed data up to 9 bytes are stored by the same way as ZX8 and ZX9 compressions,
  one bit 1 for each byte. To keep large uncompressed block smaller, there is combination
  00000 what allows to store 10 and more uncompressed bytes with smaller overhead and
  keep better compression ratio by this way.

  These advantages - reused offset for sequences and block of more uncompressed bytes are
  included in all following compressions BX1 BX2 BX3 SX1.


BX1 - Sophisticated compres for solo bytes and reused offsets, good for short sequences

  1 .............................. one uncompressed byte
  01 ............................. 2 bytes long sequence
  001 ............................ 3 bytes long sequence
  0001 <offset> .................. one standalone byte
  00001 <length+2b> .............. 4+ bytes long sequence
  000001 <BYTE> <length+1b> ...... one uncompressed byte and sequence with reused offset
  0000001 <offset> <length+1b> ... one   standalone byte and sequence with reused offset
  0000000 <length+3b> ............ 12+ bytes of uncompressed data


BX2 - Sophisticated compres for solo bytes and reused offsets, good compromise BX1 and BX3

  1 .............................. one uncompressed byte
  01 ............................. 2 bytes long sequence
  001 <offset> ................... one standalone byte
  0001 ........................... 3 bytes long sequence
  00001 <length+2b> .............. 4+ bytes long sequence
  000001 <BYTE> <length+1b> ...... one uncompressed byte and sequence with reused offset
  0000001 <offset> <length+1b> ... one   standalone byte and sequence with reused offset
  0000000 <length+3b> ............ 12+ bytes of uncompressed data


BX3 - Sophisticated compres for solo bytes and reused offsets, optimized for solo bytes

  1 .............................. one uncompressed byte
  01 <offset> .................... one standalone byte
  001 ............................ 2 bytes long sequence
  0001 ........................... 3 bytes long sequence
  00001 <length+2b> .............. 4+ bytes long sequence
  000001 <BYTE> <length+1b> ...... one uncompressed byte and sequence with reused offset
  0000001 <offset> <length+1b> ... one   standalone byte and sequence with reused offset
  0000000 <length+3b> ............ 12+ bytes of uncompressed data

  Compressions BX1 BX2 BX3 are similar, the only difference
  is position of standalone byte towards 2 and 3 byte sequences.


SX1 - Special compression optimized for very sparse data (many sequences, a bit unpacked)

  1 <length+1b> ................ 2+ bytes long sequence
  01 ........................... one uncompressed byte
  001 <offset> ................. one standalone byte
  0001 <BYTE> <length+1b> ...... one uncompressed byte and sequence with reused offset
  00001 <offset> <length+1b> ... one   standalone byte and sequence with reused offset
  00000 <length+2b> ............ 5+ bytes of uncompressed data


  In all compressions, the <length> is allways coding in standart Elias-Gamma coding:

    <N zeroes> 1 <N bits of value>

  It means: First of all, there are N zero bits. Then bit 1 follows, and after this bit 1,
  the N bits of value follows. Target value is bit 1 with N bits of value. Some examples:

  Value   Bits
  =====   ====
    1 .... 1
    2 .... 010
    3 .... 011
    4 .... 00100
    5 .... 00101
    6 .... 00110

  The <length+Xb) means slightly modified Elias-Gamma coding,
  where additional X bits follows after value bits:

    <N zeroes> 1 <N+X bits of value>

  So whole targed value is created by  bit 1 + N bits + X bits.
  Some examples for X=2 (two additinal bits):

  Value   Bits
  =====   ====
    4 .... 100
    5 .... 101
    6 .... 110
    7 .... 111
    8 .... 01000
    9 .... 01001

  This modified Elias-Gamma is used if an value 2^X and more is needed to encode.
  For example: Item "4+ bytes sequence long" needs to encode length from value 4 only.
  The idea is the value has X and more bits, it is enough number of leading zero bits smaller by X.


Format <offset>
~~~~~~~~~~~~~~~

OF1 - One offset with fixed bit width

  <A bits> ... A bits value decremented by 1. The number A is equal to the parameter "ofset1".

  Encoded value is incremented and then used as offset in range 1 .. 2^A.
  Offset above 2^A are not possible, sequences with bigger offset can not be stored.


OF2 - Two different offsets, both with fixed bit width

  1 <A bits> .... shorter offset with fixed width A bits. A is equal to parameter "ofset1"
  0 <B bits> ....  longer offset with fixed width B bits. B is equal to parameter "ofset2"

  Ranges of offsets                    Example for A=3, B=5:
  Shorter offset:      1 .. 2^A              1 .. 8
  Longer  offset:  2^A+1 .. 2^A+2^B          9 .. 40


OF3 - Three offsets with uniformly scaled bit width

  0 <A> ....... short offset with 'A' bits width
  10 <2*A> ... middle offset with 2*A bits width
  11 <3*A> ..... long offset with 3*A bits width

  A is equal to paramter "ofset1".

  Ranges of offsets                                 Example for A=2
   Short offset:              1 .. 2^A                   1 .. 4
  Middle offset:          2^A+1 .. 2^A+2^(2*A)           5 .. 20
    Long offset:  2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)  21 .. 84


OF4 - Four offsets with uniformly scaled bit width

  00 <A> ..... shortest offset with 'A' bits width
  01 <2*A> ... shorter  offset with 2*A bits width
  10 <3*A> ... longer   offset with 3*A bits width
  11 <4*A> ... longest  offset with 4*A bits width

  A is equal to paramter "ofset1".
  Example for A=2:

  Ranges of offsets                                                     Example for A=2
   Shortest offset:                      1 .. 2^A                           1 .. 4
    Shorder offset:                  2^A+1 .. 2^A+2^(2*A)                   5 .. 20
     Longer offset:          2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)          21 .. 84
    Longest offset:  2^A+2^(2*A)+2^(3*A)+1 .. 2^A+2^(2*A)+2^(3*A)+2^(4*A)  85 .. 340


OV1 - One offset with variable bit width

  <value> ... offset value in Elias-Gamma coding

  It enables storing of any offset, with emphasis on effectively
  storing of more frequently occurring of small offsets.
  No parameters "ofset1" not "ofset2" is needed to speficy bit width of offset.
  Range of offset: 1 .. 65535


OV2 - One variable and one fixed width offset

  0 <A bits> ........ smaller offset with fixed width A bits
  1 <value-Abits> ... longer offset encoded as modified Elias-gamma with A additional bits

  A is equal to parameter "ofset1".
  Since longer offset has A or more bits allways, it is enough to use
  modified Eliash-gamma encoding with number of leading zero bits decreased by A:

     <N zeroes> 1 <N+A bits of value>

  Ranges of offsets:                   Example for A=4
  Shorter offset:      1 .. 2^A              1 .. 16
  Longer  offset:  2^A+1 .. 65535           17 .. 65535


OV3 - One variable and two fixed width offsets

  0 <A bits> .......... short offset with fixed width A bits. A is equal to parameter "ofset1"
  10 <B bits>......... middle offset with fixed width B bits. B is equal to parameter "ofset2"
  11 <value-Bbits> ..... long offset encoded as modified Elias-gamma with B additional bits

  Since long offset has B or more bits allways, it is enough to use
  modified Eliash-gamma encoding with number of leading zero bits decreased by B:

     <N zeroes> 1 <N+B bits of value>

  Ranges of offsets:                       Example for A=3 B=5
   Short offset:          1 .. 2^A              1 .. 8
  Middle offset:      2^A+1 .. 2^A+2^B          9 .. 40
    Long offset:  2^A+2^B+1 .. 65535           41 .. 65535


OV4 - One variable and three fixed width offsets with uniformly scaled bit width

  00 <A> ............... shortest offset with 'A' bits width
  01 <2*A> ............. longer offset   with 2*A bits width
  10 <3*A> ............. even longer     with 3*A bits width
  11 <value-3*Abits> ... longest offset encoded as modified Elias-gamma with 3*A additional bits

  A is equal to paramter "ofset1".

  Ranges of offsets                                             Example for A=2
   Shortest offset:                      1 .. 2^A                    1 .. 4
    Shorder offset:                  2^A+1 .. 2^A+2^(2*A)            5 .. 20
     Longer offset:          2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)   21 .. 84
    Longest offset:  2^A+2^(2*A)+2^(3*A)+1 .. 65535                 85 .. 65535


%%%%%%%%%%%%%
%% History %%
%%%%%%%%%%%%%

Version 01
~~~~~~~~~~~
 - Release 07.02.2017
 - First official version
 - Compress types: LZM LZE ZX7 BLK BS1
 - Offset coding types: OF1 OF2 OF4 OFD
 - Selecting the best compress automatically
 - Saving output from all used compressions:  -a
 - Show statistics of all used compressions:  -s
 - Assuming depacker length into compress ration:  -d <file>
 - Depacker optimized for code length or speed

Version 02a
~~~~~~~~~~~
 - Release 26.01.2021
 - Removing compressions LZM a LZE
 - Offset coding OFD renamed to OV1
 - Added new offset codings: OF3 OV2 OV3 OV4
 - Totally new and more powerful compressions
 - Support both types of option syntax:  -d<file> and -d <file>
 - Possibility of (de)packing in reverse order - from end of file:  -tr...
 - Possibility of specification explicit filename of output file: -o <name>
 - Possibility of setting maximal limit for offsets (dictionary size): -l
 - Possibility of generating include file with all params of compression: -i
 - Possibility of adding additional effort to improve compress ratio: -e <number>
 - Evaluate of minimal distance between packed and unpacked area to prevent damage
 - Displaying of statistics of packed data (numbers and length of sequences and blocks)

Version 02b
~~~~~~~~~~~
 - Release 01.02.2021
 - Language correction of help in command line

Version 02c
~~~~~~~~~~~
 - Release 30.08.2021
 - LzxList: Correction of statistics of unpacked blocks
 - LzxPack: Added "deplen" length of depacked into include file

Version 02d
~~~~~~~~~~~
 - Release 15.09.2021
 - Included depacker DecLzx02 for 8080 and 6502 (was for Z80 only)
 - New parameter "declzx_init_addres" in DecLzx02 for skipping settings HL and DE at begin


%%%%%%%%%%%
%% Thanx %%
%%%%%%%%%%%

 Big THANKS for the inspiration and help goes to:

 - RM-TEAM for its compression utility QUIDO
 - Einar Saukas for his compress program ZX7
 - Emmanuel Marty for his compress program Apultra
 - Ped7g + baze + mborik + Loki for tips, ideas and corrections
 - Loki for depacker DecLzx02 pre 6502
 