object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'ERP Vendas'
  ClientHeight = 300
  ClientWidth = 700
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
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 72
    Align = alTop
    BevelOuter = bvNone
    Color = 7359017
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 24
      Top = 8
      Caption = 'ERP Vendas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 24
      Top = 44
      Caption = 'Clientes  |  Produtos  |  Vendas  |  Integra'#231#227'o com o ERP Financeiro'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14737632
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 281
    Width = 700
    Height = 19
    Panels = <
      item
        Width = 250
      end
      item
        Width = 210
      end
      item
        Width = 50
      end>
  end
  object pnlMenu: TPanel
    Left = 0
    Top = 72
    Width = 700
    Height = 209
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object btnClientes: TcxButton
      Left = 24
      Top = 24
      Width = 200
      Height = 72
      Caption = 'Clientes'
      TabOrder = 0
      OnClick = btnClientesClick
    end
    object btnProdutos: TcxButton
      Left = 250
      Top = 24
      Width = 200
      Height = 72
      Caption = 'Produtos'
      TabOrder = 1
      OnClick = btnProdutosClick
    end
    object btnVendas: TcxButton
      Left = 476
      Top = 24
      Width = 200
      Height = 72
      Caption = 'Vendas'
      TabOrder = 2
      OnClick = btnVendasClick
    end
    object btnFila: TcxButton
      Left = 24
      Top = 116
      Width = 200
      Height = 72
      Caption = 'Fila de integra'#231#227'o'
      TabOrder = 3
      OnClick = btnFilaClick
    end
    object btnSair: TcxButton
      Left = 476
      Top = 116
      Width = 200
      Height = 72
      Caption = 'Sair'
      TabOrder = 4
      OnClick = btnSairClick
    end
  end
  object tmrStatus: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrStatusTimer
    Left = 360
    Top = 200
  end
end
