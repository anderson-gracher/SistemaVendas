object frmVendas: TfrmVendas
  Left = 0
  Top = 0
  Caption = 'Vendas'
  ClientHeight = 560
  ClientWidth = 1000
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 1000
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlFiltros: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblPeriodo: TLabel
      Left = 8
      Top = 18
      Caption = 'Per'#237'odo:'
    end
    object lblAte: TLabel
      Left = 180
      Top = 18
      Caption = 'at'#233
    end
    object lblStatus: TLabel
      Left = 322
      Top = 18
      Caption = 'Status:'
    end
    object lblCliente: TLabel
      Left = 492
      Top = 18
      Caption = 'Cliente:'
    end
    object dtDe: TcxDateEdit
      Left = 60
      Top = 14
      TabOrder = 0
      Width = 112
    end
    object dtAte: TcxDateEdit
      Left = 204
      Top = 14
      TabOrder = 1
      Width = 112
    end
    object cbStatus: TcxComboBox
      Left = 366
      Top = 14
      Properties.DropDownListStyle = lsFixedList
      Properties.Items.Strings = (
        'Todos'
        'ABERTA'
        'FATURADA'
        'QUITADA'
        'CANCELADA')
      TabOrder = 2
      Width = 116
    end
    object edtCliente: TcxTextEdit
      Left = 540
      Top = 14
      TabOrder = 3
      OnKeyDown = edtClienteKeyDown
      Width = 230
    end
    object btnPesquisar: TcxButton
      Left = 780
      Top = 12
      Width = 110
      Height = 27
      Caption = 'Pesquisar (F5)'
      TabOrder = 4
      OnClick = btnPesquisarClick
    end
  end
  object grdVendas: TcxGrid
    Left = 0
    Top = 52
    Width = 1000
    Height = 460
    Align = alClient
    TabOrder = 1
    object tvVendas: TcxGridDBTableView
      OnDblClick = tvVendasDblClick
      DataController.DataSource = dsVendas
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
    end
    object lvVendas: TcxGridLevel
      GridView = tvVendas
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 512
    Width = 1000
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnNova: TcxButton
      Left = 8
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Nova (F2)'
      TabOrder = 0
      OnClick = btnNovaClick
    end
    object btnEditar: TcxButton
      Left = 114
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnExcluir: TcxButton
      Left = 220
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Excluir'
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnFaturar: TcxButton
      Left = 340
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Faturar'
      TabOrder = 3
      OnClick = btnFaturarClick
    end
    object btnCancelar: TcxButton
      Left = 446
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Cancelar venda'
      TabOrder = 4
      OnClick = btnCancelarClick
    end
    object btnImprimir: TcxButton
      Left = 566
      Top = 8
      Width = 110
      Height = 32
      Caption = 'Imprimir pedido'
      TabOrder = 5
      OnClick = btnImprimirClick
    end
    object btnReenviarEmail: TcxButton
      Left = 682
      Top = 8
      Width = 120
      Height = 32
      Caption = 'Reenviar e-mail'
      TabOrder = 6
      OnClick = btnReenviarEmailClick
    end
    object btnFechar: TcxButton
      Left = 892
      Top = 8
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Fechar'
      TabOrder = 7
      OnClick = btnFecharClick
    end
  end
  object qryVendas: TFDQuery
    Left = 840
    Top = 120
  end
  object dsVendas: TDataSource
    AutoEdit = False
    DataSet = qryVendas
    OnDataChange = dsVendasDataChange
    Left = 904
    Top = 120
  end
end
