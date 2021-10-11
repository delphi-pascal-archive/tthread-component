object MainForm: TMainForm
  Left = 227
  Top = 133
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Example TThreadComponent et TThreadListEx'
  ClientHeight = 258
  ClientWidth = 490
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object InfoLabel: TLabel
    Left = 8
    Top = 8
    Width = 481
    Height = 33
    AutoSize = False
    Caption = 
      'Dans cet exemple, nous nous proposerons de comparer les performa' +
      'nces d'#39'un thread selon sa priorite. Definissons 7 threads, nomme' +
      's chacun par une couleur:'
    WordWrap = True
  end
  object ThreadListBox: TListBox
    Left = 8
    Top = 48
    Width = 473
    Height = 137
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = []
    ItemHeight = 17
    ParentFont = False
    TabOrder = 0
  end
  object CreateThreadsBtn: TButton
    Left = 8
    Top = 192
    Width = 145
    Height = 25
    Caption = 'Create 7 threads'
    TabOrder = 1
    OnClick = CreateThreadsBtnClick
  end
  object GoBtn: TButton
    Left = 160
    Top = 192
    Width = 321
    Height = 25
    Caption = 'Lancer le test de performance de 10 secondes'
    Enabled = False
    TabOrder = 2
    OnClick = GoBtnClick
  end
  object QuitBtn: TButton
    Left = 8
    Top = 224
    Width = 473
    Height = 25
    Caption = 'Exit'
    TabOrder = 3
    OnClick = QuitBtnClick
  end
end
