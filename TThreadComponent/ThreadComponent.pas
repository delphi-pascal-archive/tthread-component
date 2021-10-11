{                                  THREAD COMPONENT

Auteur : Bacterius

Ce composant permet d'introduire facilement un thread dans votre application.
Une notion interessante et utile qui est mise en application dans ce composant
est la "monodépendance". Je m'explique : ici, le composant encapsulant le thread
a bien sûr accès au thread. Mais la réciproque n'est pas vraie ! Le thread n'a pas
accès au composant qui l'encapsule. C'est pourquoi l'on est obligé de stocker
quelques variables dans le thread lui-même, ainsi que dans le composant (pour
pouvoir gérer les propriétés du composant, ET pour pouvoir laisser au thread l'accès
à des informations indispensables à son fonctionnement correct, tels l'intervalle
ou encore la priorité demandée par l'utilisateur du composant).

Remarque : Le paramètre Sender des différents évènements de ce composant n'est
pas le même selon les évènements. Voici un tableau de correspondance :

           _______________________________________________________
          |        Evènement        |       Paramètre Sender      |
          | ________________________|_____________________________|
          |       OnExecute         |          TThread            |
          |       OnResume          |      TThreadComponent       |
          |       OnSuspend         |      TThreadComponent       |
          |_________________________|_____________________________|

La raison de cette différence dans OnExecute est que le gestionnaire OnExecute
est appelé par le thread et non par le composant encapsulant le thread (contrairement
aux deux autres évènements OnResume et OnSuspend).



De plus, un type TThreadComponentList est fourni pour gérer une liste de threads,
à laquelle vous pouvez bien sûr ajouter, retirer et gérer des threads.
Notez que le fait de retirer un thread par les méthodes Delete ou Clear ou Free
a pour effet de terminer ce thread afin de ne pas le laisser hors de contrôle.
Pour ne pas terminer le thread (le garder en fonctionnement tout en le retirant
de la liste), utilisez la méthode Extract.

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
    FRuntimeCheck: TRuntimeCheck; // Fonction de liaison à IsRuntime dans le composant
    procedure CentralControl; // Méthode principale du thread
  protected
    procedure Execute; override; // Boucle principale du thread
  end;

  TThreadComponent = class(TComponent) // Le composant encapsulant le thread
  private
    FThread: TMyThread; // Le thread à encapsuler
    FInterval: Cardinal; // L'intervalle
    FActive: Boolean; // L'état (actif/inactif)
    FPriority: TThreadPriority; // La priorité du thread
    FOnSuspend: TNotifyEvent; // Le gestionnaire OnSuspend
    FOnResume: TNotifyEvent; // Le gestionnaire OnResume
    FOnExecute: TNotifyEvent; // Le gestionnaire OnExecute
    procedure SetInterval(Value: Cardinal); // Setter pour la propriété Interval
    procedure SetPriority(Value: TThreadPriority); // Setter pour la propriété Priority
    procedure SetActive(Value: Boolean); // Setter pour la propriété Active
    procedure SetOnExecute(Value: TNotifyEvent); // Setter pour le gestionnaire OnExecute
    function GetThreadHandle: Cardinal; // Getter pour le handle du thread
    function GetThreadID: Cardinal; // Getter pour l'identificateur du thread
    function IsRuntime: Boolean; // Fonction pour savoir si le composant est en runtime
  public
    constructor Create(AOwner: TComponent); override; // Constructeur surchargé
    destructor Destroy; override; // Destructeur surchargé
  published
    property Interval: Cardinal read FInterval write SetInterval; // Propriété Interval
    property Priority: TThreadPriority read FPriority write SetPriority; // Propriété Priority
    property Active: Boolean read FActive write SetActive; // Propriété Active
    property ThreadHandle: Cardinal read GetThreadHandle; // Propriété ThreadHandle
    property ThreadID: Cardinal read GetThreadID; // Propriété ThreadID
    property OnSuspend: TNotifyEvent read FOnSuspend write FOnSuspend; // Gestionnaire OnSuspend
    property OnResume: TNotifyEvent read FOnResume write FOnResume; // Gestionnaire OnResume
    property OnExecute: TNotifyEvent read FOnExecute write SetOnExecute; // Gestionnaire OnExecute
  end;

  PThreadComponent = ^TThreadComponent; // Pointeur sur le type TThreadComponent

procedure Register; // Procédure de recensement du composant

{-------------------------------------------------------------------------------
------------------------------- TTHREADLISTEX ----------------------------------
-------------------------------------------------------------------------------}

type TThreadListEx = class // Classe TThreadListEx
 private
  FList: TList; // La liste de pointeurs privée
  function GetCount: Cardinal; // Getter Count
  function GetCapacity: Cardinal; // Getter Capacity
  procedure SetCapacity(Value: Cardinal); // Setter Capacity
  function GetThread(Index: Integer): TThreadComponent; // Getter Threads
 public
  constructor Create; reintroduce; // Constructeur réintroduit pour la classe
  destructor Destroy; override; // Destructeur surchargé
  function AddNew: TThreadComponent; // Ajoute un nouveau thread
  procedure Add(var Thread: TThreadComponent); // Ajoute un thread déjà créé
  procedure Insert(At: Integer; var Thread: TThreadComponent); // Insère un thread dans la liste
  function Extract(At: Integer): TThreadComponent; // Supprime un thread sans le terminer
  procedure Delete(At: Integer); // Supprime un thread de la liste
  procedure SetNil(At: Integer); // "Gomme" un thread sans le supprimer de la liste
  procedure Exchange(Src, Dest: Integer); // On échange 2 threads de place dans la liste
  procedure Pack; // Compression et nettoyage de la liste
  procedure Clear; // Elimine tous les threads de la liste
  property Count: Cardinal read GetCount; // Propriété Count (nombre de threads dans la liste)
  property Capacity: Cardinal read GetCapacity write SetCapacity; // Propriété Capacity
  property Threads[Index: Integer]: TThreadComponent read GetThread; // Propriété tableau Threads
 end;

implementation

procedure Register; // Procédure de recensement du composant
begin
  RegisterComponents('Système', [TThreadComponent]);
  // Recensement de TThreadComponent dans la page Système.
end;

procedure TMyThread.CentralControl; // Méthode principale
begin
 if (FRuntimeCheck) and Assigned(FOnExecute) then FOnExecute(self);
 // Si on est en runtime et que le gestionnaire OnExecute est assigné, on execute ce dernier
end;

procedure TMyThread.Execute; // Boucle du thread
begin
 repeat  // On répète l'execution du thread ...
  Sleep(FInterval); // On attend l'intervalle demandé
  Application.ProcessMessages;  // On laisse l'application traiter ses messages
  Synchronize(CentralControl); // On synchronise avec la méthode principale
 until Terminated; // ... jusqu'à ce que le thread soit terminé
end;

function TThreadComponent.IsRuntime: Boolean; // Vérifie si le composant est un runtime
begin
 Result := not (csDesigning in ComponentState);
 // csDesigning indique que l'on est en mode conception
end;

procedure TThreadComponent.SetOnExecute(Value: TNotifyEvent); // On définit le gestionnaire OnExecute
begin
 if @Value <> @FOnExecute then // Si on a changé de gestionnaire ...
  begin
   FOnExecute := Value; // On change le gestionnaire
   FThread.FOnExecute := Value; // On le change aussi dans le thread
  end;
end;

procedure TThreadComponent.SetInterval(Value: Cardinal); // On définit l'intervalle du thread
begin
 if Value <> FInterval then // Si l'intervalle a changé
  begin
   FInterval := Value; // On change la propriété
   FThread.FInterval := Value; // Et on change aussi la variable dans le thread
  end;
end;

procedure TThreadComponent.SetPriority(Value: TThreadPriority); // On définit la priorité du thread
begin
 if Value <> FPriority then // Si la priorité a changé
  begin
   FPriority := Value; // On change la propriété
   FThread.Priority := Value; // Et on change réellement la priorité du thread
  end;
end;

procedure TThreadComponent.SetActive(Value: Boolean); // On définit l'état du thread
begin
 if Value <> FActive then // Si on change d'état
  begin
   FActive := Value; // On change la propriété
   case FActive of // Selon le nouvel état ...
    False: // Désactivé
     begin
      FThread.Suspend; // On arrête le thread
      if (IsRuntime) and (Assigned(FOnSuspend)) then FOnSuspend(self);
      // Si on a défini un gestionnaire OnSuspend et que l'on est en runtime, on lance ce gestionnaire
     end;
    True: // Activé
     begin
      FThread.Resume; // On reprend l'execution du thread
      if (IsRuntime) and (Assigned(FOnResume)) then FOnResume(self);
      // Si on a défini un gestionnaire OnResume et que l'on est en runtime, on lance ce gestionnaire
     end;
   end;
  end;
end;

function TThreadComponent.GetThreadHandle: Cardinal; // On récupère le handle du thread
begin
 Result := FThread.Handle; // Ce handle peut être utilisé dans des APIs concernant les threads
end;

function TThreadComponent.GetThreadID: Cardinal; // On récupère l'identificateur du thread
begin
 Result := FThread.ThreadID; // Peut être utilisé également dans certaines APIs
end;

constructor TThreadComponent.Create(AOwner: TComponent); // Création du composant
begin
 inherited Create(AOwner); // On laisse Delphi faire le sale boulot à notre place ...
 FThread := TMyThread.Create(True); // On crée le thread arrêté
 FThread.FRuntimeCheck := IsRuntime; // On établit une liaison entre la fonction de
 // vérification du runtime dans le composant avec une fonction similaire du thread.
 // En effet, on ne peut pas savoir à partir du thread si notre composant est en runtime.
 FThread.FInterval := 1000; // On définit l'intervalle à 1 seconde dans le thread
 FActive := False; // On met la propriété Active à False
 FInterval := 1000; // On définit l'intervalle à 1 seconde dans le composant
 FPriority := tpNormal; // On définit une priorité normale
 FThread.Priority := tpNormal; // On fait de même, mais dans le thread
end;

destructor TThreadComponent.Destroy; // Destruction du composant
begin
 FThread.Terminate; // On demande l'arrêt du thread
 while not FThread.Terminated do ; // Tant que le thread n'est pas terminé, on attend ...
 inherited Destroy; // Puis on laisse Delphi finir la destruction du composant.
end;

{-------------------------------------------------------------------------------
------------------------------- TTHREADLISTEX ----------------------------------
-------------------------------------------------------------------------------}

constructor TThreadListEx.Create; // Création de la classe
begin
 inherited Create; // Création inhéritée de la classe
 FList := TList.Create; // Création de la liste de pointeurs
end;

destructor TThreadListEx.Destroy; // Destruction de la classe
Var
 I: Integer; // Variable de contrôle de boucle
begin
 for I := 0 to FList.Count - 1 do // Pour chaque thread dans la liste
  TThreadComponent(FList.Items[I]^).Free; // On libère chacun des threads
 FList.Free; // Finalement, on libère la liste de pointeurs
 inherited Destroy; // Puis on détruit la classe
end;

function TThreadListEx.GetCount: Cardinal; // Récupère le nombre d'éléments dans la liste
begin
 Result := FList.Count; // Récupère directement le résultat dans la liste de pointeurs
end;

function TThreadListEx.GetCapacity: Cardinal; // Getter Capacity
begin
 Result := FList.Capacity; // Récupère directement le résultat dans la liste de pointeurs
end;

procedure TThreadListEx.SetCapacity(Value: Cardinal); // Setter Capacity
begin
 FList.Capacity := Value; // Attention aux erreurs d'allocation mémoire EOutOfMemory !
end;

function TThreadListEx.GetThread(Index: Integer): TThreadComponent; // Getter Threads
begin
 Result := TThreadComponent(FList.Items[Index]^); // On le récupère de la liste
end;

function TThreadListEx.AddNew: TThreadComponent; // Ajoute un nouveau thread
begin
 Result := TThreadComponent.Create(nil); // Crée un nouveau thread
 FList.Add(@Result); // Ajoute cet objet dans la liste, à la fin
end;

procedure TThreadListEx.Add(var Thread: TThreadComponent); // Ajoute un thread déjà créé
begin
 if Assigned(Thread) then FList.Add(@Thread); // Si l'objet thread existe, on l'ajoute
end;

procedure TThreadListEx.Insert(At: Integer; var Thread: TThreadComponent); // Insère un thread dans la liste
begin
 if Assigned(Thread) then FList.Insert(At, @Thread); // Si l'objet thread existe, on l'insère
end;

function TThreadListEx.Extract(At: Integer): TThreadComponent; // Supprime un thread sans le terminer
begin
 Result := TThreadComponent(FList.Items[At]^); // On récupère le thread
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

procedure TThreadListEx.Exchange(Src, Dest: Integer); // On échange 2 threads de place dans la liste
begin
 FList.Exchange(Src, Dest); // La liste possède une méthode pour pouvoir le faire aisément
end;

procedure TThreadListEx.Pack; // Compression et nettoyage de la liste
begin
 FList.Pack; // On enlève toutes les références à nil
end;

procedure TThreadListEx.Clear; // Elimine tous les threads de la liste
Var
 I: Integer; // Variable de contrôle de boucle
begin
 for I := 0 to FList.Count - 1 do // Pour chaque thread dans la liste
  TThreadComponent(FList.Items[I]).Free; // On libère chacun des threads
 FList.Clear; // Pour finir, on nettoie la liste de pointeurs totalement !
end;

end.
 