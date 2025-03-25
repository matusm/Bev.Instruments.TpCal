unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OoMisc, AdPort, StdCtrls, ExtCtrls, AdPacket, Math, TeEngine,
  Series, TeeProcs, Chart, ComCtrls, inifiles, Pruefdaten;

CONST
    MAXWIDTH  = 1360;
    MAXHEIGHT = 1024;
    BUFFERSIZE = MAXWIDTH * MAXHEIGHT * 2;
    SNAP = 7;
    VERL_MIN = -120;
    VERL_BEREICH= 0.2;
    LQ_ANZ=6;

Type
  IEEE754Single=array[0..3] of Char;

Type TLastMessw = record
    Zeit:TDateTime;
    Lichtquelle:Integer;
    Temperatur,Feuchte:double; //HMT-Werte
    Druck:Integer;              //PTB-Wert
    MatTemp:double;            // vom TPCal
    MTIndex:Integer;
    LuftTemp:double;           // vom TPCal
    LTIndex:Integer;
    end;

// Treumann anfang
Type TPruefDaten = record
      FileName:string;
      ET_Zahl:string;
      Pruefer:string;
      Bemerkung:TStrings;
      Inko:string;
      Nennlaenge:string;
      Hersteller:string;
      IdentNr:string;
      Material:string;
      MessmittelNr:string;
      Platte_Seite:string;
      Messflaeche:string;
      end;
// Treumann ende

type
  TfrmMain = class(TForm)
    cpHMT: TApdComPort;
    cpPTB: TApdComPort;
    tmHMT: TTimer;
    adpHMT: TApdDataPacket;
    tmPTB: TTimer;
    cpTPCAL: TApdComPort;
    tmTPCal: TTimer;
    adpPTB: TApdDataPacket;
    PaintBox: TPaintBox;
    btLoadBild: TButton;
    sbWinkel: TScrollBar;
    OpenDialog: TOpenDialog;
    btClose: TButton;
    btSave: TButton;
    btNewMess: TButton;
    Label1: TLabel;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Chart: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    GroupBox1: TGroupBox;
    lbTPCal0: TLabel;
    lbTPCal1: TLabel;
    lbTPCal2: TLabel;
    lbTPCal3: TLabel;
    lbTPCal4: TLabel;
    lbTPCal5: TLabel;
    lbTPCal6: TLabel;
    lbTPCal7: TLabel;
    lbTPCal8: TLabel;
    GroupBox2: TGroupBox;
    lbTemp: TLabel;
    lbFeuchte: TLabel;
    GroupBox3: TGroupBox;
    lbDruck: TLabel;
    rgMTAkt: TRadioGroup;
    rgLTAkt: TRadioGroup;
    rgLichtquelle: TRadioGroup;
    tmVerlauf: TTimer;
    edMessname: TEdit;
    Label2: TLabel;
    edFringe: TEdit;
    Label3: TLabel;
    btInfo: TButton;
    tmLog: TTimer;
    btTakePictureB: TButton;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure tmHMTTimer(Sender: TObject);
    procedure adpHMTStringPacket(Sender: TObject; Data: String);
    procedure tmPTBTimer(Sender: TObject);
    procedure tmTPCalTimer(Sender: TObject);
    procedure adpPTBStringPacket(Sender: TObject; Data: String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure sbWinkelChange(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
    procedure btLoadBildClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure tmVerlaufTimer(Sender: TObject);
    procedure btNewMessClick(Sender: TObject);
    procedure btInfoClick(Sender: TObject);
    procedure rgLichtquelleClick(Sender: TObject);
    procedure tmLogTimer(Sender: TObject);
    procedure btTakePictureBClick(Sender: TObject);
    procedure ChangeCamClick(Sender: TObject);
  private
    { Private declarations }
    {$IFDEF NOHARDWARE}
    TPCAL_toggle:Integer;
    {$ENDIF}
    MonitorHandle:Integer;
    {Treumann anfang}
    MonitorHandle_QE:Integer;
    CamSel:Integer;
    myPDat:TPruefDaten;
    {Treumann ende}
    myLastMessw : TLastMessw;

    fhLog:Text;

    Temperatur,Feuchte:double; //HMT-Werte
    Druck:Integer;              //PTB-Wert
    TPCalWerte:array[0..8] of double; //0..KanalA 1-8 andere
    T_Korr_k:array[0..8] of double; //TemperaturKorrektur
    T_Korr_d:array[0..8] of double; //TemperaturKorrektur
    ExpZeiten:Array[0..LQ_ANZ-1] of Integer;
    FringeFrac:double;
    WantClose:boolean;

    bmBild:TBitMap;
    BilddatenLoaded:boolean;
    BildDaten: Array[0..MAXWIDTH-1,0..MAXHEIGHT-1] of Word;
    MessdatenPfad:string;
    Messname:string;

    PLO,PRU:TPoint;
    P1,P2,P3,P4,P5,P6:TPoint;
    LinPos_A,LinPos_B:Integer;
    //   P1-------P2
    //   P3-------P4
    //   P5-------P6
    DragStatus:Integer; //  0 .. nix  1 .. linksoben   2 .. rechtsunten

    MTVerl,LTVerl:array[VERL_MIN+1..0] of double;

    function SetPoints(lox,loy,rux,ruy:Integer):boolean;

    procedure LoadBmp(Dateiname:string);
    procedure LoadFits(Dateiname:string);
    procedure SaveFits(Dateiname:string);

    function GetFehlerQuadrat(om,Ph:double; funktwerte:Array of Single):double;
    function Fringe(Stelle:Integer; ome1,phi1,ome2,phi2:double):double;
    procedure ExtractNormVal(StartPunkt,Endpunkt: TPoint ;Var Werte:array of single);

    procedure ExtractBresenham(PS, PE:TPoint; Var Werte:Array of Integer);

    procedure GetSinus(inp_arr:Array of single; Var omega,phi:double);
    procedure GN_Iterate(Var omega,phi:double; Werte:array of Single);
    procedure CalcFringe;
    procedure PaintBoxResize(oldWidth,oldHeight:Integer);
    function LQInd2Str(index:Integer;Uml:boolean):string;

    function CalcShiftBits:Integer;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

Uses U_FTG2, FInfo;

function Tr(x:Integer):Integer;
begin
result:=x div 2;
end;

function RTr(x:Integer):Integer;
begin
result:=x * 2;
end;

function IsInt(IntString:string):boolean;
Var len,AnzNumber,i:Integer;
begin
len:=length(IntString);
AnzNumber:=0;
for i:=1 to len do
  if IntString[i] in ['0'..'9'] then inc(AnzNumber);
result:=(len>0) and (AnzNumber=len);
end;

function IsFloat(IntFloat:string):boolean;
Var len,AnzNumber,AnzDec,i:Integer;
begin
len:=length(IntFloat);
AnzNumber:=0;
AnzDec:=0;
for i:=1 to len do
  if IntFloat[i] in ['0'..'9'] then inc(AnzNumber)
    else if IntFloat[i]='.' then inc(AnzDec);

result:=(AnzNumber>0) and (AnzNumber+AnzDec=len) and (AnzDec=1);
end;

procedure wait(x:Integer);
Var start:Cardinal;
begin
start:=GetTickCount;
repeat
Application.ProcessMessages;
sleep(5);
until (abs(GetTickCount-start) > x);
end;

function TfrmMain.LQInd2Str(index:Integer;Uml:boolean):string;
begin
if Uml then
    case index of
        0: result:='HeNe rot';
        1: result:='HeNe grün';
        2: result:='Cd rot';
        3: result:='Cd grün';
        4: result:='Cd blau';
        5: result:='Cd violett';
        end
  else
     case index of
        0: result:='HeNe_rot';
        1: result:='HeNe_gruen';
        2: result:='Cd_rot';
        3: result:='Cd_gruen';
        4: result:='Cd_blau';
        5: result:='Cd_violett';
        end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
Var i:Integer;
    ini:TIniFile;
    V1,       // Major Version
    V2,       // Minor Version
    V3,       // Release
    V4: Word; // Build Number
    VerInfoSize, VerValueSize, Dummy : DWORD;
    VerInfo : Pointer;
    VerValue : PVSFixedFileInfo;
begin
VerInfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), Dummy);
GetMem(VerInfo, VerInfoSize);
GetFileVersionInfo(PChar(Application.ExeName), 0, VerInfoSize, VerInfo);
VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
with VerValue^ do
    begin
       V1 := dwFileVersionMS shr 16;
       V2 := dwFileVersionMS and $FFFF;
       V3 := dwFileVersionLS shr 16;
       V4 := dwFileVersionLS and $FFFF;
    end;
