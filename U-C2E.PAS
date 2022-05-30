program REMOVER_COM2EXE;
{$M $3000, 0000, 128}

uses dos,crt;

var
  tbuf    :record
             sign :word;
             lpage:word;    {02/03}
             pagef:word;
             reloc:word;    {06/07}
             phead:word;
             minm :word;    { 10, 0a/0b}
             maxm :word;
             _SS  :word;    { 14, 0e/0f}
             _SP  :word;
             crc  :word;    { 18, 12/13}
             _IP  :word;
             _CS  :word;    { 22, 16/17}
             relo1:word;
             overl:word;    { 26, 1a/1b}
             (*
             tpkl :word;    { 28, 1Ch }
             tlnk :word;    { 30 }
             twin :longint; { 60 }
             id   :word;    { fill with offset(twin) }
             entry:longint; { calculate }
             psize:longint; { calculate }
             osize:longint; { calculate }
             *)
           end;
  mbuf    :array [1..50000] of byte;
  f       :file;
  fsize   :longint;
  ergo    :integer;
  flag_exe:boolean;

{-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-}

function MAKE_STR(hc:char; s:string):string;
var d_str:dirstr;
    n_str:namestr;
    e_str:extstr;
begin
  FSplit(s,d_str,n_str,e_str);
  if (hc='C') then MAKE_STR:=d_str+n_str+'.COM'
  else             MAKE_STR:=d_str+n_str+'.@00';
end;

function FIND_FILE(hstr:string):boolean;
var rec_file:SearchRec;
begin
  FindFirst(hstr, anyfile, rec_file);
  fsize:=rec_file.size;
  if (doserror=0) then FIND_FILE:=true
  else                 FIND_FILE:=false;
end;

function OPEN_FILE(hstr:string):boolean;
var lastmode:byte;
begin
  lastmode:=filemode; filemode:=0;
  {$I-}
  Assign(f,hstr); Reset(f,1);
  if (IOResult=0)and(hstr[0]<>#0) then OPEN_FILE:=true
  else                                 OPEN_FILE:=false;
  {$I+}
  filemode:=lastmode;
end;

procedure MAKE_COM(s_from,s_to:string);
label LL1;
var fc      :file;
    pentry,l:longint;
    i,j     :integer;
    c       :char;
begin
  if OPEN_FILE(s_from) then
  begin
    Seek(f,0); BlockRead(f,tbuf,SizeOF(tbuf),ergo);             { fill tbuf }
    pentry:=0; flag_exe:=false;
    if (tbuf.sign=$5A4D)or(tbuf.sign=$4D5A) then
    begin
      flag_exe:=true;
      pentry:=(longint(tbuf._CS) SHL 4) +tbuf._IP +(longint(tbuf.phead) SHL 4);
      pentry:=pentry AND $FFFFF;   { set range for entry point }
    end;
    if (paramcount>1) then
    begin
      val(paramstr(2),l,ergo);
      if (ergo=0)and(l<fsize) then pentry:=l;  { get available offset }
    end;
    Seek(f,pentry);

    if (tbuf._CS<>65520)or(tbuf._SS<>65520)or(tbuf._IP<>256)or(tbuf.reloc<>0)
    then
    begin
      writeln('Attention!!  Input file isn`t a real COM2EXE..  ABORT ? [y/n]');
      repeat until keypressed;
      c:=readkey;
      if (c<>'n')and(c<>'N') then goto LL1;
    end;

    Assign(fc,s_to);
    Rewrite(fc,1);
    Seek(fc,0);

    repeat
      BlockRead (f ,mbuf, SizeOf(mbuf), i);  {from}
      BlockWrite(fc,mbuf, i, j);             {to}
    until (i=0) or (j<>i);

    write('Done: "',MAKE_STR('C',paramstr(1)),'" written successful..');
    if flag_exe then writeln(' eXe-typ for input!')
    else             writeln(' cOm-typ for input!');

    Close(fc);
    LL1:Close(f);                            {jump here, when not C2E}
  end;
end;

{*** Hauptprogramm ***}

begin
  if (paramcount=0) then
  begin
    writeln('Usage: u-e2c.exe <name.exe> [offset]');
  end

  else
  begin
    if (not FIND_FILE(paramstr(1))) then
    begin
      writeln('Error: Input-File not found!');
    end

    else
    begin
      if FIND_FILE(MAKE_STR('C',paramstr(1))) then
      begin
        writeln('Error: Output-File "',MAKE_STR('C',paramstr(1)),'" allready exist!');
      end
      else MAKE_COM(paramstr(1),MAKE_STR('C',paramstr(1)));
    end;

  end;
  writeln;
end.