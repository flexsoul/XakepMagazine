object Form1: TForm1
  Left = 241
  Top = 96
  Width = 620
  Height = 511
  Caption = '][ IRC '#1082#1083#1080#1077#1085#1090
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label5: TLabel
    Left = 16
    Top = 404
    Width = 33
    Height = 13
    Caption = #1058#1077#1082#1089#1090':'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 612
    Height = 137
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 60
      Height = 13
      Caption = 'IRC '#1089#1077#1088#1074#1077#1088':'
    end
    object Label2: TLabel
      Left = 40
      Top = 48
      Width = 28
      Height = 13
      Caption = #1055#1086#1088#1090':'
    end
    object Label3: TLabel
      Left = 328
      Top = 16
      Width = 23
      Height = 13
      Caption = #1053#1080#1082':'
    end
    object Label4: TLabel
      Left = 328
      Top = 48
      Width = 34
      Height = 13
      Caption = #1050#1072#1085#1072#1083':'
    end
    object Label6: TLabel
      Left = 36
      Top = 80
      Width = 32
      Height = 13
      Caption = 'E-Mail:'
    end
    object ServerEdit: TEdit
      Left = 80
      Top = 10
      Width = 233
      Height = 21
      TabOrder = 0
      Text = 'irc.dal.net'
    end
    object PortEdit: TEdit
      Left = 80
      Top = 42
      Width = 233
      Height = 21
      TabOrder = 1
      Text = '6667'
    end
    object NickEdit: TEdit
      Left = 368
      Top = 8
      Width = 233
      Height = 21
      TabOrder = 2
      Text = 'Santa2008'
    end
    object ChannelEdit: TEdit
      Left = 368
      Top = 40
      Width = 233
      Height = 21
      TabOrder = 3
      Text = '#xakep'
    end
    object ConnectBtn: TButton
      Left = 8
      Top = 104
      Width = 89
      Height = 25
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100
      DragKind = dkDock
      TabOrder = 4
      OnClick = ConnectBtnClick
    end
    object DisconnectBtn: TButton
      Left = 96
      Top = 104
      Width = 89
      Height = 25
      Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100
      DragKind = dkDock
      TabOrder = 5
      OnClick = DisconnectBtnClick
    end
    object Button1: TButton
      Left = 368
      Top = 72
      Width = 233
      Height = 25
      Caption = #1047#1072#1081#1090#1080' '#1085#1072' '#1082#1072#1085#1072#1083
      TabOrder = 6
      OnClick = Button1Click
    end
    object EmailEdit: TEdit
      Left = 80
      Top = 72
      Width = 233
      Height = 21
      TabOrder = 7
      Text = 'spider_net@inbox.ru'
    end
  end
  object logMemo: TMemo
    Left = 0
    Top = 137
    Width = 496
    Height = 299
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial Black'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object UsersListBox: TListBox
    Left = 496
    Top = 137
    Width = 116
    Height = 299
    Align = alRight
    ItemHeight = 13
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 0
    Top = 436
    Width = 612
    Height = 41
    Align = alBottom
    TabOrder = 3
    object MessageEdit: TEdit
      Left = 8
      Top = 12
      Width = 441
      Height = 21
      TabOrder = 0
    end
    object SendBtn: TButton
      Left = 456
      Top = 8
      Width = 153
      Height = 25
      Caption = #1054#1090#1087#1088#1072#1074#1080#1090#1100
      TabOrder = 1
      OnClick = SendBtnClick
    end
  end
end
