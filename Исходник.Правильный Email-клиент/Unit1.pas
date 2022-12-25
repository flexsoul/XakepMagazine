unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, StdCtrls, WinSock, ImgList;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    FromEdit: TEdit;
    ToEdit: TEdit;
    Label4: TLabel;
    TextMemo: TMemo;
    SendButton: TButton;
    TabSheet3: TTabSheet;
    ConnectPopButton: TButton;
    MailListView: TListView;
    TextMemo2: TMemo;
    Label7: TLabel;
    smtpServerEdit: TEdit;
    Bevel1: TBevel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    popServerEdit: TEdit;
    PopLoginEdit: TEdit;
    PopPassEdit: TEdit;
    TabSheet4: TTabSheet;
    logMemo: TMemo;
    Label13: TLabel;
    smtpPortEdit: TEdit;
    Label14: TLabel;
    popPortEdit: TEdit;
    Label3: TLabel;
    SubjectEdit: TEdit;
    ImageList1: TImageList;
    ReadMail: TButton;
    DisconnectButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure ConnectPopButtonClick(Sender: TObject);
    procedure DisconnectButtonClick(Sender: TObject);
    procedure ReadMailClick(Sender: TObject);
  private
    function lookupname (str:string):TInAddr;
    function CreateSocket (serverAddress:string; port:integer):TSocket;
    function ReadFromSocket (socket:TSocket):String;
    function GetLocalHost:string;
    function SendToSocket (socket:TSocket; str:string):integer;
    procedure AddToLog (event:string);
    procedure SocketsErrors;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _wData:WSAData;
  _server_addr:sockaddr_in;
  _POPsocket:TSocket;
implementation

{$R *.dfm}

{ TForm1 }

function TForm1.lookupname(str: string): TInAddr;
var
  _hostEnt:PHostEnt;
  _inAddr:TInAddr;
begin
  //���� ����� smtp ������� ����������
  if (lowerCase(str)[1] IN ['a'..'z']) OR
      (lowerCase(str)[2] IN ['a'..'z']) then
  begin
  //���������� IP �����
    _hostEnt := getHostByName(pchar(str));
  //������� _inAddr
    FillChar(_inAddr, sizeOf(_inAddr), 0);
    if _hostEnt<>nil then
    begin
      //���� ����� �������, �� �������� ���.
      with _hostEnt^, _inAddr do
      begin
        s_un_b.s_b1 := h_addr^[0];
        s_un_b.s_b2 := h_addr^[1];
        s_un_b.s_b3 := h_addr^[2];
        s_un_b.s_b4 := h_addr^[3];
      end;
    end;
  end
  else
    _inAddr.s_addr := inet_addr(pchar(str));

 Result:= _inAddr;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 if WSAStartup(makeword(1,1), _wData) <> 0 then
 begin
  ShowMessage('������ ��� ������������� WinSock. ����������� ����������');
  Application.Terminate;
 end;

 LogMemo.Lines.Clear;
 AddToLog('��������� ������ � ������!');
end;

procedure TForm1.SocketsErrors;
var
 _errorCode:integer;
 _errorText:string;
begin
  _errorCode:=WSAGetLastError();

  case _errorCode of
    WSANOTINITIALISED: _errorText:=
      '������� ���������� �� ���� ����������������!!! ���������� � ������������';
    WSAENETDOWN: _errorText:=
      '����� �������� - �������� ������ ������� ������';
    WSAEADDRINUSE: _errorText:=
      '��������� �����/���� ��� ������������!!!';
    WSAEINVAL: _errorText:=
      '����� ��� ������ � �������';
    WSAENOBUFS: _errorText:=
      '������� ����� ����������. ���������� ������!';
    WSAENOTSOCK: _errorText:=
      '��������� ���������� ������';
    WSAEISCONN: _errorText:=
      '����� ��� ���������';
    WSAEMFILE: _errorText:=
      '����������� ���������� �����������';
    WSAETIMEDOUT: _errorText:=
      '����� �������� ������ �������';
  end;

 addToLog(_errorText);

end;

procedure TForm1.AddToLog(event: string);
var
 _time:string;
