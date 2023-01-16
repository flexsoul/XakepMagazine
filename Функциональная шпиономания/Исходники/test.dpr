library project1;

uses
  Windows,
  advApiHook,
  Messages,
  SysUtils;

type
  TSocket=integer;
  TSendProcedure=function (s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;


var
  _pOldSend: TSendProcedure;
  _hinst, _h:integer;


Procedure SendData(data:string; funcType:integer; Buff:pointer; len:integer);
var
 d:TCopyDataStruct;
begin
 case funcType of
  10:
   begin
     d.lpData := Buff;
     d.cbData := len;
     d.dwData := 10;
   end;
  30:
    begin
      d.lpData := pchar(data);
      d.cbData := length(data);
      d.dwData := 30;
    end;
 end;
 SendMessage(_h, WM_COPYDATA, 0, LongInt(@d));
End;


function xSend(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
begin
  SendData('', 10, addr(string(buf)), len);
  result:=_pOldSend(s,buf,len,flags);
end;

procedure DLLEntryPoint(dwReason: DWord);
begin
   case dwReason of
    DLL_PROCESS_ATTACH:
      begin
        SendData('Библиотека загружена. Начинается подготовка к перехвату...', 30, nil, 0);
        _hinst:=GetModuleHandle(nil);
        StopThreads;
        HookProc('WS2_32.dll','send',@xSend,@_pOldSend);
        SendData('Подмена функций завершилась успехом!', 30, nil, 0);
        RunThreads;
      end;

    DLL_PROCESS_DETACH:
       begin
         SendData('Снимаем перехват...', 30, nil, 0);
         UnhookCode(@_pOldsend);
      end;
   end;
end;


begin
  _h:=findwindow(nil,'WinSock Sniffer');
  if (_h = 0) then
  begin
    MessageBox(0, 'Не найдено окно клиентской части программы!', 'Ошибка!', 0);
    ExitThread(0);
  end;
  DllProc := @DLLEntryPoint;
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.