FreeMem(VerInfo, VerInfoSize);
self.Caption:=self.Caption +'         Version: '+IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + ' Build: ' + IntToStr(V4);

self.Left:=100;
ini:=TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini'));
LinPos_A:=ini.ReadInteger('LINIENPOS','A',0);
LinPos_B:=ini.ReadInteger('LINIENPOS','B',100);

for i:=0 to LQ_ANZ-1 do
    ExpZeiten[i]:=ini.ReadInteger('EXP_ZEITEN',LQInd2Str(i,false),100);

Messdatenpfad:=IncludeTrailingBackslash(ini.ReadString('PFADE','DATENPFAD','c:'));

// Treumann nur für Test remark
for i:=0 to 8 do
    begin
    T_Korr_k[i]:=ini.ReadFloat('TPCAL_KORREKTUR','k'+inttostr(i),1);
    T_Korr_d[i]:=ini.ReadFloat('TPCAL_KORREKTUR','d'+inttostr(i),1);
//    T_Korr_k[i]:=1;
//    T_Korr_d[i]:=0;
    end;

tmLog.Interval:=1000*ini.ReadInteger('LOGGING','LOG_INTERVALL',60);
if tmLog.Interval>0 then
    begin
    Assignfile(fhLog,ChangeFileExt(ParamStr(0),'.log'));
    ReWrite(fhLog);
    end;

tmLog.Enabled:=tmLog.Interval>0;

cpTPCAL.ComNumber:=ini.ReadInteger('COMPORTS','TPCAL',0);
cpTPCAL.baud:=9600;
cpTPCAL.DataBits:=8;
cpPTB.Parity:=pNone;
cpPTB.StopBits:=1;
cpTPCAL.RTS:=true;
cpTPCAL.DTR:=false;
cpTPCAL.Open:=true;

cpHMT.ComNumber:=ini.ReadInteger('COMPORTS','HMT',0);
cpHMT.Baud:=4800;
cpHMT.DataBits:=7;
cpHMT.Parity:=pEven;
cpHMT.StopBits:=1;
cpHMT.Open:=true;

cpPTB.ComNumber:=ini.ReadInteger('COMPORTS','PTB',0);
cpPTB.Baud:=9600;
cpPTB.DataBits:=7;
cpPTB.Parity:=pEven;
cpPTB.StopBits:=1;
cpPTB.open:=true;
cpPTB.Output:='RESET'#13;
cpPTB.Output:='ECHO OFF'#13;

ini.free;

bmBild:=TBitMap.Create;
bmBild.Width:=PaintBox.Width;
bmBild.Height:=PaintBox.Height;

OpenDialog.InitialDir:=Messdatenpfad;
BilddatenLoaded:=false;

tmHMT.enabled:=true;
tmPTB.Enabled:=true;
tmTPCal.Enabled:=true;
tmVerlauf.Enabled:=true;

{$IFNDEF NOHARDWARE}
deletefile('c:\grab.raw');
{$ENDIF}

for i:=0 to 8 do TPCalWerte[i]:=-999;
for i:=VERL_MIN+1 to 0 do
  begin
  MTVerl[i]:=0;
  LTVerl[i]:=0;
  end;
Chart.LeftAxis.Maximum:=20+VERL_BEREICH;
Chart.LeftAxis.Minimum:=20-VERL_BEREICH;
for i:=0 to LQ_ANZ-1 do
  rgLichtQuelle.Items.add(LQInd2Str(i,true));
PageControl.ActivePageIndex:=0;

{Treumann anfang}
//WinExec(PChar(IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+'uniform.exe'),SW_SHOW);
//MonitorHandle:=FindWindow(nil,'Pixelfly');
WinExec(PChar(IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+'uniform_qe.exe'),SW_SHOW);
MonitorHandle_QE:=FindWindow(nil,'Pixelfly QE');
//CamSel:=1;
//SendMessage(Monitorhandle_QE,WM_USER+2,CamSel,0);
{Treumann ende}

rgLichtQuelle.ItemIndex:=0;
end;

procedure TfrmMain.tmHMTTimer(Sender: TObject);
begin
cpHMT.Output:='SEND D'#13;
end;

procedure TfrmMain.tmPTBTimer(Sender: TObject);
begin
cpPTB.Output:='SEND'#13;
end;

