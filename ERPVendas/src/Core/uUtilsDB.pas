unit uUtilsDB;

interface

uses Data.DB;

/// Define rótulo, formato de exibição e visibilidade de um campo (se existir).
procedure DefinirCampo(ADataSet: TDataSet; const ACampo, ARotulo: string;
  const AFormato: string = ''; AVisivel: Boolean = True);

implementation

uses Data.SqlTimSt;

procedure DefinirCampo(ADataSet: TDataSet; const ACampo, ARotulo: string;
                       const AFormato: string; AVisivel: Boolean);
var Campo: TField;

begin

  Campo := ADataSet.FindField(ACampo);
  
  if Campo = nil then begin
    
	exit;
  end;
  
  Campo.DisplayLabel := ARotulo;
  Campo.Visible := AVisivel;
  
  if AFormato = '' then begin
    
	exit;
  end;
  
  if Campo is TNumericField then begin
  
    TNumericField(Campo).DisplayFormat := AFormato	
  end else begin 
   if Campo is TDateTimeField then begin
   
     TDateTimeField(Campo).DisplayFormat := AFormato   
   end else begin
   
     if Campo is TSQLTimeStampField then begin
       TSQLTimeStampField(Campo).DisplayFormat := AFormato;
	 end; 
   end;
  end; 
end;

end.
