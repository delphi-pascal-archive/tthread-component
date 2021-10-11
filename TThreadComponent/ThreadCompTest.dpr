program ThreadCompTest;

uses
  Forms,
  Main in 'Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Exemple TThread';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
