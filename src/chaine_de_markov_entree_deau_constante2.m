
% L = taille maximale de la retenue du barrage.
% o = taille maximale de l'ouverture des conduites forcées.
% N = durée de la période de production d'électricité.
% W = entrée d'eau journalière, dans le barrage.
% nbr_detats = Nombre de valeurs d'entree d'eau possible.
% vol_depart = valeur arbitraire du volume présent dans le barrage au depart, pour pouvoir construire le graphe.
% entree_deau_depart = valeur de l'entrée le premier jour, celle qui débute la chaîne de markov, donc la simulation.
% P_H_Pleine = Prix de l'électricité, en heure pleine.
% P_H_Creuse = Prix de l'électricité, en heure creuse.
% Periode_H = Période entre les changements de tarifs, heures pleines et heures creuses.

% Appel à la fonction Optimise:
[production,controles,U]=Optimise(100,15,100,15,0,7,0.1841,0.1470,10)

function [prod_max,programme,U]=Optimise(L,o,N,nbr_detats,vol_depart,entree_deau_depart,P_H_Pleine,P_H_Creuse,Periode_H)
    % Données
    rho=1000;                       
    g=9.80665;
    mu=0.75;
    % Définition des matrices
    V=zeros(N+1,L+1,nbr_detats+1);          % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1,nbr_detats+1);          % Matrices des valeurs des contrôles, liées aux valeurs de production, coefficient par coefficient.
    Volume=[0:L];                           % Vecteur des valeurs des niveaux de remplissages du barrage.
    Controle=[0:o];                         % Vecteur des tailles d'ouvertures de la conduite forcée.
    Production_elec_prix=ones(1,N+1);       % Vecteur des valeurs de production d'électricité en prix, en fonction du temps.
    Production_elec=ones(1,N+1);            % Vecteur des valeurs de production d'électricité, en fonction du temps.
    Production_elec_prix_cumulee=ones(1,N+1);        % Vecteur des valeurs des gains cumulés en prix, en fonction du temps.
    Entree_deau=[0:nbr_detats];             % Vecteur discrétisé, des différentes valeurs d'entrées d'eau possibles, dans le barrage. 
    % Construction de la matrice de transition de la chaîne de markov.
    P=eye(nbr_detats);
    % Construction du vecteur des prix de l'électricité, en fonction du temps:
    Prix=[];                        % Vecteur des prix.
    Compteur=0;
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
    for i=N:-1:1                        % Boucle pour le temps
        for j=1:L+1                     % Boucle pour le volume
            for l=1:nbr_detats          % Boucle pour l'entrée d'eau
                possible=zeros(1,o+1);
                for u=1:o+1             % Boucle pour les contrôles possibles.
                    if(Volume(j)-Controle(u)+Entree_deau(l)>=0)
                        esperance=0;
                        for k=1:nbr_detats  % Seconde Boucle pour l'entrée d'eau
                            esperance=esperance+P(l,k)*V(i+1,round(max(min(L,Volume(j)+k-Controle(u)),1)),l); % Calcul de l'espérance.
                        end
                        possible(1,u)=Volume(j)*rho*g*mu*Controle(u)*Prix(i)+esperance;
                    end
                end
                [V(i,j,l),indice]=max(possible);
                U(i,j,l)=Controle(indice);
            end
        end
    end
    [prod_max,rang]=max(V(1,:,:));
    % Construction de la chaîne de markov, à partir de P et de entree_deau_depart:
    [chaine]=cree_chaine_markov(N+1,nbr_detats+1,entree_deau_depart);   % On met nombre d'états +1, ccar on considère aussi l'état 0.
    % Construction des vecteurs des CONTROLES OPTIMAUX Controle_opt et des VOLUMES OPTIMAUX Volume_opt, grâce aux matrices U et V.
    Controle_opt=zeros(1,N+1);
    Controle_opt(1)=U(1,vol_depart+1,entree_deau_depart+1);
    vol_courant=zeros(1,N+1);
    vol_courant(1)=vol_depart;
    Production_elec(1)=vol_courant(1)*rho*g*mu*Controle_opt(1);
    Production_elec_prix(1)=vol_courant(1)*rho*g*mu*Controle_opt(1)*Prix(i);
    Production_elec_prix_cumulee(1)=Production_elec_prix(1);
    for i=2:N+1
        vol_courant(i)=max(min(L,vol_courant(i-1)+Entree_deau(chaine(i-1)+1)-Controle_opt(i-1)),0);
        Controle_opt(i)=U(i,round(vol_courant(i))+1,chaine(i)+1);
        Production_elec(i)=vol_courant(i)*rho*g*mu*Controle_opt(i);
        Production_elec_prix(i)=vol_courant(i)*rho*g*mu*Controle_opt(i)*Prix(i);
        for j=i:N+1
            Production_elec_prix_cumulee(j)=Production_elec_prix_cumulee(j)+Production_elec_prix(i);
        end
    end
    % Récupération des résultats
    programme=Controle_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    % Test fonction sinusoïdale:
    x=[0:N];    % Vecteur abscisses du temps.
    clf
    hold on         
    subplot(3,1,1);
    plot(x,vol_courant,'blue');    % Graphe du volume d'eau, du barrage.
    title('Volume d eau du barrage, en fonction du temps')
    subplot(3,1,2);
    plot(x,chaine,'cyan');
    title('Entrée d eau, en fonction du temps')
    subplot(3,1,3);
    plot(x,Prix,'red');
    title('Prix de l électricité, en fonction du temps')
    hold off
    figure(2)
    clf
    hold on
    subplot(3,1,1);
    plot(x,Production_elec_prix_cumulee,'green');
    title('Gain cumulé, en fonction du temps')
    subplot(3,1,2);
    plot(x,Production_elec_prix,'magenta');
    title('Production électrique en prix, en fonction du temps')
    subplot(3,1,3);
    plot(x,Controle_opt,'black');    
    title('Controles appliqués, en fonction du temps')
    hold off
end 

% n=longueur de la chaine de markov.
% nbr_detats=nombre d'états que le système peut atteindre.
% etat_initial=état initial du système.

function [W]=cree_chaine_markov(n,nbr_detats,etat_initial)
    % On génère la matrice P de transition:
    P=eye(nbr_detats);
    % On initialise l'état initial de notre système:
    W=[etat_initial];
    % Algorithme de génération:
    for i=1:n-1
        aleatoire=rand;
        j=W(i)+1;    
        somme=P(j,1);
        compteur=1;
        while (somme<=aleatoire) && (compteur<nbr_detats)
            compteur=compteur+1;
            somme=somme+P(j,compteur);
        end
        W(i+1)=compteur-1;
    end
end