procedure TfrmMain.tmTPCalTimer(Sender: TObject);
  function GetTemp(ti:Integer):string;
  begin
  if TPCalWerte[ti]=-999 then result:='n.a'
    else result:=FormatFloat('0.000',TPCalWerte[ti])+' °C';
  end;

  function GetFarbe(ti:Integer):TColor;
  begin
  result:=clBlack;
  if (ti>=1) and (ti<=4) and (rgMTAkt.ItemIndex+1=ti) then result:=$FF8000;
  if (ti>=5) and (ti<=6) and (rgLTAkt.ItemIndex+5=ti) then result:=$4080FF;
  end;

Var ant:string;
    dumTemp:single;
    Kanal:Integer;
begin
cpTPCAL.Output:='h';
wait(150);
if WantClose then exit;
ant:='';
while cpTPCAL.CharReady do
  ant:=ant+cpTPCAL.GetChar;

//  a   #6  (ACK)
//  b   MD00100010029600
//  c   V 1.05
//  d   #9
//  e   #4
//  f   #$15  NACK
//  h   #$15  NACK
{$IFDEF NOHARDWARE}
TPCal_Toggle:=(TPCal_Toggle+1) mod 9;
dumtemp:=20+random/10;
ant:=#6+ chr(TPCal_Toggle)  +  IEEE754Single(dumTemp)[0]+IEEE754Single(dumTemp)[1]+IEEE754Single(dumTemp)[2]+IEEE754Single(dumTemp)[3]+#13;
{$ENDIF}

if length(ant)=7 then
  if ant[1]=#6 then
    begin
    Kanal:=Ord(ant[2]);
    IEEE754Single(dumTemp)[0]:=ant[3];
    IEEE754Single(dumTemp)[1]:=ant[4];
    IEEE754Single(dumTemp)[2]:=ant[5];
    IEEE754Single(dumTemp)[3]:=ant[6];
    if (Kanal>=0) and (Kanal<=8) then
      TPCalWerte[Kanal]:=T_Korr_k[Kanal] * dumtemp + T_Korr_d[Kanal];
    end;

lbTPCal1.Font.Color:=GetFarbe(1);
lbTPCal2.Font.Color:=GetFarbe(2);
lbTPCal3.Font.Color:=GetFarbe(3);
lbTPCal4.Font.Color:=GetFarbe(4);
lbTPCal5.Font.Color:=GetFarbe(5);
lbTPCal6.Font.Color:=GetFarbe(6);

lbTPCal0.Caption:='SPRT: '+GetTemp(0);
lbTPCal1.Caption:='Materialtemp.1: '+GetTemp(1);
lbTPCal2.Caption:='Materialtemp.2: '+GetTemp(2);
lbTPCal3.Caption:='Materialtemp.3: '+GetTemp(3);
lbTPCal4.Caption:='Materialtemp.4: '+GetTemp(4);
lbTPCal5.Caption:='Lufttemp.1: '+GetTemp(5);
lbTPCal6.Caption:='Lufttemp.2: '+GetTemp(6);
lbTPCal7.Caption:='Kanal 7: '+GetTemp(7);
lbTPCal8.Caption:='Kontrolle: '+GetTemp(8);

end;

procedure TfrmMain.adpHMTStringPacket(Sender: TObject; Data: String);
Var stTemp,stFeuchte:string;
begin
stTemp:=trim(copy(Data,1,8));
stFeuchte:=trim(copy(Data,10,8));
if IsFloat(stTemp) then
    begin
    Temperatur:=StrToFloat(stTemp);
    lbTemp.Caption:=Format('Temperatur: %.2f °C',[Temperatur]);
    end
  else lbTemp.Caption:='Fehler';

if IsFloat(stFeuchte) then
    begin
    Feuchte:=StrToFloat(stFeuchte);
    lbFeuchte.Caption:=Format('Feuchte: %.1f %%',[Feuchte]);
    end
  else lbFeuchte.Caption:='Fehler';

end;

procedure TfrmMain.adpPTBStringPacket(Sender: TObject; Data: String);
Var st:string;
begin
st:=trim(copy(Data,1,6));
if IsInt(st) then
    begin
    Druck:=StrToInt(st);
    lbDruck.caption:=format('Druck: %d Pa',[Druck]);
    end
  else lbDruck.caption:='Fehler';
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
WantClose:=true;

if tmLog.Interval>0 then CloseFile(fhLog);

bmBild.Free;

tmHMT.Enabled:=false;
tmPTB.Enabled:=false;
tmTPCal.Enabled:=false;

adpHMT.Enabled:=false;
adpPTB.Enabled:=false;

cpHMT.Open:=false;
cpTPCal.Open:=false;
cpPTB.Open:=false; 
end;

procedure TfrmMain.btTakePictureBClick(Sender: TObject);
Var whnd:Integer;
    x,y:Integer;
    b1:byte;
    w1:word;
    Zeile:Array of Word;
    ShiftBits,fitsfile:Integer;
    oldW,oldH:Integer;
    StartTick:Cardinal;
    TimeOut:boolean;
begin
btTakePictureB.Enabled:=false;
try

SendMessage(Monitorhandle_QE,WM_USER,0,0);
StartTick:=GetTickCount;
TimeOut:=false;

repeat
sleep(50);
Application.ProcessMessages;
TimeOut:=abs(GetTickCount-StartTick)>20000;
until fileexists('c:\grab.raw') or Timeout;

if TimeOut then
  raise Exception.Create('Bildaufnahme hat nicht funktioniert!');

oldW:=bmBild.Width;
oldH:=bmBild.Height;

fitsfile:=FileOpen('c:\grab.raw', fmShareDenyNone);
if fitsfile<=0 then
    raise exception.create('Datei gesperrt!');

if (CamSel=1) then SetLength(zeile,MAXWIDTH);
if (CamSel=0) then SetLength(zeile,MAXWIDTH+32); {um 32 mehr PixelFly QE}

for y:=0 to MAXHEIGHT-1 do
    begin
    if (CamSel=1) then fileRead(fitsfile,zeile[0],MAXWIDTH*2);
    if (CamSel=0) then fileRead(fitsfile,zeile[0],MAXWIDTH*2+32); {um 32 mehr einlesen PixelFly QE}
{    for x:=0 to MAXWIDTH-1 do
        BildDaten[x,y]:=Word(((zeile[(x shl 1)+1] shl 8) or zeile[(x shl 1)]));}
    for x:=0 to MAXWIDTH-1 do
        BildDaten[x,y]:=Zeile[x];
    end;
finalize(zeile);
fileclose(fitsfile);

bmBild.Width:=MAXWIDTH;
bmBild.height:=MAXHEIGHT;

ShiftBits:=CalcShiftBits;

