% L = taille maximale de la retenue principale du barrage.
% L2 = taille maximale de la retenue secondaire du barrage.
% o = taille maximale de l'ouverture des conduites forcées, de la retenue principale.
% T = taille maximale de l'ouverture du canal de transfert, de la retenue secondaire.
% N = durée totale de la période de production d'électricité.
% type_retenue1 = sélectionne le type d'entrée d'eau dans la retenue, les valeurs possibles sont "periodique" ou "crue".
% type_retenue2 = sélectionne le type d'entrée d'eau dans la retenue, les valeurs possibles sont "periodique" ou "crue".
% nbr_detats1 = Nombre de valeurs d'entree d'eau possible, pour la pluie, sur la retenue 1.
% nbr_detats2 = Nombre de valeurs d'entree d'eau possible, pour la pluie, sur la retenue 2.
% entree_deau_depart1 = valeur de l'entrée le premier jour, celle qui débute la chaîne de markov, pour la retenue 1.
% entree_deau_depart2 = valeur de l'entrée le premier jour, celle qui débute la chaîne de markov, pour le retenue 2.
% vol_depart = valeur arbitraire du volume présent dans le barrage au depart, pour pouvoir construire le graphe.
% vol_reserve_depart = valeur arbitraire du volume au départ, dans la seconde retenue du barrage.
% P_H_Pleine = Prix de l'électricité, en heure pleine.
% P_H_Creuse = Prix de l'électricité, en heure creuse.
% Periode_H = Période entre les changements de tarifs, heures pleines et heures creuses.


% Appel à la fonction Optimise:
[production,prog1,prog2]=Optimise_Production(10,10,2,3,25,"crue","crue",3,2,3,2,2,2,0.18,0.04,2)

