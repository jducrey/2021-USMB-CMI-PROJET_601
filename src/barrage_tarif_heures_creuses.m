
% L = taille maximale de la retenue du barrage.
% o = taille maximale de l'ouverture des conduites forcées.
% N = durée de la période de production d'électricité.
% type_entree_deau = type d'entée d'eau, au choix entre "périodique" et "crue".
% vol_depart = valeur arbitraire du volume présent dans le barrage au
% depart, pour pouvoir construire le graphe.
% P_H_Pleine = Prix de l'électricité, en heure pleine.
% P_H_Creuse = Prix de l'électricité, en heure creuse.
% Periode_H = Période entre les changements de tarifs, heures pleines et heures creuses.

% Appel à la fonction Optimise:
[production,controles,U]=Optimise(100,15,100,"periodique",80,20,1,10)

function [prod_max,programme,U]=Optimise(L,o,N,type_entree_deau,vol_depart,P_H_Pleine,P_H_Creuse,Periode_H)
    % Données
    rho=1000;                       
    g=9.80665;
    mu=0.75;
    % Définition des matrices
    V=zeros(N+1,L+1);               % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1);               % Matrices des valeurs des contrôles, liées aux valeurs de production.
    Volume=[0:L];                   % Vecteur des valeurs des niveaux de remplissages du barrage.
    Controle=[0:o];                 % Vecteur des tailles d'ouvertures de la conduite forcée.
    Production_elec_prix=ones(1,N+1);   % Vecteur des valeurs de production d'électricité en prix, en fonction du temps.
    Production_elec_prix_cumulee=ones(1,N+1);    % Vecteur des valeurs des gains cumulés en prix, en fonction du temps.
    % Construction du vecteur des entrées d'eau:
    W=[];                           % Vecteur des entrées d'eau.
    if type_entree_deau=="periodique"
        for i=0:N
            W(i+1)=(L/32)+(L/64)*cos((N/1)*i);
        end
    elseif type_entree_deau=="crue"
        for i=0:N
            W(i+1)=4+(N/4)*exp(-(i-(N/2))^2/(N/4));
        end
    end
    % Construction du vecteur des prix de l'électricité, en fonction du temps:
    Prix=[];                        % Vecteur des prix.
    Compteur=1;
    Changement=false;
    for i=0:N
        if Compteur==Periode_H
            Compteur=0;
            Changement=not(Changement);
        end
        if Changement
            Prix(i+1)=P_H_Pleine;
        else
            Prix(i+1)=P_H_Creuse;
        end
        Compteur=Compteur+1;
    end
    % Construction des Matrices U et V, par remontée.  
    for i=N:-1:1                    % Boucle pour le temps
        for j=1:L+1                 % Boucle pour le volume
            possible=zeros(1,o+1);
            for k=1:o+1             % Boucle pour les contrôles possibles.
                if(Volume(j)+W(i)-Controle(k)>=0)  % Vérifie que le contrôle est physiquement possible, il reste de l'eau.
                    possible(1,k) = Volume(j)*rho*g*mu*Controle(k)*Prix(i) + V(i+1,round(max(min(L,Volume(j)+W(i)-Controle(k)),1)));
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
    Production_elec_prix(1)=vol_courant(1)*rho*g*mu*Controle_opt(1)*Prix(i);
    Production_elec_prix_cumulee(1)=Production_elec_prix(1);
    for i=2:N+1
        vol_courant(i)=max(min(L,vol_courant(i-1)+W(i)-Controle_opt(i-1)),0);
        Controle_opt(i)=U(i,round(vol_courant(i))+1);
        Production_elec_prix(i)=vol_courant(i)*rho*g*mu*Controle_opt(i)*Prix(i);
        for j=i:N+1
            Production_elec_prix_cumulee(j)=Production_elec_prix_cumulee(j)+Production_elec_prix(i);
        end
    end
    % Récupération des résultats
    programme=Controle_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    % Test fonction sinusoïdale:
    x=[0:N];                                % Vecteur abscisses du temps.
    clf
    hold on         
    subplot(3,1,1);
    plot(x,vol_courant,'red');    % Graphe du volume d'eau, du barrage.
    title('Volume d eau du barrage, en fonction du temps')
    subplot(3,1,2);
    plot(x,Prix,'blue');
    title('Prix de l électricité, en fonction du temps')
    subplot(3,1,3);
    plot(x,W,'green');
    title('Entrée d eau, en fonction du temps')
    hold off
    figure(2)
    clf
    hold on
    subplot(3,1,1);
    plot(x,Production_elec_prix_cumulee,'blue');
    title('Production total cumulée, en fonction du temps')
    subplot(3,1,2);
    plot(x,Production_elec_prix,'magenta');
    title('Production instannée en prix, en fonction du temps')
    subplot(3,1,3);
    plot(x,Controle_opt,'green');
    title('Contrôles appliqués, en fonction du temps')
    hold off
end 