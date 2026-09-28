object frmCadastroBase: TfrmCadastroBase
  Left = 0
  Top = 0
  Caption = 'Cadastro'
  ClientHeight = 540
  ClientWidth = 880
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 780
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pgcPrincipal: TcxPageControl
    Left = 0
    Top = 0
    Width = 880
    Height = 492
    Align = alClient
    TabOrder = 0
    Properties.ActivePage = tsConsulta
    OnPageChanging = pgcPrincipalPageChanging
    object tsConsulta: TcxTabSheet
      Caption = 'Consulta'
      object pnlPesquisa: TPanel
        Left = 0
        Top = 0
        Width = 872
        Height = 44
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblPesquisa: TLabel
          Left = 8
          Top = 14
          Caption = 'Pesquisar:'
        end
        object edtPesquisa: TcxTextEdit
          Left = 72
          Top = 10
          TabOrder = 0
          OnKeyDown = edtPesquisaKeyDown
          Width = 400
        end
        object btnPesquisar: TcxButton
          Left = 480
          Top = 8
          Width = 100
          Height = 27
          Caption = 'Pesquisar'
          TabOrder = 1
          OnClick = btnPesquisarClick
        end
      end
      object grdConsulta: TcxGrid
        Left = 0
        Top = 44
        Width = 872
        Height = 418
        Align = alClient
        TabOrder = 1
        object tvConsulta: TcxGridDBTableView
          OnDblClick = tvConsultaDblClick
          DataController.DataSource = dsDados
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
        end
        object lvConsulta: TcxGridLevel
          GridView = tvConsulta
        end
      end
    end
    object tsCadastro: TcxTabSheet
      Caption = 'Cadastro'
      ImageIndex = 1
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 492
    Width = 880
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnNovo: TcxButton
      Left = 8
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Novo (F2)'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TcxButton
      Left = 114
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Editar (F3)'
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
    object btnSalvar: TcxButton
      Left = 340
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Salvar (F10)'
      TabOrder = 3
      OnClick = btnSalvarClick
    end
    object btnCancelar: TcxButton
      Left = 446
      Top = 8
      Width = 100
      Height = 32
      Caption = 'Cancelar (Esc)'
      TabOrder = 4
      OnClick = btnCancelarClick
    end
    object btnFechar: TcxButton
      Left = 772
      Top = 8
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Fechar'
      TabOrder = 5
      OnClick = btnFecharClick
    end
  end
  object qryDados: TFDQuery
    BeforePost = qryDadosBeforePost
    Left = 720
    Top = 120
  end
  object dsDados: TDataSource
    AutoEdit = False
    DataSet = qryDados
    OnStateChange = dsDadosStateChange
    Left = 784
    Top = 120
  end
end
