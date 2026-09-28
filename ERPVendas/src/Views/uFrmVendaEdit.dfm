object frmVendaEdit: TfrmVendaEdit
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Venda'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Constraints.MinHeight = 520
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlCabecalho: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 120
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblNumero: TLabel
      Left = 12
      Top = 8
      Caption = 'Nova venda'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7359017
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCliente: TLabel
      Left = 12
      Top = 40
      Caption = 'Cliente *'
    end
    object lblData: TLabel
      Left = 448
      Top = 40
      Caption = 'Data *'
    end
    object lblObservacao: TLabel
      Left = 612
      Top = 40
      Caption = 'Observa'#231#227'o'
    end
    object lcbCliente: TcxLookupComboBox
      Left = 12
      Top = 58
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 0
      Width = 420
    end
    object dtData: TcxDateEdit
      Left = 448
      Top = 58
      Properties.Kind = ckDateTime
      TabOrder = 1
      Width = 150
    end
    object memObservacao: TcxMemo
      Left = 612
      Top = 58
      Properties.MaxLength = 500
      TabOrder = 2
      Height = 52
      Width = 276
    end
  end
  object pnlItem: TPanel
    Left = 0
    Top = 120
    Width = 900
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblProduto: TLabel
      Left = 12
      Top = 6
      Caption = 'Produto'
    end
    object lblQuantidade: TLabel
      Left = 448
      Top = 6
      Caption = 'Quantidade'
    end
    object lblPreco: TLabel
      Left = 556
      Top = 6
      Caption = 'Pre'#231'o unit'#225'rio'
    end
    object lcbProduto: TcxLookupComboBox
      Left = 12
      Top = 24
      Properties.DropDownListStyle = lsFixedList
      Properties.OnEditValueChanged = lcbProdutoPropertiesEditValueChanged
      TabOrder = 0
      Width = 420
    end
    object edtQuantidade: TcxCurrencyEdit
      Left = 448
      Top = 24
      TabOrder = 1
      Width = 100
    end
    object edtPreco: TcxCurrencyEdit
      Left = 556
      Top = 24
      TabOrder = 2
      Width = 110
    end
    object btnAdicionar: TcxButton
      Left = 676
      Top = 22
      Width = 100
      Height = 27
      Caption = 'Adicionar'
      TabOrder = 3
      OnClick = btnAdicionarClick
    end
    object btnRemover: TcxButton
      Left = 784
      Top = 22
      Width = 104
      Height = 27
      Caption = 'Remover item'
      TabOrder = 4
      OnClick = btnRemoverClick
    end
  end
  object grdItens: TcxGrid
    Left = 0
    Top = 184
    Width = 900
    Height = 360
    Align = alClient
    TabOrder = 2
    object tvItens: TcxGridDBTableView
      DataController.DataSource = dsItens
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
    end
    object lvItens: TcxGridLevel
      GridView = tvItens
    end
  end
  object pnlRodape: TPanel
    Left = 0
    Top = 544
    Width = 900
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object lblTotalTitulo: TLabel
      Left = 12
      Top = 20
      Caption = 'Total da venda:'
    end
    object lblTotal: TLabel
      Left = 108
      Top = 12
      Caption = 'R$ 0,00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7359017
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnSalvar: TcxButton
      Left = 680
      Top = 12
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Salvar'
      Default = False
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnCancelar: TcxButton
      Left = 788
      Top = 12
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object qryClientes: TFDQuery
    Left = 560
    Top = 280
  end
  object dsClientes: TDataSource
    DataSet = qryClientes
    Left = 624
    Top = 280
  end
  object qryProdutos: TFDQuery
    Left = 560
    Top = 336
  end
  object dsProdutos: TDataSource
    DataSet = qryProdutos
    Left = 624
    Top = 336
  end
  object mtItens: TFDMemTable
    Left = 560
    Top = 392
  end
  object dsItens: TDataSource
    AutoEdit = False
    DataSet = mtItens
    Left = 624
    Top = 392
  end
end
