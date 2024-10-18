
% L = taille maximale de la retenue du barrage.
% o = taille maximale de l'ouverture des conduites forcées.
% N = durée de la période de production d'électricité.
% vol_depart = valeur arbitraire du volume présent dans le barrage au
% depart, pour pouvoir construire le graphe.

% Appel à la fonction Optimise:
[production,controles]=Optimise(100,20,100,70)

function [prod_max,programme]=Optimise(L,o,N,vol_depart)
    % Données
    rho=1000;                       
    g=9.80665;
    mu=0.75;
    % Définition des matrices
    V=zeros(N+1,L+1);               % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1);               % Matrices des valeurs des contrôles, liées aux valeurs de production, coefficient par coefficient.
    Volume=[0:L];                   % Vecteur des valeurs des niveaux de remplissages du barrage.
    Controle=[0:o];                 % Vecteur des tailles d'ouvertures de la conduite forcée.
    % Construction du vecteur des entrées d'eau:
    W=[];                           % Vecteur des entrées journalières.
    for i=0:N
        W(i+1)=5+50*exp(-(i-(N/2))^2/(N/2));
    end
    % Construction des Matrices U et V, par remontée.  
    for i=N:-1:1                    % Boucle pour le temps
        for j=1:L+1                 % Boucle pour le volume
            possible=zeros(1,o+1);
            for k=1:o+1             % Boucle pour les contrôles possibles.
                if(Volume(j)+W(i)-Controle(k)>=0)  % Pour être sûr que le contrôle est physiquement possible, reste de l'eau dans retenue.
                    possible(1,k) = Volume(j)*rho*g*mu*Controle(k) + V(i+1,round(max(min(L,Volume(j)+W(i)-Controle(k)),1)));
                end
            end
            [V(i,j),indice]=max(possible);
            U(i,j)=Controle(indice); % Décallage, pour avoir le controle u=0, à cause de l'indexation des tableaux dans Matlab.
        end
    end
    [prod_max,rang]=max(V(1,:));
    % Construction des vecteurs des CONTROLES OPTIMAUX Controle_opt et des VOLUMES OPTIMAUX Volume_opt, grâce aux matrices U et V.
    Controle_opt=zeros(1,N+1);
    Controle_opt(1)=U(1,vol_depart);
    vol_courant=zeros(1,N+1);
    vol_courant(1)=vol_depart;
    for i=2:N+1
        vol_courant(i)=max(min(L,vol_courant(i-1)+W(i)-Controle_opt(i-1)),0);
        Controle_opt(i)=U(i,round(vol_courant(i))+1);
    end
    % Récupération des résultats
    programme=Controle_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    % Test de la fonction crue:
    x=[0:N];                                % Vecteur abscisses du temps.
    clf
    hold on
    subplot(2,1,1);
    plot(x,W,'blue')                               % Graphe de la sinusoïde.
    hold on
    plot(x,vol_courant,'green');                    % Graphe du volume d'eau, du barrage.
    hold off
    title('Volume et entrée d eau, en fonction du temps')
    subplot(2,1,2);
    plot(x,Controle_opt,'red')
    title('Controles appliqués, en fonction du temps')
    hold off
end 