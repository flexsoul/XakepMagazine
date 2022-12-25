unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ComCtrls, WinSock, ExtCtrls, Unit2;


  const
    WM_MYSOCKMESS = WM_USER+1;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    LIST1: TMenuItem;
    CWD1: TMenuItem;
    RichEdit1: TRichEdit;
    procedure N2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure LIST1Click(Sender: TObject);
    procedure CWD1Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
  private
    _wsaData:TWSADATA;
    _clientSocket:TSocket;
    _serverSocket:TSocket;
    _clientAddr:sockaddr_in;
    _serverAddr:sockaddr_in;
    _tempSocket:TSocket;
    procedure GetError(function_name:string);
    procedure _Recv(s:TSocket);
    procedure _Send(s:TSocket; ftp_command:string);
    procedure _Connect(ftp_server:string; ftp_port:string;
        user_name:string; user_pass:string);
    procedure NetMSG (var M:TMessage); message WM_MYSOCKMESS;
    function CreateListenSocket:integer;
    function getmyipadress:string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Unit3;

{$R *.dfm}

{ TForm1 }

procedure TForm1.GetError(function_name: string);
var
  _strErrorName:string;
  _codeError:Integer;
begin
 _strErrorName:='����������� ������';
 _codeError:=WSAGetLastError();

 case _codeError of
   WSANOTINITIALISED:_strErrorName:=
      '������� ���������� �� ����������������';
   WSAENETDOWN:_strErrorName:=
      '�������� �����. ��������� ���������� � ������';
   WSAEADDRINUSE:_strErrorName:=
      '����� ��� ������������';
   WSAEFAULT:_strErrorName:=
      '�������� ������� namelen �� ������������� ��������� ���������';
   WSAEINPROGRESS:_strErrorName:=
      '��� ���� ��������, ������� ����������� � ����������� ������. ����� ��������� �� ����������';
   WSAEINVAL:_strErrorName:=
      '����� ��� ������ � �������';
   WSAENOBUFS:_strErrorName:=
      '������������ �������, ������� ����� ����������';
   WSAENOTSOCK:_strErrorName:=
      '�������� ���������� ������';
   WSAEISCONN:_strErrorName:=
      '����� ��� ���������';
   WSAEMFILE:_strErrorName:=
      '������ ��� ��������� ������������';
   
 end;

 RichEdit1.SelAttributes.Color:=clBlue;
 RichEdit1.SelAttributes.Size:=10;

 RichEdit1.Lines.Add('��������� ������ � ������� '+function_name+' '+
                  _strErrorName);
end;


{ ��������� ������������� ���������� � ��������� FTP �������� }
procedure TForm1._Connect(ftp_server, ftp_port, user_name,
  user_pass: string);
begin
//������� ����� �����
  _clientsocket:=SOCKET(AF_INET, SOCK_STREAM, IPPROTO_IP);
//��������, ���� �������� ������, ��
//��������� �������� ��� ������ � � ����� ������ �������
//�� ���������
 if _clientSocket=INVALID_SOCKET then
 begin
  GetError('Socket');
  Exit;
 end;

//�������� ��������� ���������
//��������� ��������� ����������
 _clientAddr.sin_family:=AF_INET;
//��������� ����� ���������� �������
 _clientAddr.sin_addr.S_addr:=inet_addr(pchar(ftp_server));
//��������� ����
 _clientAddr.sin_port:=htons(StrToInt(ftp_port));

//��������� ����� � ����������� �����. ������������� ���������� ��
//��������� FD_READ (�������� ������)
 WSAAsyncSelect(_clientSocket, handle, WM_MYSOCKMESS, FD_READ);
//�������� ���������� �����������. ��� �������� �����, � �� ����� ��� ��������,
//� �������� ���������� ��� ������ ����������
 Connect(_clientsocket, _clientaddr, sizeof(_clientaddr));
//�������� �������
 Sleep(100);
//�� �������� ���������� ������ ���� ��� �����������, �������,
//��� ����� ���������� ������
//� �������� ������ �� ����� ���������� ������ ����� ������� ������
//������� �������� ������� USER + ��� �����
 _send(_clientsocket, 'USER '+user_name);
//������ �������� ������. � �������� FTP �������, ����� ��������� ����� �������
//����� ��������� �����. ��������� � ����� ������� ����� ������ �� RFC 959
 _send(_clientsocket, 'PASS '+user_pass);
//etc
 _send(_clientSocket, 'FEAT');

end;