for y:=0 to MAXHEIGHT-1 do
    for x:=0 to MAXWIDTH-1 do
        begin
        w1:=(BildDaten[x,y] shr ShiftBits) and $FF00;
        if w1<>0 then b1:=$FF
            else b1:=Byte(BildDaten[x,y] shr ShiftBits);
        bmBild.Canvas.Pixels[x,y]:=b1 or (b1 shl 8) or (b1 shl 16);
        end;

BilddatenLoaded:=true;
PaintBoxResize(oldW,oldH);

myLastMessw.Zeit:=now;
myLastMessw.Lichtquelle:=rgLichtquelle.ItemIndex;
myLastMessw.Temperatur:=Temperatur;
myLastMessw.Feuchte:=Feuchte;
myLastMessw.Druck:=Druck;
myLastMessw.MTIndex:=rgMTAkt.ItemIndex+1;
myLastMessw.MatTemp:=TPCalWerte[myLastMessw.MTIndex];
myLastMessw.LTIndex:=rgLTAkt.ItemIndex+1;
myLastMessw.LuftTemp:=TPCalWerte[myLastMessw.LTIndex+4];
btSave.Enabled:=BildDatenLoaded and (Messname<>'');
finally
{$IFNDEF NOHARDWARE}
DeleteFile('c:\grab.raw');
{$ENDIF}
btTakePictureB.Enabled:=true;
end;
end;
{Treumann ende}

procedure TfrmMain.LoadBmp(Dateiname:string);
Var x,y:Integer;
    line : PByteArray;
begin
bmBild.LoadFromFile(Dateiname);
if (bmBild.height>MAXHEIGHT) or (bmBild.width>MAXWIDTH) then
    raise exception.create('Bild zu groß!');

Screen.Cursor:=crHourglass;

for y:=0 to bmBild.height-1 do
  begin
  line := bmBild.ScanLine[y];
  for x:=0 to bmBild.Width-1 do
    BildDaten[x,y]:=line[x];
  end;

BilddatenLoaded:=true;
Screen.Cursor:=crDefault;
end;

procedure TfrmMain.LoadFits;
    procedure Extract(input:string;Var key,value:string);
    Var p:Integer;
    begin
    p:=pos('=',input);
    if p=0 then key:=trim(input)
      else
        begin
        key:=trim(copy(input,1,p-1));
        value:=copy(input,p+1,length(input)-p);
        p:=pos('/',value); // kommentare filtern
        if p<>0 then value:=copy(value,1,p-1);
        value:=trim(value);
        end;
    end;

Var i,x,y,ShiftBits:Integer;
    w1:word;
    Header:Array[0..35,0..79] of Char;
    line,ke,va:string;
    Naxis1,Naxis2,BitPix,BZero:Integer;
    b1:byte;
    Zeile:Array of Byte;
    fitsfile:Integer;

begin
fitsfile:=FileOpen(Dateiname, fmShareDenyNone);
if fitsfile<=0 then
    raise exception.create('Datei gesperrt!');
fileRead(fitsfile,Header,2880);

for i:=0 to 35 do
    begin
    SetString(line,pchar(@Header[i,0]),80);
    extract(line,ke,va);
    if ke='END' then break;
    if ke='NAXIS1' then naxis1:=StrToInt(va)
        else if ke='NAXIS2' then naxis2:=StrToInt(va)
        else if ke='BITPIX' then BitPix:=StrToInt(va)
        else if ke='BZERO' then BZero:=trunc(StrToFloat(StringReplace(va,'.',Decimalseparator,[])));
    end;
if bitpix<>16 then
    raise exception.Create('Dieses Fits-Format wird nicht unterstützt!');

SetLength(zeile,naxis1*2);

for y:=Naxis2-1 downto 0 do
    begin
    fileRead(fitsfile,zeile[0],naxis1*2);
    for x:=0 to Naxis1-1 do
        BildDaten[x,y]:=Word(((zeile[x shl 1] shl 8) or zeile[(x shl 1)+1]) - BZero);
    end;
finalize(zeile);
fileclose(fitsfile);

bmBild.Width:=Naxis1;
bmBild.height:=Naxis2;

ShiftBits:=CalcShiftBits;

for y:=0 to Naxis2-1 do
    for x:=0 to Naxis1-1 do
        begin
        w1:=(BildDaten[x,y] shr ShiftBits) and $FF00;
        if w1<>0 then
           b1:=$FF
            else
           b1:=Byte(BildDaten[x,y] shr ShiftBits);

        bmBild.Canvas.Pixels[x,y]:=b1 or (b1 shl 8) or (b1 shl 16);
        end;
BilddatenLoaded:=true;
end;


function TfrmMain.GetFehlerQuadrat(Om,Ph:double; funktwerte:Array of Single):double;
Var i:Integer;
    y:double;
begin
result:=0;
for i:=0 to High(funktwerte) do
    begin
    y:=cos(om*i+ph);
    result:=result+sqr(funktwerte[i]-y);
    end;
end;

function TfrmMain.Fringe(Stelle:Integer;ome1,phi1,ome2,phi2:double):double;
Var lam1,x,y:double;
    StelleY:double;
begin
lam1:=2*pi/ome1;

x:=Stelle*ome1  +  phi1;

while x>2*pi do
    x:=x-2*pi;

// auf Stelle steht erste Welle auf Phase x
y:=Stelle*ome2 +  phi2;
while y>2*pi do
    y:=y-2*pi;

if x<y then y:=y-2*pi;

StelleY:=Stelle+1/ome1*(x-y);
result:=1-(StelleY-Stelle)/lam1;
end;

procedure TfrmMain.ExtractBresenham(PS, PE:TPoint; Var Werte:Array of Integer);
  procedure TauschePunkte(var Punkt1: TPoint; var Punkt2: TPoint);
  var
    Temp: TPoint;
  begin
    Temp := Punkt1;
    Punkt1 := Punkt2;
    Punkt2 := Temp;
  end;
var
  x, y, e, dx, dy, li: Integer;
