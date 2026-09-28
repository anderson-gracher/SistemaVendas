inherited frmProdutos: TfrmProdutos
  Caption = 'Cadastro de Produtos'
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
      object lblDescricao: TLabel
        Left = 120
        Top = 16
        Caption = 'Descri'#231#227'o *'
      end
      object edtDescricao: TcxDBTextEdit
        Left = 120
        Top = 34
        DataBinding.DataField = 'DESCRICAO'
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
      object lblUnidade: TLabel
        Left = 16
        Top = 70
        Caption = 'Unidade *'
      end
      object cbUnidade: TcxDBComboBox
        Left = 16
        Top = 88
        DataBinding.DataField = 'UNIDADE'
        DataBinding.DataSource = dsDados
        Properties.CharCase = ecUpperCase
        Properties.MaxLength = 6
        TabOrder = 3
        Width = 90
      end
      object lblPreco: TLabel
        Left = 120
        Top = 70
        Caption = 'Pre'#231'o de venda *'
      end
      object edtPreco: TcxDBCurrencyEdit
        Left = 120
        Top = 88
        DataBinding.DataField = 'PRECO'
        DataBinding.DataSource = dsDados
        Properties.DecimalPlaces = 2
        Properties.DisplayFormat = ',0.00'
        TabOrder = 4
        Width = 140
      end
      object lblEstoque: TLabel
        Left = 274
        Top = 70
        Caption = 'Estoque'
      end
      object edtEstoque: TcxDBCurrencyEdit
        Left = 274
        Top = 88
        DataBinding.DataField = 'ESTOQUE'
        DataBinding.DataSource = dsDados
        Properties.DecimalPlaces = 3
        Properties.DisplayFormat = ',0.###'
        TabOrder = 5
        Width = 140
      end
    end
  end
end
