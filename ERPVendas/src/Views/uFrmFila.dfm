object frmFila: TfrmFila
  Left = 0
  Top = 0
  Caption = 'Fila de integra'#231#227'o'
  ClientHeight = 480
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object grdFila: TcxGrid
    Left = 0
    Top = 0
    Width = 1000
    Height = 432
    Align = alClient
    TabOrder = 0
    object tvFila: TcxGridDBTableView
      DataController.DataSource = dsFila
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
    end
    object lvFila: TcxGridLevel
      GridView = tvFila
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 432
    Width = 1000
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnAtualizar: TcxButton
      Left = 8
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Atualizar'
      TabOrder = 0
      OnClick = btnAtualizarClick
    end
    object btnProcessarAgora: TcxButton
      Left = 114
      Top = 8
      Width = 120
      Height = 32
      Caption = 'Processar agora'
      TabOrder = 1
      OnClick = btnProcessarAgoraClick
    end
    object btnReprocessarErros: TcxButton
      Left = 240
      Top = 8
      Width = 130
      Height = 32
      Caption = 'Reprocessar erros'
      TabOrder = 2
      OnClick = btnReprocessarErrosClick
    end
    object btnFechar: TcxButton
      Left = 892
      Top = 8
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Fechar'
      TabOrder = 3
      OnClick = btnFecharClick
    end
  end
  object qryFila: TFDQuery
    Left = 840
    Top = 80
  end
  object dsFila: TDataSource
    AutoEdit = False
    DataSet = qryFila
    Left = 904
    Top = 80
  end
end
