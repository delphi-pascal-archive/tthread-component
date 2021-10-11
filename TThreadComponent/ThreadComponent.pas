{                                  THREAD COMPONENT

Auteur : Bacterius

Ce composant permet d'introduire facilement un thread dans votre application.
Une notion interessante et utile qui est mise en application dans ce composant
est la "monod�pendance". Je m'explique : ici, le composant encapsulant le thread
a bien s�r acc�s au thread. Mais la r�ciproque n'est pas vraie ! Le thread n'a pas
acc�s au composant qui l'encapsule. C'est pourquoi l'on est oblig� de stocker
quelques variables dans le thread lui-m�me, ainsi que dans le composant (pour
pouvoir g�rer les propri�t�s du composant, ET pour pouvoir laisser au thread l'acc�s
� des informations indispensables � son fonctionnement correct, tels l'intervalle
ou encore la priorit� demand�e par l'utilisateur du composant).

Remarque : Le param�tre Sender des diff�rents �v�nements de ce composant n'est
pas le m�me selon les �v�nements. Voici un tableau de correspondance :

           _______________________________________________________
          |        Ev�nement        |       Param�tre Sender      |
          | ________________________|_____________________________|
          |       OnExecute         |          TThread            |
          |       OnResume          |      TThreadComponent       |
          |       OnSuspend         |      TThreadComponent       |
          |_________________________|_____________________________|

La raison de cette diff�rence dans OnExecute est que le gestionnaire OnExecute
est appel� par le thread et non par le composant encapsulant le thread (contrairement
aux deux autres �v�nements OnResume et OnSuspend).



De plus, un type TThreadComponentList est fourni pour g�rer une liste de threads,
� laquelle vous pouvez bien s�r ajouter, retirer et g�rer des threads.
Notez que le fait de retirer un thread par les m�thodes Delete ou Clear ou Free
a pour effet de terminer ce thread afin de ne pas le laisser hors de contr�le.
Pour ne pas terminer le thread (le garder en fonctionnement tout en le retirant
de la liste), utilisez la m�thode Extract.

}

unit ThreadComponent;

interface

uses
  Windows,
  Classes,
  Forms; 

type
  TRuntimeCheck=function: Boolean of Object; // Fonction pour savoir depuis le thread
   // si le composant est en runtime.

  TMyThread = class(TThread) // Classe thread basique
   private
    FInterval: Cardinal; // Intervalle dans le thread
    FOnExecute: TNotifyEvent; // Gestionnaire OnExecute dans le thread
    FRuntimeCheck: TRuntimeCheck; // Fonction de liaison � IsRuntime dans le composant
    procedure CentralControl; // M�thode principale du thread
  protected
    procedure Execute; override; // Boucle principale du thread
  end;

  TThreadComponent = class(TComponent) // Le composant encapsulant le thread
  private
    FThread: TMyThread; // Le thread � encapsuler
    FInterval: Cardinal; // L'intervalle
    FActive: Boolean; // L'�tat (actif/inactif)
    FPriority: TThreadPriority; // La priorit� du thread
    FOnSuspend: TNotifyEvent; // Le gestionnaire OnSuspend
    FOnResume: TNotifyEvent; // Le gestionnaire OnResume
    FOnExecute: TNotifyEvent; // Le gestionnaire OnExecute
    procedure SetInterval(Value: Cardinal); // Setter pour la propri�t� Interval
    procedure SetPriority(Value: TThreadPriority); // Setter pour la propri�t� Priority
    procedure SetActive(Value: Boolean); // Setter pour la propri�t� Active
    procedure SetOnExecute(Value: TNotifyEvent); // Setter pour le gestionnaire OnExecute
    function GetThreadHandle: Cardinal; // Getter pour le handle du thread
    function GetThreadID: Cardinal; // Getter pour l'identificateur du thread
    function IsRuntime: Boolean; // Fonction pour savoir si le composant est en runtime
  public
    constructor Create(AOwner: TComponent); override; // Constructeur surcharg�
    destructor Destroy; override; // Destructeur surcharg�
  published
    property Interval: Cardinal read FInterval write SetInterval; // Propri�t� Interval
    property Priority: TThreadPriority read FPriority write SetPriority; // Propri�t� Priority
    property Active: Boolean read FActive write SetActive; // Propri�t� Active
    property ThreadHandle: Cardinal read GetThreadHandle; // Propri�t� ThreadHandle
    property ThreadID: Cardinal read GetThreadID; // Propri�t� ThreadID
    property OnSuspend: TNotifyEvent read FOnSuspend write FOnSuspend; // Gestionnaire OnSuspend
    property OnResume: TNotifyEvent read FOnResume write FOnResume; // Gestionnaire OnResume
    property OnExecute: TNotifyEvent read FOnExecute write SetOnExecute; // Gestionnaire OnExecute
  end;

  PThreadComponent = ^TThreadComponent; // Pointeur sur le type TThreadComponent

procedure Register; // Proc�dure de recensement du composant

{-------------------------------------------------------------------------------
------------------------------- TTHREADLISTEX ----------------------------------
-------------------------------------------------------------------------------}

type TThreadListEx = class // Classe TThreadListEx
 private
  FList: TList; // La liste de pointeurs priv�e
  function GetCount: Cardinal; // Getter Count
  function GetCapacity: Cardinal; // Getter Capacity
  procedure SetCapacity(Value: Cardinal); // Setter Capacity
  function GetThread(Index: Integer): TThreadComponent; // Getter Threads
 public
  constructor Create; reintroduce; // Constructeur r�introduit pour la classe
  destructor Destroy; override; // Destructeur surcharg�
  function AddNew: TThreadComponent; // Ajoute un nouveau thread
  procedure Add(var Thread: TThreadComponent); // Ajoute un thread d�j� cr��
  procedure Insert(At: Integer; var Thread: TThreadComponent); // Ins�re un thread dans la liste
  function Extract(At: Integer): TThreadComponent; // Supprime un thread sans le terminer
  procedure Delete(At: Integer); // Supprime un thread de la liste
  procedure SetNil(At: Integer); // "Gomme" un thread sans le supprimer de la liste
  procedure Exchange(Src, Dest: Integer); // On �change 2 threads de place dans la liste
  procedure Pack; // Compression et nettoyage de la liste
  procedure Clear; // Elimine tous les threads de la liste
  property Count: Cardinal read GetCount; // Propri�t� Count (nombre de threads dans la liste)
  property Capacity: Cardinal read GetCapacity write SetCapacity; // Propri�t� Capacity
  property Threads[Index: Integer]: TThreadComponent read GetThread; // Propri�t� tableau Threads
 end;

implementation

procedure Register; // Proc�dure de recensement du composant
begin
  RegisterComponents('Syst�me', [TThreadComponent]);
  // Recensement de TThreadComponent dans la page Syst�me.
end;

procedure TMyThread.CentralControl; // M�thode principale
begin
 if (FRuntimeCheck) and Assigned(FOnExecute) then FOnExecute(self);
 // Si on est en runtime et que le gestionnaire OnExecute est assign�, on execute ce dernier
end;

procedure TMyThread.Execute; // Boucle du thread
begin
 repeat  // On r�p�te l'execution du thread ...
  Sleep(FInterval); // On attend l'intervalle demand�
  Application.ProcessMessages;  // On laisse l'application traiter ses messages
  Synchronize(CentralControl); // On synchronise avec la m�thode principale
 until Terminated; // ... jusqu'� ce que le thread soit termin�
end;

function TThreadComponent.IsRuntime: Boolean; // V�rifie si le composant est un runtime
begin
 Result := not (csDesigning in ComponentState);
 // csDesigning indique que l'on est en mode conception
end;

procedure TThreadComponent.SetOnExecute(Value: TNotifyEvent); // On d�finit le gestionnaire OnExecute
begin
 if @Value <> @FOnExecute then // Si on a chang� de gestionnaire ...
  begin
   FOnExecute := Value; // On change le gestionnaire
   FThread.FOnExecute := Value; // On le change aussi dans le thread
  end;
end;

procedure TThreadComponent.SetInterval(Value: Cardinal); // On d�finit l'intervalle du thread
begin
 if Value <> FInterval then // Si l'intervalle a chang�
  begin
   FInterval := Value; // On change la propri�t�
   FThread.FInterval := Value; // Et on change aussi la variable dans le thread
  end;
end;

procedure TThreadComponent.SetPriority(Value: TThreadPriority); // On d�finit la priorit� du thread
begin
 if Value <> FPriority then // Si la priorit� a chang�
  begin
   FPriority := Value; // On change la propri�t�
   FThread.Priority := Value; // Et on change r�ellement la priorit� du thread
  end;
end;

procedure TThreadComponent.SetActive(Value: Boolean); // On d�finit l'�tat du thread
begin
 if Value <> FActive then // Si on change d'�tat
  begin
   FActive := Value; // On change la propri�t�
   case FActive of // Selon le nouvel �tat ...
    False: // D�sactiv�
     begin
      FThread.Suspend; // On arr�te le thread
      if (IsRuntime) and (Assigned(FOnSuspend)) then FOnSuspend(self);
      // Si on a d�fini un gestionnaire OnSuspend et que l'on est en runtime, on lance ce gestionnaire
     end;
    True: // Activ�
     begin
      FThread.Resume; // On reprend l'execution du thread
      if (IsRuntime) and (Assigned(FOnResume)) then FOnResume(self);
      // Si on a d�fini un gestionnaire OnResume et que l'on est en runtime, on lance ce gestionnaire
     end;
   end;
  end;
end;

function TThreadComponent.GetThreadHandle: Cardinal; // On r�cup�re le handle du thread
begin
 Result := FThread.Handle; // Ce handle peut �tre utilis� dans des APIs concernant les threads
end;

function TThreadComponent.GetThreadID: Cardinal; // On r�cup�re l'identificateur du thread
begin
 Result := FThread.ThreadID; // Peut �tre utilis� �galement dans certaines APIs
end;

constructor TThreadComponent.Create(AOwner: TComponent); // Cr�ation du composant
begin
 inherited Create(AOwner); // On laisse Delphi faire le sale boulot � notre place ...
 FThread := TMyThread.Create(True); // On cr�e le thread arr�t�
 FThread.FRuntimeCheck := IsRuntime; // On �tablit une liaison entre la fonction de
 // v�rification du runtime dans le composant avec une fonction similaire du thread.
 // En effet, on ne peut pas savoir � partir du thread si notre composant est en runtime.
 FThread.FInterval := 1000; // On d�finit l'intervalle � 1 seconde dans le thread
 FActive := False; // On met la propri�t� Active � False
 FInterval := 1000; // On d�finit l'intervalle � 1 seconde dans le composant
 FPriority := tpNormal; // On d�finit une priorit� normale
 FThread.Priority := tpNormal; // On fait de m�me, mais dans le thread
end;

destructor TThreadComponent.Destroy; // Destruction du composant
begin
 FThread.Terminate; // On demande l'arr�t du thread
 while not FThread.Terminated do ; // Tant que le thread n'est pas termin�, on attend ...
 inherited Destroy; // Puis on laisse Delphi finir la destruction du composant.
end;

{-------------------------------------------------------------------------------
------------------------------- TTHREADLISTEX ----------------------------------
-------------------------------------------------------------------------------}

constructor TThreadListEx.Create; // Cr�ation de la classe
begin
 inherited Create; // Cr�ation inh�rit�e de la classe
 FList := TList.Create; // Cr�ation de la liste de pointeurs
end;

destructor TThreadListEx.Destroy; // Destruction de la classe
Var
 I: Integer; // Variable de contr�le de boucle
begin
 for I := 0 to FList.Count - 1 do // Pour chaque thread dans la liste
  TThreadComponent(FList.Items[I]^).Free; // On lib�re chacun des threads
 FList.Free; // Finalement, on lib�re la liste de pointeurs
 inherited Destroy; // Puis on d�truit la classe
end;

function TThreadListEx.GetCount: Cardinal; // R�cup�re le nombre d'�l�ments dans la liste
begin
 Result := FList.Count; // R�cup�re directement le r�sultat dans la liste de pointeurs
end;

function TThreadListEx.GetCapacity: Cardinal; // Getter Capacity
begin
 Result := FList.Capacity; // R�cup�re directement le r�sultat dans la liste de pointeurs
end;

procedure TThreadListEx.SetCapacity(Value: Cardinal); // Setter Capacity
begin
 FList.Capacity := Value; // Attention aux erreurs d'allocation m�moire EOutOfMemory !
end;

function TThreadListEx.GetThread(Index: Integer): TThreadComponent; // Getter Threads
begin
 Result := TThreadComponent(FList.Items[Index]^); // On le r�cup�re de la liste
end;

function TThreadListEx.AddNew: TThreadComponent; // Ajoute un nouveau thread
begin
 Result := TThreadComponent.Create(nil); // Cr�e un nouveau thread
 FList.Add(@Result); // Ajoute cet objet dans la liste, � la fin
end;

procedure TThreadListEx.Add(var Thread: TThreadComponent); // Ajoute un thread d�j� cr��
begin
 if Assigned(Thread) then FList.Add(@Thread); // Si l'objet thread existe, on l'ajoute
end;

procedure TThreadListEx.Insert(At: Integer; var Thread: TThreadComponent); // Ins�re un thread dans la liste
begin
 if Assigned(Thread) then FList.Insert(At, @Thread); // Si l'objet thread existe, on l'ins�re
end;

function TThreadListEx.Extract(At: Integer): TThreadComponent; // Supprime un thread sans le terminer
begin
 Result := TThreadComponent(FList.Items[At]^); // On r�cup�re le thread
 FList.Items[At] := nil; // On le retire de la liste
end;

procedure TThreadListEx.Delete(At: Integer); // Supprime un thread de la liste
begin
 TThreadComponent(FList.Items[At]).Free; // On termine le thread
 FList.Delete(At); // La liste le supprime
end;

procedure TThreadListEx.SetNil(At: Integer); // "Gomme" un thread sans le supprimer de la liste
begin
 TThreadComponent(FList.Items[At]).Free; // On termine le thread
 FList.Items[At] := nil; // L'objet n'existera plus mais occupera toujours une place dans la liste ...
 // ... en tant que nil.
end;

procedure TThreadListEx.Exchange(Src, Dest: Integer); // On �change 2 threads de place dans la liste
begin
 FList.Exchange(Src, Dest); // La liste poss�de une m�thode pour pouvoir le faire ais�ment
end;

procedure TThreadListEx.Pack; // Compression et nettoyage de la liste
begin
 FList.Pack; // On enl�ve toutes les r�f�rences � nil
end;

procedure TThreadListEx.Clear; // Elimine tous les threads de la liste
Var
 I: Integer; // Variable de contr�le de boucle
begin
 for I := 0 to FList.Count - 1 do // Pour chaque thread dans la liste
  TThreadComponent(FList.Items[I]).Free; // On lib�re chacun des threads
 FList.Clear; // Pour finir, on nettoie la liste de pointeurs totalement !
end;

end.
 