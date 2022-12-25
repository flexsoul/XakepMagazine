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
 _strErrorName:='Неизвестная ошибка';
 _codeError:=WSAGetLastError();

 case _codeError of
   WSANOTINITIALISED:_strErrorName:=
      'Сетевая библиотека не инициализорована';
   WSAENETDOWN:_strErrorName:=
      'Нарушена связь. Проверьте соединение с инетом';
   WSAEADDRINUSE:_strErrorName:=
      'Адрес уже используется';
   WSAEFAULT:_strErrorName:=
      'Параметр функции namelen не соответствует выбранной адресации';
   WSAEINPROGRESS:_strErrorName:=
      'Уже есть операция, которая выполняется в блокирующем режиме. Нужно дождаться ее завершения';
   WSAEINVAL:_strErrorName:=
      'Сокет уже связан с адресом';
   WSAENOBUFS:_strErrorName:=
      'Недостаточно буффера, слишком много соединений';
   WSAENOTSOCK:_strErrorName:=
      'Неверный дискриптор сокета';
   WSAEISCONN:_strErrorName:=
      'Сокет уже подключен';
   WSAEMFILE:_strErrorName:=
      'Больше нет доступных дискрипторов';
   
 end;

 RichEdit1.SelAttributes.Color:=clBlue;
 RichEdit1.SelAttributes.Size:=10;

 RichEdit1.Lines.Add('Произошла ошибка в функции '+function_name+' '+
                  _strErrorName);
end;


{ Процедура устанавливает соединение с удаленным FTP сервером }
procedure TForm1._Connect(ftp_server, ftp_port, user_name,
  user_pass: string);
begin
//Создаем новый сокет
  _clientsocket:=SOCKET(AF_INET, SOCK_STREAM, IPPROTO_IP);
//Проверим, если возникла ошибка, то
//попробуем получить код ошибки и в любом случае выходим
//из процедуры
 if _clientSocket=INVALID_SOCKET then
 begin
  GetError('Socket');
  Exit;
 end;

//Начинаем заполнять структуру
//Указываем семейство протоколов
 _clientAddr.sin_family:=AF_INET;
//Указываем адрес удаленного сервера
 _clientAddr.sin_addr.S_addr:=inet_addr(pchar(ftp_server));
//Указываем порт
 _clientAddr.sin_port:=htons(StrToInt(ftp_port));

//Переводим сокет в асинхронный режим. Устанавливаем наблюдение за
//событиями FD_READ (прибытие данных)
 WSAAsyncSelect(_clientSocket, handle, WM_MYSOCKMESS, FD_READ);
//Попробую установить соединенние. Для экономии места, я не делаю код проверки,
//в реальном приложении это делать необходимо
 Connect(_clientsocket, _clientaddr, sizeof(_clientaddr));
//подождем немного
 Sleep(100);
//По хорошему соединение должно было уже установится, поэтому,
//нам можно отправлять данные
//В качестве данных мы будем отправлять данные нашей учетной записи
//Сначала отправим команду USER + наш логин
 _send(_clientsocket, 'USER '+user_name);
//Теперь отправим пароль. В реальном FTP клиенте, перед отправкой новой команды
//нужно проверять ответ. Подробнее о кодах ответов можно узнать из RFC 959
 _send(_clientsocket, 'PASS '+user_pass);
//etc
 _send(_clientSocket, 'FEAT');

end;

{ Процедура выполняет прием данных }
procedure TForm1._Recv(s: TSocket);
var
  _buff:array[0..5000] of char;
  _str:string;
begin
//Очищаем буфер
 Fillchar(_buff, sizeof(_buff), 0);
//Пробуем получить данные,
//если возникнет ошибка, то пробуем получить ее код и сразу выйдем из процедуры
 if recv(s, _buff, sizeof(_buff), 0)=SOCKET_ERROR then
 begin
  GetError('recv');
  Exit;
 end;
//Копируем в _str пришедщие в _buff данные
 _str:=_buff;

//Вот таким образом можно проверять ответы от FTP сервера
 if pos('221', _str)>0 then
 begin
