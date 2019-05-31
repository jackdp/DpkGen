program DpkGen;

{
  Jacek Pazera
  http://www.pazera-software.com
  https://github.com/jackdp
  Last mod: 2019.05.31

  -----------------------------------------
  DpkGen - Delphi packages (DPK) generator.
  -----------------------------------------
}

{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads} cthreads, {$ENDIF}{$ENDIF}
  SysUtils,
  DPKG.App in 'DPKG.App.pas',
  DPKG.Types in 'DPKG.Types.pas';

var
  App: TApp;

{$IFDEF MSWINDOWS}
// Na Linuxie czasami wyskakuje EAccessViolation
procedure MyExitProcedure;
begin
  if Assigned(App) then
  begin
    App.Done;
    FreeAndNil(App);
  end;
end;
{$ENDIF}


{$R *.res}

begin

  App := TApp.Create;
  try

    try

      {$IFDEF MSWINDOWS}App.ExitProcedure := @MyExitProcedure;{$ENDIF}
      App.Init;
      App.Run;
      if Assigned(App) then App.Done;

    except
      on E: Exception do Writeln(E.ClassName, ': ', E.Message);
    end;

  finally
    if Assigned(App) then App.Free;
  end;

end.