begin
  li:=0;
  if PS.X > PE.X then TauschePunkte(PS,PE);
  e := 0;
  x := PS.X;
  y := PS.Y;
  dx := PE.X - PS.X;
  dy := PE.Y - PS.Y;
  if dy >= 0 then     // positive Steigung
    if dx >= dy then    // leichte positive Steigung
      for x := PS.X to PE.X do
      begin
        Werte[li]:=(BildDaten[x,y+1]+BildDaten[x,y]+BildDaten[x,y-1]) div 3;
        inc(li);
        if 2*(e + dy) < dx then
          Inc(e,dy)
        else
        begin
          Inc(y);
          Inc(e, dy-dx);
        end;
      end
    else                // starke positive Steigung
      for y := PS.Y to PE.Y do
      begin
        Werte[li]:=BildDaten[x,y];
        inc(li);
        if 2*(e + dx) < dy then
          Inc(e,dx)
        else
        begin
          Inc(x);
          Inc(e, dx-dy);
        end;
      end
  else                // negative Steigung
    if dx >= -dy then    // leichte negative Steigung
      for x := PS.X to PE.X do
      begin
        Werte[li]:=(BildDaten[x,y+1]+BildDaten[x,y]+BildDaten[x,y-1]) div 3;
        inc(li);
        if 2*(e + dy) > -dx then
          Inc(e,dy)
        else
        begin
          Dec(y);
          Inc(e, dy+dx);
        end;
      end
    else                // starke negative Steigung
    begin
      TauschePunkte(PS,PE);
      x := PS.X;
      dx := PE.X - PS.X;
      dy := PE.Y - PS.Y;
      for y := PS.Y to PE.Y do
      begin
        Werte[li]:=BildDaten[x,y];
        inc(li);
        if 2*(e + dx) > -dy then
          Inc(e,dx)
        else
        begin
          Dec(x);
          Inc(e, dx+dy);
        end;
      end
    end;
end;


procedure TfrmMain.GetSinus(inp_arr:Array of single; Var omega,phi:double);
Var {fft_tran:array of single;
    plan : Pointer;}
    MaxWert:single;
    i:Integer;
    MaxFreqBand:Integer;
    fq,minFQ:double;


    NC: integer;
    Cinp,Cout,CScr: array of tComplex;
    j: integer; a: double;

begin //FFT zur groben omegawert
  NC := length(inp_arr);
  SetLength(Cinp,NC);
  SetLength(Cout,NC);
  SetLength(CScr,NC);
  For j := 0 to NC-1 do
    begin
    Cinp[j].r:=cos(inp_arr[j]);
    Cinp[j].i:=sin(inp_arr[j]);
    end;

  CFTG(Cinp,Cout,CScr,+NC);

MaxWert:=0;
for i:=1 to high(cout) div 2 do
    begin
    a:=sqr(cout[i].r) + sqr(cout[i].i);
    if a>MaxWert then
        begin
        MaxWert:=a;
        MaxFreqBand:=i;
        end;
    end;
finalize(CInp);
finalize(COut);
finalize(CScr);

omega:=2*pi*MaxFreqBand/high(inp_arr);

MinFQ:=999999;
for i:=0 to 100 do //Phase schätzen
    begin
    fq:=GetFehlerQuadrat(omega,6.282*(i/100),inp_arr);
    if fq<MinFQ then
        begin
        phi:=6.282*(i/100);
        Minfq:=fq;
        end;
    end;
//gauß Newton Verfahren
for i:=1 to 10 do
    GN_Iterate(omega,phi,inp_arr);
if phi>2*pi then phi:=phi-2*pi;
if phi<0 then phi:=phi+2*pi;
end;

procedure TfrmMain.CalcFringe;
Var NormVal:Array of Single;
    omega1,phi1:double;
    omega2,phi2:double;
    omega3,phi3:double;
    laenge:Integer;
    faktor:double;
    faktor1,faktor2:double;
begin
laenge:=Max(abs(P1.X-P2.X),abs(P1.Y-P2.Y))+1;
SetLength(NormVal,laenge);

ExtractNormVal(P1,P2,NormVal);
GetSinus(NormVal,omega1,phi1);

ExtractNormVal(P3,P4,NormVal);
GetSinus(NormVal,omega2,phi2);

ExtractNormVal(P5,P6,NormVal);
GetSinus(NormVal,omega3,phi3);
Finalize(NormVal);

faktor1:=Fringe(laenge div 2,omega2,phi2,omega1,phi1);
faktor2:=Fringe(laenge div 2,omega2,phi2,omega3,phi3);

if abs(Faktor1-faktor2)>0.5 then
    faktor:=(faktor1+faktor2+1)/2
  else faktor:=(faktor1+faktor2)/2;

if faktor>1 then faktor:=faktor-1;
FringeFrac:=faktor;
edFringe.Text:=FormatFloat('0.00',100*FringeFrac)+' %';
end;

procedure TfrmMain.ExtractNormVal(StartPunkt,Endpunkt: TPoint ;Var Werte:array of single);
Var Helligkeiten:array of Integer;
    MaxInp,MinInp,i:Integer;
    Sum:Integer;
    SumSqr:double;
    Mittelwert:double;
    Ampl:double;
begin
SetLength(Helligkeiten,length(Werte));

ExtractBresenham(StartPunkt,EndPunkt, Helligkeiten);

MaxInp:=-99999999;
MinInp:=99999999;
Sum:=0;
SumSqr:=0;
for i:=0 to high(Helligkeiten) do
    begin
    Sum:=sum+Helligkeiten[i];
    SumSqr:=SumSqr+sqr(Helligkeiten[i]);
    if Helligkeiten[i]>MaxInp then MaxInp:=Helligkeiten[i];
    if Helligkeiten[i]<MinInp then MinInp:=Helligkeiten[i];
    end;
Mittelwert:=sum/length(Helligkeiten);
Ampl:=2*((SumSqr/length(Helligkeiten)) - sqr(Mittelwert));
if Ampl>0 then Ampl:=Sqrt(Ampl)
    else Ampl:=0;

if Ampl<>0 then
    for i:=0 to high(Helligkeiten) do
        Werte[i]:=(Helligkeiten[i] - Mittelwert) / Ampl;


finalize(Helligkeiten);
end;

procedure TfrmMain.GN_Iterate(Var omega,phi:double; Werte:array of Single);
Var DM:Array of Array[0..1] of single;
    d11,d12,d22,r,r1,r2:double;
    Det:double;
    i:Integer;
begin
SetLength(DM,length(Werte));
for i:=0 to high(DM) do
    begin
    DM[i,1]:=-sin(omega*i+phi);
    DM[i,0]:=i*DM[i,1];
    end;
//trans(DM)  *  DM          trans(DM) * r

//  d11 d12                    r1
//  d21 d22                    r2
r1:=0;
r2:=0;
d11:=0;
d12:=0;
d22:=0;
for i:=0 to high(DM) do
    begin
    d11:=d11+sqr(DM[i,0]);
    d22:=d22+sqr(DM[i,1]);
    d12:=d12+DM[i,0]*DM[i,1];
    r:=(cos(omega*i+phi) - Werte[i]);
    r1:=r1+DM[i,0]*r;
    r2:=r2+DM[i,1]*r;
    end;
