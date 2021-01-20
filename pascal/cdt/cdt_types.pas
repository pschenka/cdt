{  ***  ConstantDatabaseTable - structure  ***

cdt-file structure and idea
BSD-2 licence:  Copyright (c) 2020, frantisek novotny

pascal version
BSD-3 licence:  Copyright (c) 2020, petr schenka }


unit cdt_types;

{$mode delphi}

interface

{  File / memory map:
 ===================== descripts
 head: id, blocks #, cols #, lines#
 ---------------------
 blocks list
   block1: type, flags, seek
   block2: type, flags, seek
   ...
 ---------------------
 columns description
   column1: name, type, width
   column2: name, type, witdh
   ...
 ---------------------
 user: data user identification
 ===================== database
 main: lines x sum_widths
 ---------------------
 text1: variable length texts from some table columns
 ---------------------
 search1: lower+un_latin2 copy of text1 for fast search
 ---------------------
 sort1: index for halfening find
 ---------------------
 ...
}

const
  cdtSign = $5344;          // main file id 'DT'
    // blocks types
  cdbtCols = $18;           // block of columns descript
  cdbtUser = $00;           // user id block
  cdbtMain = $20;           // main data table = rows x rlen
  cdbtMemo = $28;           // extra saved var-memo, 1st byte lenght
  cdbtText = $30;           // extra saved var-texts, 1st byte length
  cdbtSrch = $38;           // search copy of cdbtText lowerAscii, #0 delim
  cdbtSort = $80;           // index .. log(rows) x rows
                            // low 3bits # joined-columns
  cdbtSor1 = $88;           // index - unique
                            // low 3bits # joined-columns -1
  cdbtSDum = $90;           // flag-only column is pre-sorted
  cdbtSDu1 = $98;           // same for Sor1
  cdbtList = $e0;           // shortcut to index with grouped values
                            // low 3bits # chars -1  (0..whole col)
// cdbtSrAB = $f0;          // shortcut to dsbSrch
    // cell justify + types
  cdcjMask = $70;           // mask of justify
  cdcjLeft = $00;           // left
  cdcjRigh = $10;           // right
  cdcjZero = $20;           // leading zeros + right
  cdcj1dec = $40;           // 1 dec place fixed
  cdcj2dec = $50;           // 2 dec places fixed
  cdcj3dec = $60;           // 3 dec places fixed
  cdcj4dec = $70;           // 4 dec places fixed
  cdec_dcj = 'LeftRightZero----1dec2dec3dec4dec';
  cdctMask = 15;            // mask of cell types
  cdctChar =  0;            // normal text, ascii or latin = 1B coded
  cdctBin  =  1;            // binary, Intel-like = LSB..MSB
  cdctY40  =  2;            // caps alfa-num + _-.?
  cdctSBcd =  3;            // binary coded decimal with signes
                            // $0:- $1:. $2:_ $3:0 .. $C:9 $D:/ $E:a $F:b
  cdctUNum =  5;            // numeric output unsigned - endian MSB..LSB
                            // max_uint ... undefined
  cdctSNum =  6;            // numeric output signed - endian MSB..LSB
                            // -max_int ... undefined
  cdctReal =  7;            // float 4, 6, 8, 10 byte
  cdctDate =  8;            // DOS-date allways 2byte
                      // v--   next 3 types are binary on output !
  cdctUInt =  9;            // unsigned - endian MSB..LSB
                            // max_uint ... undefined
  cdctSInt = 10;            // signed - endian MSB..LSB
                            // -max_int ... undefined
  cdctFlt  = 11;            // float 4, 6, 8, 10 byte
  cdctText = 12;            // reference (address) to var-width text of cell
  cdctMemo = 13;            // reference (address) to var-width bin of cell
  cdec_dct = 'CharBin Y40 Bcd----UNumSNumRealDateUIntSIntFlt TextMemo--------';


type
  arr80 = array[0..79] of byte;
    // file structure
  CdtHead = packed record   // main file header
    sgn:  word;             // cdtSign
    sub:  word;             // subversion cdt - clone, version
    dver: word;             // data version, f-ex: date
    dsub: word;             // data subversion
    nblk: word;             // blocks count
    ncol: word;             // columns count
    nrow: longint;          // lines count
  end;
  CdtBlock = packed record  // one block descript
    typ:  byte;             // type, see dbtXxx
    flg:  byte;             // flags
    col:  word;             // touched column#
    beg:  longint;          // seek from bof
    crc:  longint;          // crc
  end;
  CdtCol = packed record    // one column descript
    name: longword;         // name 2x3 alfanum - Y40 coded
    typ:  byte;             // type, see dcjXxx + dctXxx
    len:  byte;             // length in main-table (pack or seek length)
    pak:  byte;             // #un-pack function, pak-1 pack function
                            // or #block for cdctText
    max:  byte;             // max length of unpack data
  end;
  CdtUser = packed record   // data about user
    cnt:  word;             // sign count x3001
    day:  word;             // Dos-date of last sign
    typ:  longint;          // IC or typ shl 24
    key:  longint;          // key
    flg:  longint;          // flags
    txt:  arr80;            // some text, f-ex: path, who|where
  end;
    // memory expanded structures
    // premise: read-whoe-at-once
  pCdtHead = ^CdtHead;
  aCdtBlock = array[0..255] of CdtBlock;
  paCdtBlock = ^aCdtBlock;
  aCdtCol = array[0..1023] of CdtCol;
  paCdtCol = ^aCdtCol;
  pCdtUser = ^CdtUser;
  CdtPCol = record          // fast info for column
    name: longword;         // name 2x3 alfanum - Y40 coded
    text: PByte;            // pointer to text-block, if any
    srch: PByte;            // pointer to search-block, if any
    list: PByte;            // pointer to list-block, if any
    sort: PByte;            // pointer to sort-block, if any
  end;
  CdtFile = record          // open or load cdt-file
    id:   longword;         // 1st 6 alfanum of name in Y40 coded
    size: longword;         // known file size
    aloc: longword;         // mem alocated for base of file, usually size
    name: string;           // full path + name
    fil:  file;             // file
    stat: word;             // status of file, see dfsXxx
    ncol: word;             // column count - copy from Head
    rlen: word;             // fixed line-length of main table
    flen: word;             // max full-length of all output data of one line
    nblk: word;             // block count
    logr: word;             // bytes per row-count ~= log256(rows)
    nrow: longint;          // lines count - copy from Head
    mem:  array of byte;    // memory for file
    { CdtHead(mem) }
    blks: paCdtBlock;       // pointer to loaded blocks list
    colf: paCdtCol;         // pointer to loaded columns list
   // colp: aCdtPCol;          alocated fast columns info
    colp: CdtPCol;          // fast column info for used index
    main: PByte;            // pointer to main table - nrow x rlen
  end;

implementation
end.