{ ��������� ��������� ����� ������ }
procedure TForm1._Recv(s: TSocket);
var
  _buff:array[0..5000] of char;
  _str:string;
begin
//������� �����
 Fillchar(_buff, sizeof(_buff), 0);
//������� �������� ������,
//���� ��������� ������, �� ������� �������� �� ��� � ����� ������ �� ���������
 if recv(s, _buff, sizeof(_buff), 0)=SOCKET_ERROR then
 begin
  GetError('recv');
  Exit;
 end;
//�������� � _str ��������� � _buff ������
 _str:=_buff;

//��� ����� ������� ����� ��������� ������ �� FTP �������
 if pos('221', _str)>0 then
 begin
//���������� �������� � ����������� ����������
   ShutDown(s, SD_BOTH);
//��������� �����
   CloseSocket(s);
 end;

//��������� ���������� ������
//���� ������ ����� ������
//���� �������, �� �������� ����� ������ �� ���� � ���������
//� RichEdit
 while pos(#13, _str)>0 do
 begin
  RichEdit1.Lines.Add(copy(_str, 1, pos(#13, _str)));
//�� ����� ������� ��� �������� - �������
  Delete(_str, 1, pos(#13, _str)+1);
 end;
end;

{ ��������� ���������� ������ ����� ���������� � �������� ��������� ����� }
procedure TForm1._Send(s: TSocket; ftp_command:string);
var
 _buff: array [0..1024] of Char;
begin
//� ������ ���������� FTP ������� ��������� ������� ����� ������
// � �������� �������
 ftp_command:=ftp_command+#13#10;
//�������� � _buff ������ ��� �������� �� _str
 CopyMemory(@_buff, pchar(ftp_command), length(ftp_command));
//��� ������, ������ ������� ��������� ��������. � ����� ������ ��������� ������
 if send(s, _buff, length(ftp_command),0)=SOCKET_ERROR then
 begin
  GetError('SEND');
  Exit;
 end;
end;

{ ���������� ������� ������� �� ������ }
procedure TForm1.N2Click(Sender: TObject);
begin
//�������� ������� _Connect
//��� ������� ����
 _connect(Form3.SrvEdit.Text, Form3.Edit1.Text, Form3.LoginEdit.Text, Form3.PassEdit.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//�������������� ������� ���������� WinSock ������ 1.1.
 if WSAStartup(MAKEWORD(1,1), _wsadata)<>0 then
 begin
//��� ������������� ������ ���������� ���������
//� ��������� ���� ����������
  ShowMessage('������ �������� WinSock');
  Application.Terminate;
 end;
end;

{ ��������� ������������� ��������� WM_MYSOCKMESS }
//��� ��������� �������� � ��� ������, ����� �� ������������
//������ ��������� �����-���� (�� ������������ ����) �������
procedure TForm1.NetMSG(var M: TMessage);
begin
//� ��������� m, ��������� TMessage
//���������� ��� �������
//� ������� ����������� ��������� �� ��� � ���������
   case m.LParam of
//��� ������� �� ��������� ��� ������������ ������ ��� �������� ������
//���� � ������� �� ����������� � ���������� ���� �����-������� ���� ������,
//�� �� ��������� �����������. ����� �����, �� ������ ������������ ������
//� �������� ����� _tempSocket
    FD_ACCEPT:
    begin
      _tempSocket:=accept(m.WParam, nil, nil);
//��������� ��� ����� ��������� ������ ������� ������ �� ����� ����������
//�������� ������, �� ��������� socket � ����������� ����� � �������������
//���������� �� ��������� FD_READ (��� �������� ��� ��� �� �������) � FD_CLOSE
//(���������� � ������ ���������� �������)
      WSAAsyncSelect(_tempSocket, handle, WM_MYSOCKMESS, FD_READ+FD_CLOSE);
    end;
//����� �� ������ �� �������, �������� �� ����� � �������
//��������� _recv
    FD_READ:  _recv(m.WParam);
//���� ������ "����", �� ��������� �����
    FD_CLOSE: CloseSocket(M.WParam);
   end;

end;

procedure TForm1.N3Click(Sender: TObject);
begin
//�������� �������� ������� QUIT,
//������� ��������������� � ���������� ����������
 _send(_clientSocket, 'QUIT');
end;

{ ������� ������� ����� �����, ������� ����� ������� �����������
 ������� ��� �������� ������ (���������� �������� ������ }
function TForm1.CreateListenSocket:Integer;
var
  _len, _val:integer;
begin
//����������� ���������� ������� ����� ����� �����,
//������� ����� ������ ��� �����������
 Result:=0;
//������� �����
 _serverSocket:=Socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
//���� ��� �������� ������ �������� ������, �� �������
 if _serverSocket=INVALID_SOCKET then
 begin
  GetError('Socket');
  Exit;
 end;
//������� ������ ��������� _serverAddr. � ����������� ��� ��� �����������
//��� ��������� ���������� � ������, � ��������� ��� ����������� �����,
//������� ������� ���� ���������
 _len:=sizeof(_serverAddr);

//������� setsockopt ������������� ��� ����������� ������ �����
//� �������� ������� ��������� ����� ������� �����, �������� �� ����� �������������
//�����
//������ ��������: �������. ����� ������ SOL_SOCKET ��� IPPROTO_TCP
//������ �������� ������� �� �������. � ����� ������ �� ��������� SO_REUSEADDR
//������� ������� � ���, ��� �� ����� ����� ������� �����, ����� �� ��� ��������� ������.
//����� �������� �����, �� ��� ����� ��������� ������ � ������. Windows ���� ��� ������� ���.
 setsockopt(_serversocket, SOL_SOCKET,SO_REUSEADDR, @_val, _len);
//������� ���� ���������
 FillChar(_serveraddr, sizeof(_serveraddr), 0);
//��������� ��������� ����������
 _serveraddr.sin_family:=AF_INET;
//��������� ��� �����.
 _serveraddr.sin_addr.S_addr:=htonl(INADDR_ANY);
//� �������� ����� ������ 0. � ���� ������ ������� ���� ���
//����������� ��������� ����. ����� ������� ����� ���� ���������, ��� �������
//���������� �� ����������
 _serveraddr.sin_port:=0;

//�������� ��� ����� � ��������� �������� ������
 if bind(_serverSocket, _serverAddr, sizeof(_serveraddr))=SOCKET_ERROR then
 begin
  GetError('BIND');
  Exit;
 end;

//�������� ���������� � ������
 GetSockName(_serverSocket, _serverAddr, _len);

 //��� ��������
 WSAAsyncSelect(_serversocket, handle, WM_MYSOCKMESS, FD_ACCEPT+FD_CLOSE);

//�������� ������������
 if Listen(_serversocket, 10)=SOCKET_ERROR then
 begin
  GetError('LISTEN');
  Exit;
 end;
//� ��������� ������������� ����� ��������������� �������� �����.
 Result:=ntohs(_serveraddr.sin_port);
end;

procedure TForm1.LIST1Click(Sender: TObject);
var
 _ip:string;
 _port:integer;
begin
//������ �� � ��� ��������� �����
//������ ���������, ������� ��� ������� �������� �� ���-������
//������ :)))
 if _serverSocket>0 then
  CloseSocket(_serverSocket);
//������� �����, � �������� ����� ����� �������������� ��������� ������
//��� �������� ������ - ������ ������
 _port:=CreateListenSocket;
//��������� ��� IP �����. ������� ������� ����
 _ip:=GetMyIPadress;
//����������� ��� IP ����� � ����������� Rfc 959
 _ip:=StringReplace(_ip,'.',',', [rfReplaceall]);
//��������� ���� � �� ������
 _ip:=_ip+','+intToStr(_port div 256)+','+intToStr(_port mod 256);
//���������� �������, ������� ������� � ����������� ���������� ��� �������� ������
 _send(_clientSocket, 'PORT '+_ip);
//������ ������ �� ��������� ������
 _send(_clientSocket, 'LIST');
end;

{ ������� ���������� ��������� IP ����� }
function TForm1.getmyipadress: string;
var
  _host:PHostEnt;
  _buf:array[0..127] of char;
begin
  result:='';
//������� ��������� ��� ������ ����������
  if gethostname(_buf, 128)<>SOCKET_ERROR then
  begin
//������ ��������� IP �� ����� �����
    _host:=GetHostByName(_buf);
    if _host<>nil then
      Result:=inet_ntoa(PinAddr(_host^.h_addr_list^)^);
  end;

end;

procedure TForm1.CWD1Click(Sender: TObject);
var
  _command:string;
begin
 if not inputquery('������� � �����','��� �����', _command) then
  Exit;
 _send(_clientsocket, 'CWD '+_command);
end;

procedure TForm1.N5Click(Sender: TObject);
begin
 Form3.ShowModal;
end;

end.