function [prod_max,Programme1,Programme2]=Optimise_Production(L,L2,o,T,N,type_retenue1,type_retenue2,nbr_detats1,entree_deau_depart1,nbr_detats2,entree_deau_depart2,vol_depart,vol_reserve_depart,P_H_Pleine,P_H_Creuse,Periode_H)
    % Données
    rho=1000;                      
    g=9.80665;
    mu1=0.8;
    mu2=0.2;
    % Définition des matrices
    V=zeros(N+1,L+1,L2+1,nbr_detats1+1,nbr_detats2+1);       % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1,L2+1,nbr_detats1+1,nbr_detats2+1);       % Matrices des valeurs de contrôles, pour la retenue principale.
    U2=zeros(N+1,L+1,L2+1,nbr_detats1+1,nbr_detats2+1);      % Matrices des valeurs de transferts, entre la retenue secondaire et la retenue principale.
    Volume=0:L;           % Vecteur des valeurs des niveaux de remplissages, de la retenue principale du barrage.
    Volume2=0:L2;         % Vecteur des valeurs des niveaux de remplissages, de la retenue secondaire du barrage.
    Controle=0:o;         % Vecteur des tailles d'ouvertures de la conduite forcée.
    Transfert=0:T;        % Vecteur des valeurs possibles de transferts entre la retenue principale et secondaire.
    Production_elec=ones(1,N+1);            % Vecteur des valeurs de production d'électricité, en fonction du temps.
    Production_elec_Prix=ones(1,N+1);       % Vecteur des valeurs de production d'électricité, en prix, en fonction du temps.
    Production_elec_cumulee=ones(1,N+1);    % Vecteur des valeurs des gains de production cumulés, en prix, en fonction du temps.
    Entree_deau1=[0:nbr_detats1];           % Vecteur discrétisé, des différentes valeurs d'entrées d'eau possibles, dans la retenue 1.
    Entree_deau2=[0:nbr_detats2];           % Vecteur discrétisé, des différentes valeurs d'entrées d'eau possibles, dans la retenue 2.
    % Construction des matrices de transitions des chaînes de markov.
    % matrice pour la retenue 1:
    P=0.8*eye(nbr_detats1+1);
    P=P+diag(0.1*ones(1,nbr_detats1),1);
    P=P+diag(0.1*ones(1,nbr_detats1),-1);
    P(1,1)=0.9;P(nbr_detats1+1,nbr_detats1+1)=0.9;
    % matrice pour la retenue 2:
    P2=0.8*eye(nbr_detats2+1);
    P2=P2+diag(0.1*ones(1,nbr_detats2),1);
    P2=P2+diag(0.1*ones(1,nbr_detats2),-1);
    P2(1,1)=0.9;P2(nbr_detats2+1,nbr_detats2+1)=0.9;
    % Construction des vecteurs des entrées d'eau des rivières:
    W1=zeros(1,N+1);                           % Vecteurs des entrées des rivières.
    W2=zeros(1,N+1);
    if(type_retenue1=="crue")
        for i=0:N
            W1(i+1)=0+(L/4)*exp(-(i-(N/2))^2/(N/4));
        end
    elseif(type_retenue1=="periodique")
        for i=0:N
            W1(i+1)=(L/8)+(L/8)*cos((6*N)*i);
        end
    else
        for i=0:N
            W1(i+1)=0;
        end 
    end
    if(type_retenue2=="crue")
        for i=0:N
            W2(i+1)=0+(L2/4)*exp(-(i-(N/2))^2/(N/4));
        end
    elseif(type_retenue2=="periodique")
        for i=0:N
            W2(i+1)=(L2/8)+(L2/8)*cos((6*N)*i);
        end
    else
        for i=0:N
            W2(i+1)=0;
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
    for i=N:-1:1            % Boucle sur le temps
        for j=1:L+1         % Boucle sur le volume du barrage
            for k=1:L2+1    % Boucle sur le volume de la retenue
                for l=1:nbr_detats1+1     % Boucle pour l'entrée d'eau, dans la retenue 1.
                    for m=1:nbr_detats2+1 % Boucle pour l'entrée d'eau, dans la retenue 2.
                        optimal2=zeros(o+1,T+1); % Contiendra le maximum par rapport aux transferts, pour chaque controle.
                            for t=1:T+1
                                if(Volume2(k)+W2(i)+Entree_deau2(m)-Transfert(t)>=0)
                                    for u=1:o+1
                                        if(Volume(j)+W1(i)+Entree_deau1(l)-Controle(u)+Transfert(t)>=0)
                                            esperance=0;
                                            for a=1:nbr_detats1+1  % Seconde Boucle pour l'entrée d'eau de la retenue 1
                                                for b=1:nbr_detats2+1 % Seconde Boucle pour l'entrée d'eau de la retenue 2
                                                    esperance=esperance+P(l,a)*P2(m,b)*V(i+1,round(max(min(L,Volume(j)+a+W1(i)-Controle(u)+Transfert(t)),1)),round(max(min(L2,Volume2(k)+b+W2(i)-Transfert(t)),1)),a,b); % Calcul de l'espérance.
                                                end
                                            end
                                            optimal2(u,t)=rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t))*Prix(i) + esperance;
                                        end
                                    end
                                end
                            end
                        V(i,j,k,l,m)=max(max(optimal2));
                        [x,y]=find(optimal2==max(max(optimal2)));
                        U(i,j,k,l,m)=Controle(x(1));
                        U2(i,j,k,l,m)=Transfert(y(1));
                    end
                end
            end
        end
    end
    [prod_max,rang]=max(V(1,:,:,:,:));
    % Construction des chaînes de markov, à partir de P et de entree_deau_depart1 et entree_deau_depart2:
    [chaine1]=cree_chaine_markov(N+1,nbr_detats1+1,entree_deau_depart1);   % On met nombre d'états +1, ccar on considère aussi l'état 0.
    [chaine2]=cree_chaine_markov(N+1,nbr_detats2+1,entree_deau_depart2);   % On met nombre d'états +1, ccar on considère aussi l'état 0.
    % Construction des vecteurs des CONTROLES OPTIMAUX Controle_opt et des VOLUMES OPTIMAUX vol_courant, grâce aux matrices U,U2 et V.
    Controle_opt=zeros(1,N+1);
    Controle_opt(1)=U(1,vol_depart+1,vol_reserve_depart+1,entree_deau_depart1+1,entree_deau_depart2+1);
    Transfert_opt=zeros(1,N+1);
    Transfert_opt(1)=U2(1,vol_depart+1,vol_reserve_depart+1,entree_deau_depart1+1,entree_deau_depart2+1);
    vol_courant=zeros(1,N+1);
    vol_courant(1)=vol_depart;
    vol_reserve=zeros(1,N+1);
    vol_reserve(1)=vol_reserve_depart;
    Production_elec(1)=rho*g*(vol_courant(1)*mu1*Controle_opt(1)+vol_reserve(1)*mu2*Transfert_opt(1));
    Production_elec_Prix(1)=rho*g*(vol_courant(1)*mu1*Controle_opt(1)+vol_reserve(1)*mu2*Transfert_opt(1))*Prix(1);
    Production_elec_cumulee(1)=Production_elec_Prix(1);
    for i=2:N+1
        vol_courant(i)=max(min(L,vol_courant(i-1)+Entree_deau1(chaine1(i-1)+1)+W1(i-1)-Controle_opt(i-1)+Transfert_opt(i-1)),0);
        vol_reserve(i)=max(min(L2,vol_reserve(i-1)+Entree_deau2(chaine2(i-1)+1)+W2(i-1)-Transfert_opt(i-1)),0);
        Controle_opt(i)=U(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,chaine1(i)+1,chaine2(i)+1);
        Transfert_opt(i)=U2(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,chaine1(i)+1,chaine2(i)+1);
        Production_elec(i)=rho*g*(vol_courant(i)*mu1*Controle_opt(i)+vol_reserve(i)*mu2*Transfert_opt(i));
        Production_elec_Prix(i)=rho*g*(vol_courant(i)*mu1*Controle_opt(i)+vol_reserve(i)*mu2*Transfert_opt(i))*Prix(i);
        for j=i:N+1
            Production_elec_cumulee(j)=Production_elec_cumulee(j)+Production_elec_Prix(i);
        end
    end
    % Récupération des résultats
    Programme1=Controle_opt(1:N);
    Programme2=Transfert_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    % Test fonction sinusoïdale:
    x=[0:N];    % Vecteur abscisses du temps.
    clf
    hold on         
    subplot(4,1,1);
    plot(x,vol_courant,'blue');    % Graphe du volume d'eau, du barrage.
    hold on
    plot(x,W1,'magenta')
    hold off
    title('Volume d eau de la retenue principale, en fonction du temps')
    subplot(4,1,2);
    plot(x,vol_reserve,'cyan');
    hold on
    plot(x,W2,'green')
    hold off
    title('volume d eau de la retenue secondaire, en fonction du temps')
    subplot(4,1,3);
    plot(x,Controle_opt,'red');
    title('Controle envoyé à la centrale, en fonction du temps')
    subplot(4,1,4);
    plot(x,Transfert_opt,'black');
    title('Transfert d eau, en fonction du temps')
    hold off 
    figure(2)
    clf
    hold on
    subplot(4,1,1);
    plot(x,Production_elec,'red');
    title('Production électrique, en fonction du temps')
    subplot(4,1,2);
    plot(x,Production_elec_Prix,'blue')
    title('Production électrique en prix, en fonction du temps')
    subplot(4,1,3);
    plot(x,Production_elec_cumulee,'black')
    title('Production électrique cumulée en prix, en fonction du temps')
    subplot(4,1,4);
    plot(x,Prix,'green');
    title('Prix de l électricité, en fonction du temps')
    hold off
    figure(3)
    clf
    hold on
    subplot(2,1,1);
    plot(x,chaine1,'green');
    title('entree deau de pluie, pour la retenue 1, en fonction du temps')
    subplot(2,1,2);
    plot(x,chaine2,'blue')
    title('entree deau de pluie, pour la retenue 2, en fonction du temps')
    hold off
end

% n=longueur de la chaine de markov.
% nbr_detats=nombre d'états que le système peut atteindre.
% etat_initial=état initial du système.

function [W]=cree_chaine_markov(n,nbr_detats,etat_initial)
    % On génère la matrice P de transition:
    P=0.8*eye(nbr_detats);
    P=P+diag(0.1*ones(1,nbr_detats-1),1);
    P=P+diag(0.1*ones(1,nbr_detats-1),-1);
    P(1,1)=0.9;
    P(nbr_detats,nbr_detats)=0.9;
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