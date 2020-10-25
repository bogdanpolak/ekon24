program db_generator;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  main in 'main.pas';

begin
  try
    TDatabaseGenerator.Run();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
