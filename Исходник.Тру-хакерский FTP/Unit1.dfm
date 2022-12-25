object Form1: TForm1
  Left = 441
  Top = 387
  Width = 524
  Height = 346
  Caption = 'FTP '#1082#1083#1080#1077#1085#1090
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object RichEdit1: TRichEdit
    Left = 0
    Top = 0
    Width = 516
    Height = 292
    Align = alClient
    Color = clBlack
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clLime
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object MainMenu1: TMainMenu
    Left = 232
    Top = 16
    object N1: TMenuItem
      Caption = #1057#1086#1077#1076#1080#1085#1077#1085#1080#1077
      object N2: TMenuItem
        Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100#1089#1103
        OnClick = N2Click
      end
      object N3: TMenuItem
        Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100#1089#1103
        OnClick = N3Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object N5: TMenuItem
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
        OnClick = N5Click
      end
    end
    object N6: TMenuItem
      Caption = #1050#1086#1084#1072#1085#1076#1099
      object LIST1: TMenuItem
        Caption = 'LIST'
        OnClick = LIST1Click
      end
      object CWD1: TMenuItem
        Caption = 'CWD'
        OnClick = CWD1Click
      end
    end
  end
end
