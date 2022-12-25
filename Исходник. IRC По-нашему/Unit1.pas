unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, WinSock, Menus;

const
   WM_MYMESSAGE = WM_USER+1;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    ServerEdit: TEdit;
    Label2: TLabel;
    PortEdit: TEdit;
    Label3: TLabel;
    NickEdit: TEdit;
    Label4: TLabel;
    ChannelEdit: TEdit;
    logMemo: TMemo;
    ConnectBtn: TButton;
    DisconnectBtn: TButton;
    Label5: TLabel;
    UsersListBox: TListBox;
    Panel2: TPanel;
    MessageEdit: TEdit;
    SendBtn: TButton;
    Button1: TButton;
    Label6: TLabel;
    EmailEdit: TEdit;
    procedure ConnectBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SendBtnClick(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
  private
    function lookupname(s:string): TInAddr;
    procedure ParseCommand(s:string);
    procedure ConnectToIrc(server:string; port:Integer);
    procedure MyMessage(var M:TMessage); message WM_MYMESSAGE;
    procedure SendToSocket(S:TSocket; str:string);
    procedure ReadFromSocket(S:TSocket);
    procedure FormatText(str:string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _wData:WSAData;
 _client_addr: sockaddr_in;
 _client: TSocket;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.ConnectToIrc(server: string; port: Integer);
begin
 _Client := Socket(PF_INET, SOCK_STREAM, IPPROTO_IP);

 if (_Client) = INVALID_SOCKET then
  Exit;

 _client_addr.sin_family := AF_INET;
 _client_addr.sin_addr.S_addr := htonl (INADDR_ANY);
 _client_addr.sin_port := htons (port);
 _client_addr.sin_addr := lookupname(server);

 Connect(_Client, _client_addr, sizeof(_client_addr));


 WSAAsyncSelect(_client, handle, WM_MYMESSAGE, FD_READ);
 SendToSocket(_client, 'NICK '+ NickEdit.Text+'.'+#10);

 SendToSocket(_client, 'USER '+Copy(EmailEdit.Text, 1, pos('@', EmailEdit.Text)-1)+
      ' "'+Copy(EmaiLEdit.Text, pos('@', EmailEdit.Text)+1, length(EmailEdit.Text))+
      '" "'+server+'" : '+NickEdit.Text+#10);

end;


function TForm1.lookupname(s: string): TInAddr;
var
  _hostEnt:PHostEnt;
  _inAddr:TInAddr;
begin
  if (lowerCase(s)[1] IN ['a'..'z']) OR
      (lowerCase(s)[2] IN ['a'..'z']) then
  begin
    _hostEnt := getHostByName(pchar(s));
    FillChar(_inAddr, sizeOf(_inAddr), 0);
    if _hostEnt<>nil then
    begin
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
   _inAddr.s_addr := inet_addr(pchar(s));

 Result:= _inAddr;
end;

procedure TForm1.ConnectBtnClick(Sender: TObject);
begin
 ConnectToIrc(ServerEdit.Text, StrToInt(PortEdit.Text));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 if WSAStartup(makeword(1,1), _wData) <> 0 then
 begin
  ShowMessage('Ошибка при инициализации WinSock. Продолжение невозможно');
  Application.Terminate;
 end;
end;

procedure TForm1.MyMessage(var M: TMessage);
begin
 case M.LParam of
  FD_READ: readFromSocket(M.WParam);
  FD_CLOSE: CloseSocket(M.WParam);
 end;
end;

procedure TForm1.ReadFromSocket(S: TSocket);
var
 _buff:array[0..5000] of Char;
 _str:string;
begin
 FillChar(_buff, sizeOf(_buff), 0);


 if (Recv(S, _buff, sizeof(_buff), 0) = SOCKET_ERROR) then
  Exit;

 _str := _buff;

 while pos(#13, _str) > 0 do
 begin
  ParseCommand(Copy(_str, 1, pos(#13, _str)));
  Delete(_str, 1, pos(#13, _str));
 end;
end;

procedure TForm1.SendToSocket(S: TSocket; str: string);
var
 _buff: array [0..1024] of Char;
begin
 CopyMemory(@_buff, pchar(str), length(str));

 Send(s, _buff, length(str), 0);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 UsersListBox.Items.Clear;
 SendToSocket(_Client, 'JOIN '+ChannelEdit.Text+#10);
end;

procedure TForm1.FormatText(str: string);
begin
 while pos(#13, str) > 0 do
 begin
  LogMemo.Lines.Add(Copy(str, 1, pos(#13, str)));
  Delete(str, 1, pos(#13, str)+1);
 end;
end;

procedure TForm1.ParseCommand(s: string);
var
 _command:string;
 _senderNick:string;
 _senderMess:string;
 _user:string;
 i:integer;
begin
 if (pos('PRIVMSG', s)>0) then
 begin
  _senderNick := Copy(s, 2, pos('!', s)-2);
  Delete(s, 1, 1);

  _senderMess := COpy(s, pos(':', s)+1, length(s));
  LogMemo.Lines.Add('<'+_SenderNick+'> '+_SenderMess);
  Exit;
 End;

 if (pos('NOTICE', s)>0) then
 begin
  FormatText(copy(s, pos('***', s), length(s)-2));
  Exit;
 End;

 _command := copy(s, Pos(' ', s)+1, 3);

 if (_command = '001') or (_command = '002') or (_command = '003')
  or (_command = '004') or (_command = '005') then
 begin
    Delete(s, 1, pos(_command, s));
    FormatText(copy(s, pos(':', s)+1, length(s)));
    Exit;
 end;

//Информация
 if (_command = '251') or (_command = '252') or
  (_command = '254') or (_command = '255') or
  (_command = '265') or (_command = '266') or
  (_command = '372')  then
 begin
  Delete(s, 1, pos(_command, s));
  FormatText(copy(s, pos(':', s)+1, length(s)));
  Exit;
 end;

 //Список юзеров на канале
 if (_command = '353') then
 begin
  Delete(s, 1, pos(_command, s));
  Delete(s, 1, pos(':', s));

  while pos(' ', s)>0 do
  begin
    UsersListBox.Items.Add(Copy(s, 1, pos(' ', s)-1));
    Delete(s, 1, pos(' ', s));
  end;
  Exit;
 end;

 if (pos('JOIN', s)>0) then
 begin
  _user := Copy(s, 2, pos('!', s)-2);

  if _user = NickEdit.Text then Exit;

  LogMemo.Lines.add('К нам присоединился: '+_user);
  UsersListBox.Items.Add(_user);
  Exit;
 end;

 if (pos('PART', s)>0) then
 begin
  _user := Copy(s, 2, pos('!', s)-2);

  if (_user = NickEdit.Text) then Exit;
  logMemo.Lines.add('Пользователь: '+_user+' покинул канал');

  for I:=0 to UsersListBox.Items.Count-1 do
   if (_user=UsersListBox.Items.Strings[i]) then
    UsersListBox.Items.Delete(i);
  Exit;
 end;

end;

procedure TForm1.SendBtnClick(Sender: TObject);
begin
 SendToSocket(_client, 'PRIVMSG '+ChannelEdit.Text+' :'+MessageEdit.Text+#10);
 LogMemo.Lines.Add('<'+NickEdit.Text+'> '+MessageEdit.Text);
 MessageEdit.Text:='';
end;


procedure TForm1.DisconnectBtnClick(Sender: TObject);
begin
 CloseSocket(_Client);
 UsersListBox.Items.Clear;
end;

end.