//Сообщением партнеру о прекращении соединения
   ShutDown(s, SD_BOTH);
//Закрываем сокет
   CloseSocket(s);
 end;

//Разбираем полученные данные
//Ищем символ конца строки
//Если находим, то копируем часть строки до него и добавляем
//в RichEdit
 while pos(#13, _str)>0 do
 begin
  RichEdit1.Lines.Add(copy(_str, 1, pos(#13, _str)));
//Ту часть которую уже добавили - удаляем
  Delete(_str, 1, pos(#13, _str)+1);
 end;
end;

{ Процедура отправляет данные через переданный в качестве параметра сокет }
procedure TForm1._Send(s: TSocket; ftp_command:string);
var
 _buff: array [0..1024] of Char;
begin
//К строке содержащей FTP команду добавляем символы конца строки
// и перевода каретки
 ftp_command:=ftp_command+#13#10;
//Копируем в _buff данные для отправки из _str
 CopyMemory(@_buff, pchar(ftp_command), length(ftp_command));
//Как обычно, делаем попытку выполнить действия. В нашем случае отправить данные
 if send(s, _buff, length(ftp_command),0)=SOCKET_ERROR then
 begin
  GetError('SEND');
  Exit;
 end;
end;

{ Обработчик события нажатия на кнопку }
procedure TForm1.N2Click(Sender: TObject);
begin
//Вызываем функцию _Connect
//Она описана выше
 _connect(Form3.SrvEdit.Text, Form3.Edit1.Text, Form3.LoginEdit.Text, Form3.PassEdit.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//Инициализируем сетевую библиотеку WinSock версии 1.1.
 if WSAStartup(MAKEWORD(1,1), _wsadata)<>0 then
 begin
//При возникновении ошибки показываем сообщение
//и завершаем наше приложение
  ShowMessage('Ошибка загрузки WinSock');
  Application.Terminate;
 end;
end;

{ Процедура перехватываем сообщение WM_MYSOCKMESS }
//Это сообщение приходит в тот момент, когда на определенном
//сокете возникает какое-либо (из определенных нами) событий
procedure TForm1.NetMSG(var M: TMessage);
begin
//в параметре m, структуры TMessage
//содержится код события
//С помощью управляющей структуры мы его и проверяем
   case m.LParam of
//Это событие мы проверяем для установления канала для передачи данных
//Если в очереди на подключении к созданному нами сокет-серверу есть клиент,
//то мы принимаем подключение. После этого, мы сможем обмениваться данным
//с клиентом через _tempSocket
    FD_ACCEPT:
    begin
      _tempSocket:=accept(m.WParam, nil, nil);
//Поскольку нам будут интересны данные которые придут по через соединение
//передачи данных, мы переводим socket в асинхронный режим и устанавливаем
//наблюдение за событиями FD_READ (уже объяснял что это за событие) и FD_CLOSE
//(Происходит в момент отключение клиента)
      WSAAsyncSelect(_tempSocket, handle, WM_MYSOCKMESS, FD_READ+FD_CLOSE);
    end;
//Какие бы данные не прибыли, получать их будем с помощью
//процедуры _recv
    FD_READ:  _recv(m.WParam);
//если клиент "ушел", то закрываем сокет
    FD_CLOSE: CloseSocket(M.WParam);
   end;

end;

procedure TForm1.N3Click(Sender: TObject);
begin
//Посылаем сереверу команду QUIT,
//которая свидетельствует о завершении соединения
 _send(_clientSocket, 'QUIT');
end;

{ Функция создает новый сокет, который будет ожидать подключение
 сервера для передачи данных (соединение передачи данных }
function TForm1.CreateListenSocket:Integer;
var
  _len, _val:integer;
begin
//Результатом выполнения функции будет номер порта,
//которые будет открыт для подключения
 Result:=0;
//Создаем сокет
 _serverSocket:=Socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
//Если при создании сокета возникла ошибка, то выходим
 if _serverSocket=INVALID_SOCKET then
 begin
  GetError('Socket');
  Exit;
 end;
//Получим размер структуры _serverAddr. В последствии нам это понадобится
//для получения информации о сокете, в частности для определения порта,
//который открыли длля прослушки
 _len:=sizeof(_serverAddr);

//Функция setsockopt предназначена для выставления сокету опций
//В качестве первого параметра нужно указать сокет, которому мы будем устанавливать
//опцию
//Второй параметр: уровень. Можно укзать SOL_SOCKET или IPPROTO_TCP
//Третий параметр зависит от второго. В нашем случае мы указываем SO_REUSEADDR
//который говорит о том, что мы можем после закрыти порта, сразу же его открывать заново.
//После закрытие порта, он еще висит несколько секнуд в памяти. Windows сама уже закроет его.
 setsockopt(_serversocket, SOL_SOCKET,SO_REUSEADDR, @_val, _len);
//Очищаем нашу структуру
 FillChar(_serveraddr, sizeof(_serveraddr), 0);
//Указываем семейство протоколов
 _serveraddr.sin_family:=AF_INET;
//Указываем наш адрес.
 _serveraddr.sin_addr.S_addr:=htonl(INADDR_ANY);
//В качестве порта ставим 0. В этом случае система сама нам
//предоставит свободный порт. Таким образом можно быть уверенным, что никаких
//конфликтов не произойдет
 _serveraddr.sin_port:=0;

//Связывае наш сокет с локальным адресомм портом
 if bind(_serverSocket, _serverAddr, sizeof(_serveraddr))=SOCKET_ERROR then
 begin
  GetError('BIND');
  Exit;
 end;

//Получаем информацию о сокете
 GetSockName(_serverSocket, _serverAddr, _len);

 //уже обяъснял
 WSAAsyncSelect(_serversocket, handle, WM_MYSOCKMESS, FD_ACCEPT+FD_CLOSE);

//Начинаем прослушивать
 if Listen(_serversocket, 10)=SOCKET_ERROR then
 begin
  GetError('LISTEN');
  Exit;
 end;
//В результат устанавливаем номер предосталенного системой порта.
 Result:=ntohs(_serveraddr.sin_port);
end;

procedure TForm1.LIST1Click(Sender: TObject);
var
 _ip:string;
 _port:integer;
begin
//создан ли у нас серверный сокет
//способ кустарный, поэтому его следует заменить на что-нибудь
//другое :)))
 if _serverSocket>0 then
  CloseSocket(_serverSocket);
//Создаем сокет, к которому потом будет подсоединяться удаленный сервер
//для передачи данных - списка файлов
 _port:=CreateListenSocket;
//определим наш IP адрес. Функция описана ниже
 _ip:=GetMyIPadress;
//Преобразуем наш IP адрес к требованием Rfc 959
 _ip:=StringReplace(_ip,'.',',', [rfReplaceall]);
//Добавляем порт к ип адресу
 _ip:=_ip+','+intToStr(_port div 256)+','+intToStr(_port mod 256);
//Отправляем команду, которая создаст в последствии соединение для передачи данных
 _send(_clientSocket, 'PORT '+_ip);
//Делаем запрос на получение данных
 _send(_clientSocket, 'LIST');
end;

{ Функция определяет локальный IP адрес }
function TForm1.getmyipadress: string;
var
  _host:PHostEnt;
  _buf:array[0..127] of char;
begin
  result:='';
//Сначала определим имя нашего компьютера
  if gethostname(_buf, 128)<>SOCKET_ERROR then
  begin
//Теперь определим IP по имени компа
    _host:=GetHostByName(_buf);
    if _host<>nil then
      Result:=inet_ntoa(PinAddr(_host^.h_addr_list^)^);
  end;

end;

procedure TForm1.CWD1Click(Sender: TObject);
var
  _command:string;
begin
 if not inputquery('Переход в папку','Имя папки', _command) then
  Exit;
 _send(_clientsocket, 'CWD '+_command);
end;

procedure TForm1.N5Click(Sender: TObject);
begin
 Form3.ShowModal;
end;

end.
