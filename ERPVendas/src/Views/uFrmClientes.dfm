inherited frmClientes: TfrmClientes
  Caption = 'Cadastro de Clientes'
  PixelsPerInch = 96
  TextHeight = 15
  inherited pgcPrincipal: TcxPageControl
    inherited tsCadastro: TcxTabSheet
      object lblCodigo: TLabel
        Left = 16
        Top = 16
        Caption = 'C'#243'digo'
      end
      object edtCodigo: TcxDBTextEdit
        Left = 16
        Top = 34
        TabStop = False
        DataBinding.DataField = 'ID'
        DataBinding.DataSource = dsDados
        Properties.ReadOnly = True
        TabOrder = 0
        Width = 90
      end
      object lblNome: TLabel
        Left = 120
        Top = 16
        Caption = 'Nome *'
      end
      object edtNome: TcxDBTextEdit
        Left = 120
        Top = 34
        DataBinding.DataField = 'NOME'
        DataBinding.DataSource = dsDados
        Properties.MaxLength = 100
        TabOrder = 1
        Width = 420
      end
      object chkAtivo: TcxDBCheckBox
        Left = 556
        Top = 34
        Caption = 'Ativo'
        DataBinding.DataField = 'ATIVO'
        DataBinding.DataSource = dsDados
        TabOrder = 2
      end
      object lblDocumento: TLabel
        Left = 16
        Top = 70
        Caption = 'CPF / CNPJ *'
      end
      object edtDocumento: TcxDBTextEdit
        Left = 16
        Top = 88
        DataBinding.DataField = 'CPF_CNPJ'
        DataBinding.DataSource = dsDados
        Properties.CharCase = ecUpperCase
        Properties.MaxLength = 18
        TabOrder = 3
        Width = 180
      end
      object lblEmail: TLabel
        Left = 210
        Top = 70
        Caption = 'E-mail *'
      end
      object edtEmail: TcxDBTextEdit
        Left = 210
        Top = 88
        DataBinding.DataField = 'EMAIL'
        DataBinding.DataSource = dsDados
        Properties.MaxLength = 120
        TabOrder = 4
        Width = 330
      end
      object lblTelefone: TLabel
        Left = 16
        Top = 124
        Caption = 'Telefone'
      end
      object edtTelefone: TcxDBTextEdit
        Left = 16
        Top = 142
        DataBinding.DataField = 'TELEFONE'
        DataBinding.DataSource = dsDados
        Properties.MaxLength = 20
        TabOrder = 5
        Width = 180
      end
      object lblCidade: TLabel
        Left = 210
        Top = 124
        Caption = 'Cidade'
      end
      object edtCidade: TcxDBTextEdit
        Left = 210
        Top = 142
        DataBinding.DataField = 'CIDADE'
        DataBinding.DataSource = dsDados
        Properties.MaxLength = 60
        TabOrder = 6
        Width = 260
      end
      object lblUF: TLabel
        Left = 484
        Top = 124
        Caption = 'UF'
      end
      object cbUF: TcxDBComboBox
        Left = 484
        Top = 142
        DataBinding.DataField = 'UF'
        DataBinding.DataSource = dsDados
        Properties.CharCase = ecUpperCase
        Properties.MaxLength = 2
        TabOrder = 7
        Width = 56
      end
      object lblAjuda: TLabel
        Left = 16
        Top = 186
        Caption = '* Campos obrigat'#243'rios. O CPF/CNPJ pode ser digitado com ou sem m'#225'scara (CNPJ alfanum'#233'rico aceito).'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
  end
end
