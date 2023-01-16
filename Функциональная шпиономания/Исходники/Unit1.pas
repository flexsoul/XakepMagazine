unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ImgList, ToolWin, TlHelp32, advApiHook;


type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    RefreshBtn: TToolButton;
    InjectBtn: TToolButton;
    ImageList1: TImageList;
    lvProcessList: TListView;
    Splitter1: TSplitter;
    reLog: TRichEdit;
    procedure FormCreate(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure InjectBtnClick(Sender: TObject);
  private
    procedure GetAllProcess();
    procedure EnabledBtn(state:Boolean);
    procedure WMCopyData (var Msg:TWMCopyData); message WM_COPYDATA;
    function  EnableDebugPrivilege():Boolean;

    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }


//--------Метод получает список всех процессов-----------//
procedure TForm1.GetAllProcess;
var
  _SnapList  : THandle;
  _ProcEntry : TProcessEntry32;
begin
  If NOT (EnableDebugPrivilege()) Then
  begin
    reLog.SelAttributes.Color := clMaroon;
    reLog.Lines.Add('Не удалось получить привилегии отладчика!');
  End;

  lvProcessList.Items.Clear;
  _ProcEntry.dwSize := SizeOf(TProcessEntry32);
  _SnapList := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS  , 0);

  If (Process32First(_SnapList, _ProcEntry)) Then
  begin
    Repeat
      with lvProcessList.Items.Add Do
      begin
        Caption := IntToStr(_ProcEntry.th32ProcessID);
        SubItems.Add(ExtractFileName(_ProcEntry.szExeFile));
      end;
    Until not (Process32Next(_SnapList, _ProcEntry));
  end;
  CloseHandle(_SnapList);
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
 GetAllProcess();
 reLog.Lines.Clear;
 EnabledBtn(true);
end;

procedure TForm1.RefreshBtnClick(Sender: TObject);
begin
 GetAllProcess();
end;

procedure TForm1.InjectBtnClick(Sender: TObject);
var
  _h:Thandle;
  _dllPath:string;
begin
 If (lvProcessList.Selected = NIL) then
  Exit;

 If (lvProcessList.Selected.Caption = '0') then
 begin
  Application.MessageBox('У процесса недоступен Handle, внедрить библиотеку не получится!',
                'Внимание!', MB_ICONINFORMATION);
  Exit;
 end;

 reLog.Clear;

 _h := OpenProcess(PROCESS_ALL_ACCESS, false, StrToInt(lvProcessList.Selected.Caption));
 _dllPath := ExtractFilePath(ParamStr(0))+'test.dll';

 InjectDll(_h, pchar(_dllPath));
end;

//---------------------Процедура управляет состоянием кнопок--------------//
procedure TForm1.EnabledBtn(state: Boolean);
begin
 RefreshBtn.Enabled  := state;
 InjectBtn.Enabled   := state;
end;

//---------------------Метод получает привилегии отладчика---------------//
function TForm1.EnableDebugPrivilege: Boolean;
var
 hToken: dword;
 SeDebugNameValue: Int64;
 tkp: TOKEN_PRIVILEGES;
 ReturnLength: dword;
begin
 Result:=false;
 OpenProcessToken(INVALID_HANDLE_VALUE, TOKEN_ADJUST_PRIVILEGES
                  or TOKEN_QUERY, hToken);
 if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', SeDebugNameValue) then
  begin
   CloseHandle(hToken);
   exit;
  end;
 tkp.PrivilegeCount := 1;
 tkp.Privileges[0].Luid := SeDebugNameValue;
 tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
 AdjustTokenPrivileges(hToken, false, tkp, SizeOf(TOKEN_PRIVILEGES),
                       tkp, ReturnLength);
 if GetLastError() <> ERROR_SUCCESS then exit;
 Result:=true;
end;


//-----------------------Получаем данные от внедренной dll--------------------//
procedure TForm1.WMCopyData(var MSG: TWMCopyData);
var
 _data:TCopyDataStruct;
 _str:string;
 _funcType: Integer;
 _funcName: string;
begin
 _funcName := '';
 _funcType := Msg.CopyDataStruct.dwData;

 case _funcType of
  10 : _funcName := 'SEND';
  30 : _funcName := 'Информационное сообщение';
 end;

 SetString(_str,PChar(Msg.CopyDataStruct.lpData),Msg.CopyDataStruct.cbData);

 If (Pos(#10, _str) > 0) then
  Delete(_str, pos(#10, _str), 1);

 reLog.Lines.Add(_funcName+': '+_str);
end;

end.
