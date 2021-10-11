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
    { Déclarations privées }
  public
    { Déclarations publiques }
    procedure ListThreads; // Procédure pour lister les threads dans la boîte liste
  end;

const
  ThreadNames: array [0..6] of ShortString = // Tableau des couleurs de l'arc-en-ciel :)
  ('Rouge', 'Orange', 'Vert', 'Jaune', 'Bleu', 'Violet', 'Indigo');

  Priorities: array [0..6] of TThreadPriority = // Tableau de correspondance ordinale des priorités
  (tpIdle, tpLowest, tpLower, tpNormal, tpHigher, tpHighest, tpTimeCritical);

var
  MainForm: TMainForm; // Notre fiche
  ThreadList: TThreadListEx; // La liste de threads
  Results: array [0..6] of Cardinal; // Les résultats à la fin du test
  TimeOut: Integer; // Le temps restant avant la fin du test
  Thrds: array [0..6] of TThreadComponent; // Les threads utilisés pour le test
  TimerThrd: TThreadComponent; // Le thread pour décompter le temps
  // Un timer aurait fait l'affaire mais bon après tout ...

implementation

{$R *.dfm}

function PriorityToString(Priority: TThreadPriority): String; // Conversion des priorités en chaîne
begin
 case Priority of // Rien de bien compliqué !
  tpIdle: Result := 'Idle';
  tpLowest: Result := 'Lowest';
  tpLower: Result := 'Lower';
  tpNormal: Result := 'Normal';
  tpHigher: Result := 'Higher';
  tpHighest: Result := 'Highest';
  tpTimeCritical: Result := 'Time Critical';
 end;
end;

procedure TMainForm.FormCreate(Sender: TObject); // Création de la fiche
begin
 DoubleBuffered := True; // On évite les scintillements
 ThreadListBox.DoubleBuffered := True; // Idem
 ThreadList := TThreadListEx.Create; // On crée la liste
 TimerThrd := TThreadComponent.Create(nil); // On crée le thread pour décompter le temps
 TimerThrd.OnExecute := TimerThreadExecute; // On définit son gestionnaire d'évènement OnExecute
end;

procedure TMainForm.QuitBtnClick(Sender: TObject); // Bouton Quitter
begin
 ThreadList.Free; // On libère la liste (et tous les threads dedans bien sûr !)
 TimerThrd.Free; // On libère le thread pour décompter le temps
 Close; // On ferme la fiche principale donc l'application
end;

procedure TMainForm.ListThreads; // Listage des threads
Var
 I: Integer; // Variable de contrôle de boucle
 S: String; // Chaîne formatée à afficher dans la liste
begin
 ThreadListBox.Items.BeginUpdate; // On commence la mise à jour de la boîte liste
 ThreadListBox.Clear; // On vide la liste
 for I := 0 to ThreadList.Count - 1 do // Pour chaque thread
  begin
   // On formate la chaîne
   S := Format('%s [%s] - %d', [ThreadNames[I], PriorityToString(ThreadList.Threads[I].Priority), Results[I]]);
   ThreadListBox.Items.Add(S); // On ajoute la chaîne formatée
  end;
 ThreadListBox.Items.EndUpdate; // On a terminé la mise à jour
end;

procedure TMainForm.CreateThreadsBtnClick(Sender: TObject); // Bouton "Créer les 7 threads"
Var
 I: Integer; // Variable de contrôle de boucle
begin
 CreateThreadsBtn.Enabled := False; // On désactive ce bouton
 GoBtn.Enabled := True; // On active le bouton pour lancer le test
 for I := 0 to 6 do // Pour chaque thread ...
  begin
   Thrds[I] := TThreadComponent.Create(nil); // On crée ce thread
   Thrds[I].Interval := 1; // On lui donne un interval de 1
   Thrds[I].Tag := I; // Pour le reconnaître dans le gestionnaire d'évènements
   Thrds[I].Priority := Priorities[I]; // On lui donne la priorité convenable
   Thrds[I].OnExecute := ThrdExecute; // On lui donne le gestionnaire d'évènement OnExecute
   ThreadList.Add(Thrds[I]); // On l'ajoute dans la liste de threads
  end;
 ListThreads; // On liste les threads
end;

procedure TMainForm.ThrdExecute(Sender: TObject); // Gestionnaire OnExecute
begin
 if Sender is TThread then // Vérifie si on a bien affaire à un thread ...
  case TThread(Sender).Priority of // Selon la priorité du thread, on augmente le résultat
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
 I: Integer; // Variable de contrôle de boucle
begin
 TimeOut := 10; // 10 secondes de test
 for I := 0 to 6 do Results[I] := 0; // On initialise les résultats
 ListThreads; // On liste les threads
 TimerThrd.Active := True; // On active le thread de temps
 for I := 0 to 6 do ThreadList.Threads[I].Active := True; // On active tous les autres threads !
end;

procedure TMainForm.TimerThreadExecute(Sender: TObject); // OnExecute du thread de temps
Var
 I: Integer; // Variable de contrôle de boucle
begin
 Dec(TimeOut); // On descend de 1 le temps (OnExecute de ce thread toutes les secondes)
 GoBtn.Caption := 'Fin du test dans ' + IntToStr(TimeOut) + ' seconds.'; // On affiche le temps restant
 if TimeOut = 0 then // Si on est à la fin du test ...
  begin
   for I := 0 to 6 do ThreadList.Threads[I].Active := False; // On désactive chaque thread
   TimerThrd.Active := False; // On désactive le thread de temps
   ListThreads; // On liste les threads
   // On affiche un petit message !
   MessageDlg('Normalement, vous devriez observer une certaine logique quant aux resultats obtenus (les threads avec une priorité'
    + ' inférieure auront moins d''executions que les threads avec une priorité supérieure), avec des écarts néanmoins négligeables dans la plupart des cas.', mtInformation, [mbOK], 0);
   GoBtn.Caption := 'Lancer le test de performance de 10 secondes';
   // On remet le bouton dans son état normal.
  end;
end;

end.