Det:=d11*d22-sqr(d12);

omega:=omega-(r1*d22-r2*d12)/Det;
phi:=phi-(d11*r2-d12*r1)/Det; //d21=d12
finalize(DM);
end;

function TfrmMain.SetPoints(lox,loy,rux,ruy:Integer):boolean;
Var mx,my:Integer;
    t,tanAl,Winkel:double;
    xx,yy:Integer;
    x1,y1,x2,y2:integer;
begin
xx:=((rux-lox) - LinPos_B) DIV 2;
if xx<0 then xx:=0;

x1:=lox + xx;
y1:=loy - LinPos_A;
x2:=rux - xx;
y2:=ruy + LinPos_A;

Winkel:=sbWinkel.Position/4;
tanAl:=-tan(Winkel*pi/180);

mx:=(x1+x2) div 2;
my:=(y1+y2) div 2;

t:=2*(mx+my*tanAl-x1-y1*tanAl)/(1+sqr(tanAl));

xx:=trunc(t);
yy:=trunc(tanAl*t);

result:=true;
if winkel>=0 then
    begin
    result:=result and (x1>5);
    result:=result and (x2<bmBild.Width-6);
    result:=result and ((y1+yy)>5);  //p2.Y
    result:=result and ((y2-yy)<bmBild.height-6);  //p5.Y
    end
  else
    begin
    result:=result and ((x2-xx)>5); //p5
    result:=result and ((x1+xx)<bmBild.Width-6); //p2
    result:=result and (y1>5);
    result:=result and (y2<bmBild.height-6);
    end;
result:=result and (xx>20);
result:=result and ((y2-yy-y1)>20);

if result then
    begin
    PLO.X:=lox;
    PLO.Y:=loy;
    PRU.X:=rux;
    PRU.Y:=ruy;
    P1.X:=x1;
    P1.Y:=y1;
    P2.X:=x1+xx;
    P2.Y:=y1+yy;
    P3.X:=(x1+x2-xx) div 2;
    P3.Y:=(y1+y2-yy) div 2;
    P4.X:=(x1+x2+xx) div 2;
    P4.Y:=(y1+y2+yy) div 2;
    P5.X:=x2-xx;
    P5.Y:=y2-yy;
    P6.X:=x2;
    P6.Y:=y2;
    end;
end;

procedure TfrmMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if Button = mbLeft then
    begin
    if (abs(RTr(x)-PLO.X)<SNAP) and (abs(RTr(y)-PLO.Y)<SNAP) then
        begin
        DragStatus:=1;
        PaintBoxPaint(nil);
        end;
    if (abs(RTr(x)-PRU.X)<SNAP) and (abs(RTr(y)-PRU.Y)<SNAP) then
        begin
        DragStatus:=2;
        PaintBoxPaint(nil);
        end;
    end;
end;

procedure TfrmMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
DragStatus:=0;
PaintBoxPaint(nil);
end;

procedure TfrmMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
Var x1,y1,x2,y2:Integer;
begin
if x<0 then x:=0;
if y<0 then y:=0;
if x>Tr(bmBild.width) then x:=Tr(bmBild.width);
if y>Tr(bmBild.height) then y:=Tr(bmBild.height);

if DragStatus=1 then
    begin
    x1:=RTr(x);
    y1:=RTr(y);
    if PRU.X-x1<80 then x1:=PRU.X-80;
    if PRU.Y-y1<20 then y1:=PRU.Y-20;
    x2:=PRU.X;
    y2:=PRU.Y;
    end
  else if DragStatus=2 then
    begin
    x1:=PLO.X;
    y1:=PLO.Y;
    x2:=RTr(x);
    y2:=RTr(y);
    if x2-PLO.X<80 then x2:=PLO.X+80;
    if y2-PLO.Y<20 then y2:=PLO.Y+20;
    end
  else exit;

if SetPoints(x1,y1,x2,y2) then
    begin
    PaintBoxPaint(nil);
    CalcFringe;
    end;
end;

procedure TfrmMain.sbWinkelChange(Sender: TObject);
begin
if SetPoints(PLO.X,PLO.Y,PRU.X,PRU.Y) then
    begin
    PaintBoxPaint(nil);
    CalcFringe;
    end;
end;

procedure TfrmMain.PaintBoxPaint(Sender: TObject);
begin
if not BilddatenLoaded then exit;
PaintBox.canvas.StretchDraw(Rect(0,0,tr(bmBild.width),tr(bmBild.Height)),bmBild);

if DragStatus=0 then PaintBox.Canvas.Pen.Color:=clRed
    else PaintBox.Canvas.Pen.Color:=clGreen;
PaintBox.Canvas.Pen.style:=psSolid;

PaintBox.canvas.Brush.Color:=PaintBox.Canvas.Pen.Color;
PaintBox.canvas.Ellipse(tr(PLO.x)-5,tr(PLO.y)-5,tr(PLO.x)+5,tr(PLO.y)+5);
PaintBox.canvas.Ellipse(tr(PRU.x)-5,tr(PRU.y)-5,tr(PRU.x)+5,tr(PRU.y)+5);

PaintBox.Canvas.MoveTo(tr(P1.x),tr(P1.y));
PaintBox.Canvas.LineTo(tr(P2.x),tr(P2.y));
PaintBox.Canvas.MoveTo(tr(P3.x),tr(P3.y));
PaintBox.Canvas.LineTo(tr(P4.x),tr(P4.y));
PaintBox.Canvas.MoveTo(tr(P5.x),tr(P5.y));
PaintBox.Canvas.LineTo(tr(P6.x),tr(P6.y));

PaintBox.Canvas.Pen.style:=psDot;
PaintBox.canvas.Brush.color:=clBlack;
PaintBox.canvas.Brush.style:=bsClear;
PaintBox.Canvas.MoveTo(tr((PLO.x + PRU.x) DIV 2),tr(P1.y));
PaintBox.Canvas.LineTo(tr((PLO.x + PRU.x) DIV 2),tr(P6.y));
end;

procedure TfrmMain.btCloseClick(Sender: TObject);
Var whnd:Integer;
begin
{Treumann anfang}
//whnd:=FindWindow(nil,'Pixelfly');
//if whnd<>0 then SendMessage(whnd,WM_CLOSE,0,0);
whnd:=FindWindow(nil,'Pixelfly QE');
if whnd<>0 then SendMessage(whnd,WM_CLOSE,0,0);
{Treumann ende}

WantClose:=true;
close;
end;