begin
 _time := FormatDateTime('[hh:mm:ss]', now);
 logMemo.Lines.Add(_time+': '+event);
end;

function TForm1.CreateSocket(serverAddress: string; port: integer): TSocket;
var
  _socket:TSocket;
begin
 _socket := Socket(PF_INET, SOCK_STREAM, IPPROTO_IP);
 if _socket = INVALID_SOCKET then
 begin
  Result:=0;
  Exit;
 end;

 _server_addr.sin_family := AF_INET;
 _server_addr.sin_addr.S_addr := htonl (INADDR_ANY);
 _server_addr.sin_port := htons(port);
 _server_addr.sin_addr := lookupname(ServerAddress);
 Result := _socket;
end;



procedure TForm1.SendButtonClick(Sender: TObject);
var
 _Socket:TSocket;
 _str:string;
 I,J:integer;
begin
 PageControl1.ActivePageIndex:=3;
 AddToLog('���������� ������');
 //������� ����� ��� ���������� � smtp �������
 _Socket := CreateSocket(smtpServerEdit.Text, StrToInt(SmtpPortEdit.Text));

 //�������� ��������� �����. ���� ����� 0, �� ������ �������� ������
 if (_Socket = 0) then
 begin
  AddToLog ('������ ��� �������� ������!');
  SocketsErrors();
  Exit;
 end;

 //������� �������������� � smtp �������

 if (Connect(_Socket, _server_addr, sizeOf(_server_addr)) = SOCKET_ERROR) then
 begin
  SocketsErrors();
  Exit;
 end;

 sleep(1000);
 //��������� ����������� �������
 AddToLog(ReadFromSocket(_Socket));

 SendToSocket(_socket, 'HELO '+GetLocalHost);
 sleep(100);
 AddToLog(ReadFromSocket(_Socket));

 SendToSocket(_socket, 'MAIL FROM:<'+FromEdit.Text+'>');
 sleep(100);
 AddToLog(ReadFromSocket(_socket));

 SendToSocket(_socket, 'RCPT TO:<'+ToEdit.Text+'>');
 sleep(100);
 AddToLog(ReadFromSocket(_socket));

 //��������� ��������� ������
 SendToSocket(_socket, 'DATA');
 sleep(100);
 AddToLog(ReadFromSocket(_socket));

 //�� ����
 SendToSocket(_socket, 'From:<'+FromEdit.Text+'>');

 //����
 SendToSocket(_socket, 'To:<'+ToEdit.Text+'>');

 //���� ������
 SendToSocket(_socket, 'Subject: '+SubjectEdit.Text);

 //��������� ������
 SendToSocket(_socket, 'Mime-Version: 1.0'+#13+#10+'Content-Type: text/plain; charset="windows-1251"');

 //��������� �����������
 SendToSocket(_socket, 'X-Mailer: MyMailProgram');

 //����� ������
 For I:=0 to TextMemo.Lines.Count-1 do
 begin
  _str:=TextMemo.Lines.Strings[i];
  while _str<>'' do
  begin
   j:=SendToSocket(_socket, _str);

   if j=SOCKET_ERROR then
    break;

   Delete(_str, 1, j);
  end;
 end;

 sendToSocket(_socket,#13+#10+'.');
 AddToLog(ReadFromSocket(_socket));

 sendToSocket(_socket, 'QUIT');
 AddToLog(ReadFromSocket(_socket));
 CloseSocket(_socket);
end;

function TForm1.ReadFromSocket(socket: TSocket): String;
var
  _buff: array [0..255] of Char;
  _Str:AnsiString;
  _ret:integer;
begin
  fillchar(_buff, sizeof(_buff), 0);
  Result:='';
  _ret := recv(socket, _buff, 1024, 0);
  if _ret = -1 then
  begin
    Result:='';
    Exit;
  end;

  _Str := _buff;
  while pos(#13, _str)>0 do
  begin
    Result := Result+Copy(_str, 1, pos(#13, _str));
    Delete(_str, 1, pos(#13, _Str)+1);
  end;

  Application.ProcessMessages;
end;

function TForm1.SendToSocket(socket: TSocket; str: string):integer;
var
 _buff:array [0..255] of Char;
begin
  result:=0;
  str := str+#13+#10;
  CopyMemory(@_buff, pchar(str), length(str));
  result:=send(socket, _buff, length(str), 0);
  addToLog('> '+Copy(str, 1, length(str)-2));
end;

function TForm1.GetLocalHost: string;
var
 _buff : array [0..255] of char;
begin
 if gethostname(_buff, 255) = 0 then
  Result := StrPas(_buff)
 else
  Result := '';
end;

procedure TForm1.ConnectPopButtonClick(Sender: TObject);
var
  _str:string;
  _countMail:Integer;
  i:integer;
begin
 MailListView.Items.Clear;
 PageControl1.ActivePageIndex:=3;

 AddToLog('���������� ������...');

 _POPsocket:=CreateSocket(popServerEdit.Text, StrToInt(popPortEdit.Text));
  AddToLog('������ ����������� � '+PopServerEdit.Text);

  if (Connect(_POPsocket, _server_addr, sizeOf(_server_addr))) = SOCKET_ERROR Then
  begin
    SocketsErrors();
    Exit;
  End;

  Sleep(100);
  AddToLog(ReadFromSocket(_POPsocket));

  //���������� ��� ������������
  SendToSocket(_POPsocket, 'USER '+popLoginEdit.Text);
  Sleep(100);
  AddToLog(ReadFromSocket(_POPsocket));

  //���������� ������
  SendToSocket(_POPsocket, 'PASS '+popPassEdit.Text);
  Sleep(100);
  AddToLog(ReadFromSocket(_POPsocket));

  //�������� ������ �����
  SendToSocket(_POPsocket, 'LIST');
  Sleep(1000);
  _str := ReadFromSocket(_POPsocket);

  Delete(_str, 1, 4);
  _countMail := StrToInt(Copy(_str, 1, pos(' ', _str)-1));
  Delete(_str, 1, pos(#13, _str));
  

//������������ ������
   while _str[1]<>'.' do
   begin
    with MailListView.Items.Add do
    begin
      Caption := Copy(_str, 1, pos(' ', _str)-1);
      ImageIndex := 0;
      SubItems.Add(Copy (_str, pos(' ', _str)+1, pos(#13, _str)-3));
    end;

    Delete(_str, 1, pos(#13, _str));
   end;

   AddToLog('������� ������ �����. �����: '+IntToStr(_countMail));

end;

procedure TForm1.DisconnectButtonClick(Sender: TObject);
begin
 if _POPSocket>0 then
 begin
  SendToSocket(_popSocket, 'QUIT');
  Sleep(100);
  AddToLog(ReadFromSocket(_POPSocket));
  CloseSocket(_POPSocket);
 end;
end;

procedure TForm1.ReadMailClick(Sender: TObject);
var
 _buff:array [0..256] of Char;
 i, j:integer;
 _tempStr:AnsiString;
 _size:integer;
begin
 if MailListView.Selected = nil then
  Exit;

 _size:=strToInt(MailListView.Selected.SubItems.Strings[0]);
 i:=0;

 AddToLog('������� �������� ������...');

 SendToSocket(_popSocket, 'RETR '+IntToStr(MailListView.Selected.Index+1));
 AddToLog(ReadFromSocket(_popSocket));
 Sleep(1000);

 while i<=_size do
 begin
  if _size-i<256 then
  begin
   fillchar(_buff, sizeof(_buff),#0);
   j:=_size-i+50;
   recv(_popSOcket, _buff, j, 0);

    _tempStr:=_tempStr+_buff;
    Break;
    Exit;
  end;

  fillchar(_buff, length(_buff), #0);
  i := i+recv(_popSocket, _buff, length(_buff), 0);
  _tempStr:=_tempStr+_buff;
 end;

 TextMemo2.Lines.Clear;

 while pos(#13, _tempStr)>0 do
 begin
  TextMemo2.Lines.Add(Copy(_tempStr, 1, pos(#13, _tempStr)));
  Delete (_tempStr, 1, pos(#13, _tempStr)+1);
 end;

 TextMemo2.Lines.Add(_tempStr);
end;

end.
