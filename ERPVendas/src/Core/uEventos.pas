unit uEventos;

/// Notificação simples (publish/subscribe) de "venda atualizada".
/// Pode ser disparada de qualquer thread; a entrega aos assinantes sempre
/// acontece na thread principal (telas atualizam a grade).

interface

type

  TVendaAtualizadaEvent = procedure(AIdVenda: Integer) of object;

procedure AssinarVendaAtualizada(AEvento: TVendaAtualizadaEvent);
procedure CancelarVendaAtualizada(AEvento: TVendaAtualizadaEvent);
procedure NotificarVendaAtualizada(AIdVenda: Integer);

implementation

uses System.Classes, System.Generics.Collections;

var FAssinantes: TList<TVendaAtualizadaEvent>;

procedure AssinarVendaAtualizada(AEvento: TVendaAtualizadaEvent);
begin
  
  if not FAssinantes.Contains(AEvento) then begin
    
	FAssinantes.Add(AEvento);
  end;
end;

procedure CancelarVendaAtualizada(AEvento: TVendaAtualizadaEvent);
begin
  FAssinantes.Remove(AEvento);
end;

procedure NotificarVendaAtualizada(AIdVenda: Integer);
begin
  TThread.Queue(nil, 
    procedure
    
	var
      I: Integer;
      Evento: TVendaAtualizadaEvent;
    begin
      
	  if FAssinantes = nil then begin
        
		exit;
	  end;
	  
      for I := FAssinantes.Count - 1 downto 0 do begin
        
		Evento := FAssinantes[I];
        Evento(AIdVenda);
      end;
    end);
end;

initialization
  FAssinantes := TList<TVendaAtualizadaEvent>.Create;

finalization
  FAssinantes.Free;
  FAssinantes := nil;

end.