procedure TfrmMain.btLoadBildClick(Sender: TObject);
Var oldW,oldH:Integer;
begin
if OpenDialog.Execute then
    begin
    oldW:=bmBild.Width;
    oldH:=bmBild.Height;

    if uppercase(ExtractFileExt(OpenDialog.FileName))='.FIT' then LoadFits(OpenDialog.FileName)
        else LoadBmp(OpenDialog.FileName);

    PaintBoxResize(OldW,OldH);
    end;
end;

procedure TfrmMain.PaintBoxResize(oldWidth,oldHeight:Integer);
begin
PaintBox.Width:=tr(bmBild.Width);
PaintBox.Height:=tr(bmBild.Height);

if (oldWidth<>bmBild.Width) or (oldHeight<>bmBild.Height) then
        begin
        sbWinkel.Position:=0;

        PLO.X:=trunc(bmBild.Width*0.2);
        PLO.Y:=trunc(bmBild.Height*0.3);
        PRU.X:=trunc(bmBild.Width*0.8);
        PRU.Y:=trunc(bmBild.Height*0.7);
        SetPoints(PLO.X,PLO.Y,PRU.X,PRU.Y);
        end;

PaintBoxPaint(nil);
CalcFringe;
end;

procedure TfrmMain.btSaveClick(Sender: TObject);
Var fh:textfile;
    i:Integer;
    sign:char;
begin
AssignFile(fh,MessdatenPfad+Messname+'.txt');
if fileexists(MessdatenPfad+messname+'.txt') then
    begin
    append(fh);
    WriteLn(fh,'-------------------------------------------------------');
    end
  else
    begin
    Rewrite(fh);
    WriteLn(fh,'Systemparameter');
    WriteLn(fh,'');
    WriteLn(fh,'   Protokoll : '+Messname);
    WriteLn(fh,'');
    // Treumann anfang
    WriteLn(fh,' Allgemeines');
    WriteLn(fh,'   File-Name       : '+Messname);
    WriteLn(fh,'   E/T-Zahl        : '+myPDat.ET_Zahl);
    WriteLn(fh,'   Prüfer          : '+myPDat.Pruefer);
    WriteLn(fh,'   Bemerkung       :');
    for i:=0 to myPDat.Bemerkung.Count-1 do WriteLn(fh, '                     '+ myPDat.Bemerkung.Strings[i]);
    WriteLn(fh,'   INKO            : '+myPDat.Inko);
    WriteLn(fh,'');
    WriteLn(fh,' Endmaß');
    WriteLn(fh,'   Nennlänge       : '+myPDat.Nennlaenge);
    WriteLn(fh,'   Hersteller      : '+myPDat.Hersteller);
    WriteLn(fh,'   Ident.Nr.:      : '+myPDat.IdentNr);
    WriteLn(fh,'   Material        : '+myPDat.Material);
    WriteLn(fh,'   MessmittelNr.   : '+myPDat.MessmittelNr);
    WriteLn(fh,'');
    WriteLn(fh,' Anschub');
    WriteLn(fh,'   Platte/Seite    : '+myPDat.Platte_Seite);
    WriteLn(fh,'   ang. Messfläche : '+myPDat.Messflaeche);
    WriteLn(fh,'');
    // Treumann ende
    WriteLn(fh,'   Belichtungszeiten');
    for i:=0 to LQ_ANZ-1 do
        WriteLn(fh,Format('      %-12s %5d ms',[LQInd2Str(i,true)+' :',ExpZeiten[i]]));
    WriteLn(fh,'');
    WriteLn(fh,'   Geometrieparameter');
    WriteLn(fh,format('      a = %4d pixel',[LinPos_A]));
    WriteLn(fh,format('      b = %4d pixel',[LinPos_B]));
    WriteLn(fh,'');
    WriteLn(fh,'   TPCal Korrekturwerte');
    for i:=0 to 8 do
        begin
        if T_Korr_d[i]>0 then sign:='+' else sign:='-';
        WriteLn(fh,format('      k%d = %.5f   d%d = %s%.4f',[i,T_Korr_k[i],i,sign,abs(T_Korr_d[i])]));
        end;
    WriteLn(fh,'=======================================================');
    end;

WriteLn(fh,'Uhrzeit: '+FormatDatetime('ddddd t',myLastMessw.Zeit));
WriteLn(fh,'');
WriteLn(fh,format('Streifenbruchteil %s : %.2f %%',[LQInd2Str(myLastMessw.Lichtquelle,true),100*FringeFrac]));
WriteLn(fh,'');
WriteLn(fh,format('Materialtemperatur[%d]: %7.3f °C',[myLastMessw.MTIndex,myLastMessw.MatTemp]));
WriteLn(fh,format('Lufttemperatur[%d]:     %7.3f °C',[myLastMessw.LTIndex,myLastMessw.LuftTemp]));
WriteLn(fh,format('Luftdruck:              %6d Pa',[myLastMessw.Druck]));
WriteLn(fh,format('rel. Feuchte:              %3.1f %%',[myLastMessw.Feuchte]));
WriteLn(fh,format('HMT333 Lufttemperatur:   %4.2f °C (Kontrolle)',[myLastMessw.Temperatur]));
WriteLn(fh,'');
closefile(fh);

SaveFits(MessdatenPfad+messname+'_'+LQInd2Str(myLastMessw.Lichtquelle,false)+'.fit');
btSave.Enabled:=false;
end;

procedure TfrmMain.tmVerlaufTimer(Sender: TObject);
Var i:Integer;
begin
for i:=VERL_MIN+1 to -1 do
  begin
  MTVerl[i]:=MTVerl[i+1];
  LTVerl[i]:=LTVerl[i+1];
  end;

MTVerl[0]:=TPCalWerte[myLastMessw.MTIndex];
LTVerl[0]:=TPCalWerte[myLastMessw.LTIndex+4];
Series1.Clear;
Series2.Clear;
for i:=VERL_MIN+1 to 0 do
  begin
  if MTVerl[i]>0 then Series1.AddXY(i,MTVerl[i]);
  if LTVerl[i]>0 then Series2.AddXY(i,LTVerl[i]);
  end;
end;

procedure TfrmMain.btNewMessClick(Sender: TObject);
begin
// Treumann anfang
//messname:=InputBox('Interferenz','Geben Sie den Messnamen ein!','');
if frmPDaten.ShowModal=mrOK then Beep;
messname:=frmPDaten.edFilename.Text;
myPDat.FileName:=frmPDaten.edFilename.Text;

if messname='' then exit;
edMessname.Text:=messname;
if fileexists(MessdatenPfad+messname+'.txt') then
    Showmessage('Messung wird fortgesetzt!');
