unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, ImgList, Registry, IniFiles, WinSock, Unit2;

type
  TForm1 = class(TForm)
    ListView1: TListView;
    ImageList1: TImageList;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    StatusBar1: TStatusBar;
    procedure ToolButton4Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
  private
    _listenThread:TListenThread;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ToolButton4Click(Sender: TObject);
var
 _reg:TRegIniFile;
begin
 _reg := TRegIniFile.Create('Software\Microsoft\Windows\CurrentVersion\Internet Settings');
 _reg.WriteString('','ProxyServer', '127.0.0.1:8080');
 _reg.WriteBool('', 'ProxyEnable', true);
 _reg.Free;
 ShowMessage('IE для текущего пользователя сконфигурирован!');
end;

procedure TForm1.ToolButton5Click(Sender: TObject);
var
 _reg:TRegIniFile;
 _ini:TIniFile;
 _AppData:string;
begin
 _AppData := '';
 _reg := TRegIniFile.Create('Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders');
 _AppData := _reg.ReadString('', 'AppData', '');

 if not (DirectoryExists(_AppData)) then
 begin
  ShowMessage ('Не получилось определить папку');
  Exit;
 end;


 _AppData := _AppData+'\Opera\Opera\Profile\opera6.ini';

 if not (FileExists(_AppData)) then
 begin
  ShowMessage('Не найден конфигурационный файл!');
  Exit;
 end;
 
 _ini := TIniFile.Create(_AppData);
 _ini.WriteBool('Proxy', 'Use HTTP', true);
 _ini.WriteString('Proxy', 'HTTP Server','127.0.0.1:8080');

 _reg.Free;
 _ini.Free;

 ShowMessage('Opera сконфигурирована!');
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 _WSAData: WSAData;
begin
 if (WSAStartup(makeword(1,1), _WSAData))<>0 then
 begin
  ShowMessage('Произошла ошибка при инициализации WinSock!');
  Exit;
 end;
end;

procedure TForm1.ToolButton1Click(Sender: TObject);
begin
 _listenThread := TListenThread.Create(false);
 StatusBar1.Panels.Items[0].Text := 'Проксик запущен на порту 8080';
end;


end.
