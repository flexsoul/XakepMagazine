unit Unit3;

interface

uses
  Classes,  Winsock, SysUtils, Windows;

type
  TClientThread = class(TThread)
  private
    procedure SendStr (s:TSocket; str:string);
    procedure AddToLog;
    function LookupName(name:string):TInAddr;
    { Private declarations }
  protected
    procedure Execute; override;
  public
    _client:TSocket;
    _ip:string;
    _host:string;
  end;

implementation

uses
 Unit1;


procedure TClientThread.AddToLog;
begin
 with (Form1.ListView1.Items.Add) do
 begin
  Caption := _ip;
  SubItems.Add(_host);
  SubItems.Add(FormatDateTime('dd.MM.yyyy hh:mm:ss', now));
 end;
end;


procedure TClientThread.Execute;
var
 _buff: array [0..1024] of char;
 _port: integer;
 _request:string;
 _srvAddr : sockaddr_in;
 _srvSocket : TSocket;
 _opt, _size : Integer;
 _fdset : TFDSET;
begin

//Пробуем получить данные от клиента
 Recv(_client, _buff, 1024, 0);

//Копируем запрос из буфера
 _request:=string(_buff);

//если пусто, то значит дальше делать нечего
 if _request='' then
 begin
  CloseSocket(_client);
  exit;
 end;


 //Определим сервер, с которого будем запрашивать данные
 _host:=Copy(_request, Pos('Host: ', _request), 255);
 Delete(_host, Pos(#13, _host), 255);
 Delete(_host, 1, 6);

 //Определяем порт. Если в заголовке не указан порт, то используем
 //по умолчанию - 80
 _port:=StrToIntDef(Copy(_host, Pos(':', _host)+1, 255), 80);
 Delete(_host, Pos(':', _host), 255);

 //Если не удалось определить адрес, то сообщим клиенту
 if (_host='') then
  begin
   SendStr(_client, 'Error 400: Invalid header');
   CloseSocket(_client);
   exit;
  end;

 //Запишим в лог IP клиента, и ресурс к которому он обращался
 Synchronize(addToLog);

 //Созданим сокет
 _srvSocket := socket(AF_INET, SOCK_STREAM, 0);

 // Ищем сервер
 _srvAddr.sin_addr.s_addr := htonl(INADDR_ANY);
 _srvAddr.sin_family := AF_INET;
 _srvAddr.sin_port := htons(_port);
 _srvAddr.sin_addr := LookupName(_host);

 //Соединение с сервером
 if connect(_srvSocket, _srvAddr, sizeof(_srvAddr))=SOCKET_ERROR then
  begin
   SendStr(_Client, '<h1>Error 404: NOT FOUND</h1>');
   exit;
  end;

 //Устанавливаем сокету опции (асинхронный режим)
 _opt:=1;
 setsockopt(_srvSocket, IPPROTO_TCP, TCP_NODELAY, @_opt, sizeof(integer));

//Отправляем серверу запрос
 send(_srvSocket, _buff, strlen(_buff), 0);

 while true do
  begin
   FD_ZERO(_fdset);
   FD_SET(_client, _fdset);
   FD_SET(_srvSocket, _fdset);


   if (select(0, @_fdset, nil, nil, nil) < 0) then
    exit;

  //Если пришли данные от клиента (т.е. запрос на получение док),
  //немедленно отправляем их серверу
   if (FD_ISSET(_client, _fdset)) then
		begin
			_size := recv(_Client, _buff, sizeof(_buff), 0);

      //Если данные для приема кончились, то остановимся
      if _size=-1 then break;

			send(_srvSocket, _buff, _size, 0);
			continue;
		end;

  //Если данные пришли с сервера, то значит нужно отправить их клиенту
   if(FD_ISSET(_srvSocket, _fdset)) then
		begin
			_size := recv(_srvSocket, _buff, sizeof(_buff), 0);

      if _size=0 then
       exit;

			Send(_client, _buff, _size, 0);
			continue;
		end;
  end;

 CloseSocket(_client);
 CloseSocket(_srvSocket);
end;



function TClientThread.LookupName(name: string): TInAddr;
var
 _hostent: PHostEnt;
 _inAddr: TInAddr;
begin
//Если нам подсунули обычный ip, то просто преобразовывем
//его к нужному виду
 if name[4]='.' then
  _inAddr.s_addr := inet_addr(PChar(name))
 else
  begin
//Если символьное имя, то тогда определяем его IP
  _hostent := gethostbyname(PChar(name));
  FillChar(_inAddr, SizeOf(_inAddr), 0);
  if _hostent <> nil then
   begin
    with _inAddr, _hostent^ do
     begin
      S_un_b.s_b1 := h_addr^[0];
      S_un_b.s_b2 := h_addr^[1];
      S_un_b.s_b3 := h_addr^[2];
      S_un_b.s_b4 := h_addr^[3];
     end;
   end
  end;
  Result := _inAddr;
end;

procedure TClientThread.SendStr(s: TSocket; str: string);
var
 _buff: array [0..255] of char;
 _temp: AnsiString;
begin
//Добавляем символы конца строка
 _temp :=str+#13+#10;
//Заполняем _buff
 CopyMemory(@_buff, PChar(_temp), Length(_temp));
//отправляем серверу
 send(s, _buff, Length(_temp), 0);
end;

end.