btSave.Enabled:=BildDatenLoaded and (Messname<>'');

// umschaltung der Cameras anfang
if frmPDaten.rbINKO1.Checked=true then
begin
  CamSel:=0;
  myPDat.Inko:='INKO1';
end;
if frmPDaten.rbINKO2.Checked=true then
begin
  CamSel:=1;
  myPDat.Inko:='INKO2';
end;
if (CamSel=0) then
begin
  btTakePictureB.Caption:='Bild INKO2 (QE)';
end else
if (CamSel=1) then
begin
  btTakePictureB.Caption:='Bild INKO1 (HiRes)';
end;
SendMessage(Monitorhandle_QE,WM_USER+2,CamSel,0);
// umschaltung der Cameras ende

// Daten ablegen
myPDat.ET_Zahl:=frmPDaten.edETZahl.Text;
myPDat.Pruefer:=frmPDaten.cbPruefer.Text;
myPDat.Bemerkung:=TStringList.Create;
myPDat.Bemerkung.AddStrings(frmPDaten.meBemerkung.Lines);
//myPDat.Bemergung:=frmPDaten.meBemerkung.Lines;
myPDat.Nennlaenge:=frmPDaten.edNennlaenge.Text;
myPDat.Hersteller:=frmPDaten.edHersteller.Text;
myPDat.IdentNr:=frmPDaten.edIdentNr.Text;
myPDat.Material:=frmPDaten.edMaterial.Text;
myPDat.MessmittelNr:=frmPDaten.edMessmittelNr.Text;
myPDat.Platte_Seite:=frmPDaten.cbPlatteSeite.Text;
if frmPDaten.rblinks.Checked=true then myPDat.Messflaeche:='links';
if frmPDaten.rbrechts.Checked=true then myPDat.Messflaeche:='rechts';
// Treumann ende
end;

procedure TfrmMain.SaveFits(Dateiname:string);
Var fitsfile:Integer;

  procedure Write2Header(line:string);
  Var buf:array[0..79] of Char;
      i:Integer;
  begin
  FillChar(buf,80,ord(' '));
  for i:=1 to length(line) do
    buf[i-1]:=line[i];
  fileWrite(fitsfile,buf,80);
  end;
Var i,x,y:Integer;
    Zeile:Array of Byte;
    WordOut:word;
    ende:string;
begin
if not BildDatenLoaded then exit;
if fileexists(Dateiname) then
  raise exception.Create(format('Datei %s existiert schon',[dateiname]));

fitsfile:=FileCreate(Dateiname);

Write2Header('SIMPLE  =                    T');
Write2Header('BITPIX  =                   16');
Write2Header('NAXIS   =                    2');
Write2Header('NAXIS1  =                 1360');
Write2Header('NAXIS2  =                 1024');
Write2Header('BSCALE  =   1.0000000000000000');
Write2Header('DATE-OBS= '''+FormatDatetime('yyyy-mm-dd',myLastMessw.Zeit)+'''');
Write2Header('TIME-OBS= '''+FormatDatetime('hh:nn:ss',myLastMessw.Zeit)+'''');
Write2Header('EXPTIME =   1.0000000000000000'); //?
Write2Header('BZERO   =   32768.000000000000');
Write2Header('END');
for i:=1 to 36-11 do Write2Header('');

SetLength(zeile,1360*2);

for y:=1024-1 downto 0 do
    begin
    for x:=0 to 1360-1 do
        begin
        WordOut:=Word(BildDaten[x,y]+$8000);
        Zeile[x shl 1]:=hi(WordOut);
        Zeile[(x shl 1)+1]:=lo(WordOut);
        end;
    fileWrite(fitsfile,zeile[0],1360*2);
    end;
finalize(zeile);
// 2880 + 1360*1024*2
//padding am schluss
ende:=StringOfChar(#0,2560);
fileWrite(fitsfile,ende[1],2560);

FileClose(fitsfile);
end;


procedure TfrmMain.btInfoClick(Sender: TObject);
begin
FrmInfo.showmodal;
end;

procedure TfrmMain.rgLichtquelleClick(Sender: TObject);
Var tpEn:boolean;
begin
{Treumann anfang}
tpEn:=btTakePictureB.Enabled;
btTakePictureB.Enabled:=false;
SendMessage(MonitorHandle_QE,WM_USER+1,ExpZeiten[rgLichtquelle.ItemIndex],0);
btTakePictureB.Enabled:=tpEn;
{Treumann ende}
end;

function TfrmMain.CalcShiftBits:Integer;
CONST SAMPLES=10000;
Var i:Integer;
    sum,sq,mw,sigma,wert:double;
begin
sum:=0;
sq:=0;
for i:=1 to SAMPLES do
    begin
    wert:=BildDaten[random(bmBild.Width),random(bmBild.Height)];
    sum:=sum+wert;
    sq:=sq+sqr(1.0*wert);
    end;

mw:=sum/SAMPLES;
sigma:=SQRT((SAMPLES*sq-sqr(sum))/(SAMPLES*(SAMPLES-1)));

wert:=mw+2*sigma;

if wert<$100 then result:=0
  else if wert<$200 then result:=1
  else if wert<$400 then result:=2
  else if wert<$800 then result:=3
  else result:=4
end;

procedure TfrmMain.tmLogTimer(Sender: TObject);
begin
WriteLn(fhLog,Format('%s %s : TPCal0=%.3f TPCal1=%.3f TPCal2=%.3f TPCal3=%.3f TPCal4=%.3f TPCal5=%.3f TPCal6=%.3f TPCal7=%.3f TPCal8=%.3f PTB_Druck=%d HMT_RH=%.1f HMT_Temp=%.2f',
          [DateToStr(date),TimeToStr(now),
           TPCalWerte[0],TPCalWerte[1],TPCalWerte[2],TPCalWerte[3],TPCalWerte[4],TPCalWerte[5],TPCalWerte[6],TPCalWerte[7],TPCalWerte[8],
           Druck,Feuchte,Temperatur]));
Flush(fhLog);
end;

{Treumann anfang}
procedure TfrmMain.ChangeCamClick(Sender: TObject);
begin
if (CamSel=0) then
begin
  CamSel:=1;
  btTakePictureB.Caption:='Bild InKoB (QE)';
end else
if (CamSel=1) then
begin
  CamSel:=0;
  btTakePictureB.Caption:='Bild InKoA (HiRes)';
end;
SendMessage(Monitorhandle_QE,WM_USER+2,CamSel,0);
end;
{Treumann ende}

end.

