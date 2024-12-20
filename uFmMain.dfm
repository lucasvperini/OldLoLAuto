object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'LOL Auto'
  ClientHeight = 354
  ClientWidth = 668
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object pcPageControl: TPageControl
    Left = 0
    Top = 0
    Width = 668
    Height = 353
    ActivePage = tsChampSelect
    RaggedRight = True
    TabOrder = 0
    object tsChampSelect: TTabSheet
      Caption = 'Sele'#231#227'o de Campe'#245'es'
      object lbChampionBan: TLabel
        Left = 234
        Top = 3
        Width = 82
        Height = 15
        Caption = 'Campe'#227'o (Ban)'
      end
      object lbChampionPick: TLabel
        Left = 3
        Top = 3
        Width = 84
        Height = 15
        Caption = 'Campe'#227'o (Pick)'
      end
      object lbChatMessage: TLabel
        Left = 3
        Top = 195
        Width = 122
        Height = 15
        Caption = 'Mensagem autom'#225'tica'
      end
      object lbSummonerSpell1: TLabel
        Left = 234
        Top = 195
        Width = 54
        Height = 15
        Caption = 'Feiti'#231'o (D)'
      end
      object lbSummonerSpell2: TLabel
        Left = 234
        Top = 245
        Width = 52
        Height = 15
        Caption = 'Feiti'#231'o (F)'
      end
      object lbLobbyParticipants: TLabel
        Left = 465
        Top = 3
        Width = 121
        Height = 15
        Caption = 'Participantes do Lobby'
      end
      object Label2: TLabel
        Left = 465
        Top = 219
        Width = 183
        Height = 30
        Caption = 
          #193'rea com dados da champ select, '#13#10'percentual de tipo de dano, et' +
          'c etc'
      end
      object cbChampionBan: TComboBox
        Left = 234
        Top = 24
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 0
        OnChange = cbChampionBanChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object cbChampionPick: TComboBox
        Left = 3
        Top = 24
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 1
        OnChange = cbChampionPickChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object cbSpellPick1: TComboBox
        Left = 234
        Top = 216
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 2
        OnChange = cbSpellPick1Change
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object cbSpellPick2: TComboBox
        Left = 234
        Top = 266
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 3
        OnChange = cbSpellPick2Change
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object chbAutoChampion: TCheckBox
        Left = 171
        Top = 27
        Width = 50
        Height = 17
        Caption = 'Auto'
        TabOrder = 4
        OnClick = chbAutoChampionClick
      end
      object chbAutoChampionBan: TCheckBox
        Left = 402
        Top = 27
        Width = 50
        Height = 17
        Caption = 'Auto'
        TabOrder = 5
        OnClick = chbAutoChampionBanClick
      end
      object chbAutoChatMessage: TCheckBox
        Left = 145
        Top = 195
        Width = 50
        Height = 17
        Caption = 'Auto'
        TabOrder = 6
        OnClick = chbAutoChatMessageClick
      end
      object chbAutoSpell1: TCheckBox
        Left = 402
        Top = 219
        Width = 50
        Height = 17
        Caption = 'Auto'
        TabOrder = 7
        OnClick = chbAutoSpell1Click
      end
      object chbAutoSpell2: TCheckBox
        Left = 402
        Top = 269
        Width = 50
        Height = 17
        Caption = 'Auto'
        TabOrder = 8
        OnClick = chbAutoSpell2Click
      end
      object mmChatMessage: TMemo
        Left = 3
        Top = 216
        Width = 192
        Height = 103
        Lines.Strings = (
          'mmChatMessage')
        MaxLength = 200
        TabOrder = 9
        OnChange = mmChatMessageChange
      end
      object btnSearchOPGG: TButton
        Left = 606
        Top = 169
        Width = 51
        Height = 25
        Caption = 'OP.GG'
        TabOrder = 10
        OnClick = btnSearchOPGGClick
      end
      object edtSummoner1: TEdit
        Left = 465
        Top = 24
        Width = 192
        Height = 23
        TabOrder = 11
        Text = 'Invocador 1'
      end
      object edtSummoner2: TEdit
        Left = 465
        Top = 53
        Width = 192
        Height = 23
        TabOrder = 12
        Text = 'Invocador 2'
      end
      object edtSummoner3: TEdit
        Left = 465
        Top = 82
        Width = 192
        Height = 23
        TabOrder = 13
        Text = 'Invocador 3'
      end
      object edtSummoner4: TEdit
        Left = 465
        Top = 111
        Width = 192
        Height = 23
        TabOrder = 14
        Text = 'Invocador 4'
      end
      object edtSummoner5: TEdit
        Left = 465
        Top = 140
        Width = 192
        Height = 23
        TabOrder = 15
        Text = 'Invocador 5'
      end
      object dvDiviver2: TPanel
        Left = 227
        Top = 3
        Width = 1
        Height = 318
        TabOrder = 16
      end
      object dvDivider1: TPanel
        Left = 458
        Top = 3
        Width = 1
        Height = 318
        TabOrder = 17
      end
      object ComboBox1: TComboBox
        Left = 3
        Top = 53
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 18
        OnChange = cbChampionPickChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox2: TComboBox
        Left = 3
        Top = 82
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 19
        OnChange = cbChampionPickChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox3: TComboBox
        Left = 3
        Top = 111
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 20
        OnChange = cbChampionPickChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox4: TComboBox
        Left = 3
        Top = 140
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 21
        OnChange = cbChampionPickChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox5: TComboBox
        Left = 234
        Top = 53
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 22
        OnChange = cbChampionBanChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox6: TComboBox
        Left = 234
        Top = 82
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 23
        OnChange = cbChampionBanChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox7: TComboBox
        Left = 234
        Top = 111
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 24
        OnChange = cbChampionBanChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object ComboBox8: TComboBox
        Left = 234
        Top = 140
        Width = 162
        Height = 23
        Style = csDropDownList
        Color = clWhite
        Sorted = True
        TabOrder = 25
        OnChange = cbChampionBanChange
        Items.Strings = (
          'Carregando campe'#245'es...')
      end
      object btnDodgeQueue: TButton
        Left = 562
        Top = 295
        Width = 95
        Height = 25
        Caption = 'Dodge'
        TabOrder = 26
        OnClick = btnDodgeQueueClick
      end
    end
    object tsOptions: TTabSheet
      Caption = 'Op'#231#245'es'
      ImageIndex = 1
      object Label1: TLabel
        Left = 352
        Top = 91
        Width = 34
        Height = 15
        Caption = 'Label1'
      end
      object Edit1: TEdit
        Left = 352
        Top = 112
        Width = 305
        Height = 23
        TabOrder = 0
        Text = 'Edit1'
      end
      object Edit2: TEdit
        Left = 352
        Top = 141
        Width = 305
        Height = 23
        TabOrder = 1
        Text = 'Edit2'
      end
      object btnKillClient: TButton
        Left = 269
        Top = 3
        Width = 95
        Height = 25
        Caption = 'Finalizar cliente'
        TabOrder = 2
        OnClick = btnKillClientClick
      end
      object CheckBox1: TCheckBox
        Left = 3
        Top = 49
        Width = 218
        Height = 17
        Caption = 'Aceitar apenas trocas inferiores'
        TabOrder = 3
        OnClick = chbInstaHoverChampionClick
      end
      object chbInstaHoverChampion: TCheckBox
        Left = 3
        Top = 72
        Width = 218
        Height = 17
        Caption = 'Mostrar campe'#227'o instantaneamente'
        TabOrder = 4
        OnClick = chbInstaHoverChampionClick
      end
      object chbAutoQueue: TCheckBox
        Left = 3
        Top = 3
        Width = 193
        Height = 17
        Caption = 'Aceitar queue automaticamente'
        TabOrder = 5
        OnClick = chbAutoQueueClick
      end
      object chbAutoTradePick: TCheckBox
        Left = 3
        Top = 26
        Width = 193
        Height = 17
        Caption = 'Aceitar troca automaticamente'
        TabOrder = 6
        OnClick = chbAutoTradePickClick
      end
    end
    object tsLogger: TTabSheet
      Caption = 'Log'
      ImageIndex = 2
      object mmLogger: TMemo
        Left = 0
        Top = 0
        Width = 660
        Height = 323
        Align = alClient
        Enabled = False
        Lines.Strings = (
          'mmLogger')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object pnLoadingPanel: TPanel
    Left = 428
    Top = -8
    Width = 28
    Height = 28
    Caption = 'Waiting for Riot Client'
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Roboto'
    Font.Style = []
    Font.Quality = fqAntialiased
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    Visible = False
    object pnLoadingCircle: TActivityIndicator
      Left = 266
      Top = 82
      IndicatorSize = aisXLarge
    end
  end
end
