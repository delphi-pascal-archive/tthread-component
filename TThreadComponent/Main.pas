unit Main;

interface

uses
  SysUtils, Forms, Dialogs, StdCtrls, Controls, Classes, ThreadComponent;

type
  TMainForm = class(TForm)
    ThreadListBox: TListBox;
    CreateThreadsBtn: TButton;
    GoBtn: TButton;
    QuitBtn: TButton;
    InfoLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure QuitBtnClick(Sender: TObject);
    procedure CreateThreadsBtnClick(Sender: TObject);
    procedure GoBtnClick(Sender: TObject);
    procedure TimerThreadExecute(Sender: TObject);
    procedure ThrdExecute(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
    procedure ListThreads; // Proc�dure pour lister les threads dans la bo�te liste
  end;

const
  ThreadNames: array [0..6] of ShortString = // Tableau des couleurs de l'arc-en-ciel :)
  ('Rouge', 'Orange', 'Vert', 'Jaune', 'Bleu', 'Violet', 'Indigo');

  Priorities: array [0..6] of TThreadPriority = // Tableau de correspondance ordinale des priorit�s
  (tpIdle, tpLowest, tpLower, tpNormal, tpHigher, tpHighest, tpTimeCritical);

var
  MainForm: TMainForm; // Notre fiche
  ThreadList: TThreadListEx; // La liste de threads
  Results: array [0..6] of Cardinal; // Les r�sultats � la fin du test
  TimeOut: Integer; // Le temps restant avant la fin du test
  Thrds: array [0..6] of TThreadComponent; // Les threads utilis�s pour le test
  TimerThrd: TThreadComponent; // Le thread pour d�compter le temps
  // Un timer aurait fait l'affaire mais bon apr�s tout ...

implementation

{$R *.dfm}

function PriorityToString(Priority: TThreadPriority): String; // Conversion des priorit�s en cha�ne
begin
 case Priority of // Rien de bien compliqu� !
  tpIdle: Result := 'Idle';
  tpLowest: Result := 'Lowest';
  tpLower: Result := 'Lower';
  tpNormal: Result := 'Normal';
  tpHigher: Result := 'Higher';
  tpHighest: Result := 'Highest';
  tpTimeCritical: Result := 'Time Critical';
 end;
end;

procedure TMainForm.FormCreate(Sender: TObject); // Cr�ation de la fiche
begin
 DoubleBuffered := True; // On �vite les scintillements
 ThreadListBox.DoubleBuffered := True; // Idem
 ThreadList := TThreadListEx.Create; // On cr�e la liste
 TimerThrd := TThreadComponent.Create(nil); // On cr�e le thread pour d�compter le temps
 TimerThrd.OnExecute := TimerThreadExecute; // On d�finit son gestionnaire d'�v�nement OnExecute
end;

procedure TMainForm.QuitBtnClick(Sender: TObject); // Bouton Quitter
begin
 ThreadList.Free; // On lib�re la liste (et tous les threads dedans bien s�r !)
 TimerThrd.Free; // On lib�re le thread pour d�compter le temps
 Close; // On ferme la fiche principale donc l'application
end;

procedure TMainForm.ListThreads; // Listage des threads
Var
 I: Integer; // Variable de contr�le de boucle
 S: String; // Cha�ne format�e � afficher dans la liste
begin
 ThreadListBox.Items.BeginUpdate; // On commence la mise � jour de la bo�te liste
 ThreadListBox.Clear; // On vide la liste
 for I := 0 to ThreadList.Count - 1 do // Pour chaque thread
  begin
   // On formate la cha�ne
   S := Format('%s [%s] - %d', [ThreadNames[I], PriorityToString(ThreadList.Threads[I].Priority), Results[I]]);
   ThreadListBox.Items.Add(S); // On ajoute la cha�ne format�e
  end;
 ThreadListBox.Items.EndUpdate; // On a termin� la mise � jour
end;

procedure TMainForm.CreateThreadsBtnClick(Sender: TObject); // Bouton "Cr�er les 7 threads"
Var
 I: Integer; // Variable de contr�le de boucle
begin
 CreateThreadsBtn.Enabled := False; // On d�sactive ce bouton
 GoBtn.Enabled := True; // On active le bouton pour lancer le test
 for I := 0 to 6 do // Pour chaque thread ...
  begin
   Thrds[I] := TThreadComponent.Create(nil); // On cr�e ce thread
   Thrds[I].Interval := 1; // On lui donne un interval de 1
   Thrds[I].Tag := I; // Pour le reconna�tre dans le gestionnaire d'�v�nements
   Thrds[I].Priority := Priorities[I]; // On lui donne la priorit� convenable
   Thrds[I].OnExecute := ThrdExecute; // On lui donne le gestionnaire d'�v�nement OnExecute
   ThreadList.Add(Thrds[I]); // On l'ajoute dans la liste de threads
  end;
 ListThreads; // On liste les threads
end;

procedure TMainForm.ThrdExecute(Sender: TObject); // Gestionnaire OnExecute
begin
 if Sender is TThread then // V�rifie si on a bien affaire � un thread ...
  case TThread(Sender).Priority of // Selon la priorit� du thread, on augmente le r�sultat
   tpIdle: Inc(Results[0]);
   tpLowest: Inc(Results[1]);
   tpLower: Inc(Results[2]);
   tpNormal: Inc(Results[3]);
   tpHigher: Inc(Results[4]);
   tpHighest: Inc(Results[5]);
   tpTimeCritical: Inc(Results[6]);
  end;
end;

procedure TMainForm.GoBtnClick(Sender: TObject); // Bouton "Go"
Var
 I: Integer; // Variable de contr�le de boucle
begin
 TimeOut := 10; // 10 secondes de test
 for I := 0 to 6 do Results[I] := 0; // On initialise les r�sultats
 ListThreads; // On liste les threads
 TimerThrd.Active := True; // On active le thread de temps
 for I := 0 to 6 do ThreadList.Threads[I].Active := True; // On active tous les autres threads !
end;

procedure TMainForm.TimerThreadExecute(Sender: TObject); // OnExecute du thread de temps
Var
 I: Integer; // Variable de contr�le de boucle
begin
 Dec(TimeOut); // On descend de 1 le temps (OnExecute de ce thread toutes les secondes)
 GoBtn.Caption := 'Fin du test dans ' + IntToStr(TimeOut) + ' seconds.'; // On affiche le temps restant
 if TimeOut = 0 then // Si on est � la fin du test ...
  begin
   for I := 0 to 6 do ThreadList.Threads[I].Active := False; // On d�sactive chaque thread
   TimerThrd.Active := False; // On d�sactive le thread de temps
   ListThreads; // On liste les threads
   // On affiche un petit message !
   MessageDlg('Normalement, vous devriez observer une certaine logique quant aux resultats obtenus (les threads avec une priorit�'
    + ' inf�rieure auront moins d''executions que les threads avec une priorit� sup�rieure), avec des �carts n�anmoins n�gligeables dans la plupart des cas.', mtInformation, [mbOK], 0);
   GoBtn.Caption := 'Lancer le test de performance de 10 secondes';
   // On remet le bouton dans son �tat normal.
  end;
end;

end.




