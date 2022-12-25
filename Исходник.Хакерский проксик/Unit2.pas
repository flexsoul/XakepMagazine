unit Unit2;

interface

uses
  Classes, WinSock,  Unit3, Dialogs;


type
  TListenThread = class(TThread)
  private

  protected
    procedure Execute; override;
  public
  end;

implementation



procedure TListenThread.Execute;
var
 _listenSocket, _clientSocket:TSocket;
 _listenAddr, _clientAddr: sockaddr_in;
 _clientThread:TClientThread;
 _size:integer;
begin
 _listenSocket := socket (AF_INET, SOCK_STREAM, 0);

 if (_listenSocket = INVALID_SOCKET) then
 begin
  ShowMessage('Ошибка создания сокета!');
  Exit;
 end;

 _listenAddr.sin_family := AF_INET;
 _listenAddr.sin_port := htons(8080);
 _listenAddr.sin_addr.S_addr := htonl(INADDR_ANY);

 if (Bind(_listenSocket, _listenAddr, sizeof(_listenAddr)))=SOCKET_ERROR then
 begin
  ShowMessage('Ошибка связывания сокета с адресом!');
  Exit;
 end;

 if (Listen(_listenSocket, 4)) = SOCKET_ERROR then
 begin
  ShowMessage('Не могу начать прослушивание!');
  Exit;
 end;

 while true do
 begin
  _size := sizeof(_clientAddr);
//Примаем подключение
  _clientSocket := accept(_listenSocket, @_clientAddr, @_size);

  if (_clientSocket = INVALID_SOCKET) then
  Continue;

//Создаем поток для работы с клиентом
  _clientThread := TClientThread.Create(true);
  _clientThread._Client := _ClientSocket;
//Определяем его IP                                    
  _clientThread._ip := inet_ntoa(_clientAddr.sin_addr);
  _clientThread.Resume;
 end;



end;

end.
