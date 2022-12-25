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

//������� �������� ������ �� �������
 Recv(_client, _buff, 1024, 0);

//�������� ������ �� ������
 _request:=string(_buff);

//���� �����, �� ������ ������ ������ ������
 if _request='' then
 begin
  CloseSocket(_client);
  exit;
 end;


 //��������� ������, � �������� ����� ����������� ������
 _host:=Copy(_request, Pos('Host: ', _request), 255);
 Delete(_host, Pos(#13, _host), 255);
 Delete(_host, 1, 6);

 //���������� ����. ���� � ��������� �� ������ ����, �� ����������
 //�� ��������� - 80
 _port:=StrToIntDef(Copy(_host, Pos(':', _host)+1, 255), 80);
 Delete(_host, Pos(':', _host), 255);

 //���� �� ������� ���������� �����, �� ������� �������
 if (_host='') then
  begin
   SendStr(_client, 'Error 400: Invalid header');
   CloseSocket(_client);
   exit;
  end;

 //������� � ��� IP �������, � ������ � �������� �� ���������
 Synchronize(addToLog);

 //�������� �����
 _srvSocket := socket(AF_INET, SOCK_STREAM, 0);

 // ���� ������
 _srvAddr.sin_addr.s_addr := htonl(INADDR_ANY);
 _srvAddr.sin_family := AF_INET;
 _srvAddr.sin_port := htons(_port);
 _srvAddr.sin_addr := LookupName(_host);

 //���������� � ��������
 if connect(_srvSocket, _srvAddr, sizeof(_srvAddr))=SOCKET_ERROR then
  begin
   SendStr(_Client, '<h1>Error 404: NOT FOUND</h1>');
   exit;
  end;

 //������������� ������ ����� (����������� �����)
 _opt:=1;
 setsockopt(_srvSocket, IPPROTO_TCP, TCP_NODELAY, @_opt, sizeof(integer));

//���������� ������� ������
 send(_srvSocket, _buff, strlen(_buff), 0);

 while true do
  begin
   FD_ZERO(_fdset);
   FD_SET(_client, _fdset);
   FD_SET(_srvSocket, _fdset);


   if (select(0, @_fdset, nil, nil, nil) < 0) then
    exit;

  //���� ������ ������ �� ������� (�.�. ������ �� ��������� ���),
  //���������� ���������� �� �������
   if (FD_ISSET(_client, _fdset)) then
		begin
			_size := recv(_Client, _buff, sizeof(_buff), 0);

      //���� ������ ��� ������ ���������, �� �����������
      if _size=-1 then break;

			send(_srvSocket, _buff, _size, 0);
			continue;
		end;

  //���� ������ ������ � �������, �� ������ ����� ��������� �� �������
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
//���� ��� ��������� ������� ip, �� ������ ��������������
//��� � ������� ����
 if name[4]='.' then
  _inAddr.s_addr := inet_addr(PChar(name))
 else
  begin
//���� ���������� ���, �� ����� ���������� ��� IP
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
//��������� ������� ����� ������
 _temp :=str+#13+#10;
//��������� _buff
 CopyMemory(@_buff, PChar(_temp), Length(_temp));
//���������� �������
 send(s, _buff, Length(_temp), 0);
end;

end.
