
% L = taille maximale de la retenue du barrage.
% o = taille maximale de l'ouverture des conduites forcées.
% N = durée de la période de production d'électricité.
% W = entrée d'eau journalière, dans le barrage.
% vol_depart = valeur arbitraire du volume présent dans le barrage au
% depart, pour pouvoir construire le graphe.

[production,controles]=Optimise(100,10,100,11,1)

function [prod_max,programme]=Optimise(L,o,N,W,vol_depart)
    % Données
    rho=1000;                       
    g=9.80665;
    mu=0.75;
    % Définition des matrices
    V=zeros(N+1,L+1);               % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1);               % Matrices des valeurs des contrôles, liées aux valeurs de production, coefficient par coefficient.
    Volume=[0:L];                   % Vecteur des valeurs des niveaux de remplissages du barrage.
    Controle=[0:o];
    % Construction des Matrices U et V, par remontée.  
    for i=N:-1:1                    % Boucle pour le temps
        for j=1:L+1                 % Boucle pour le volume
            possible=zeros(1,o+1);
            for k=1:o+1             % Boucle pour les contrôles possibles.
                if(Volume(j)+W-Controle(k)>=0)  % Pour être sûr que le contrôle est physiquement possible, il reste de l'eau dans le barrage.
                    possible(1,k) = Volume(j)*rho*g*mu*Controle(k) + V(i+1,max(min(L,Volume(j)+W-Controle(k)),1));
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
        vol_courant(i)=max(min(L,vol_courant(i-1)+W-Controle_opt(i-1)),0);
        Controle_opt(i)=U(i,vol_courant(i)+1);
    end
    % Récupération des résultats
    programme=Controle_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    plot(0:N,vol_courant);
end 
