unit Unit2;

interface

uses
  Classes, WinSock;

type
  Tftpserv = class(TThread)
  private
     { Private declarations }
  protected
    procedure Execute; override;
  public
    _socket:TSocket;
  end;

implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure Tftpserv.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ Tftpserv }
uses
  Unit1;

procedure Tftpserv.Execute;
var
 sRecvBuff, sSendBuff : array [0..1024] of char;
 ret:Integer;
 s:String;
begin
 while(true) do
  begin
   ret := recv(_socket, sRecvBuff, 1024, 0);
   if (ret = 0) then
    Break;

   s:=sRecvBuff;
  // Form1.FormatStr(s, Form1.RichEdit2);
 end;

 CloseSocket(_socket);
 Terminate;

end;

end.
 