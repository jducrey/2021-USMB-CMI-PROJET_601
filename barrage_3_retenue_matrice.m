% L = taille maximale de la retenue principale du barrage.
% L2 = taille maximale de la retenue secondaire du barrage.
% L3 = taille maximale de la retenue tertiaire du barrage.
% o = taille maximale de l'ouverture des conduites forcées, de la retenue principale.
% T = taille maximale de l'ouverture du canal de transfert, de la retenue secondaire.
% S = taille maximale de l'ouverture du canal des apports, de la retenue tertiaire.
% N = durée totale de la période de production d'électricité.
% W1 = entrée d'eau journalière, dans la retenue principale.
% W2 = entrée d'eau journalière, dans la retenue secondaire.
% W3 = entrée d'eau journalière, dans la retenue tertiaire.
% type_graphe = sélectionne le type de liaison entre les 3 retenues, les valeurs possibles sont "arbre" ou "serie".
% vol_depart = valeur arbitraire du volume présent dans le barrage au depart, pour pouvoir construire le graphe.
% vol_reserve_depart = valeur arbitraire du volume au départ, dans la seconde retenue du barrage.
% vol_reserve2_depart = valeur arbitraire du volume au départ, dans la troisième retenue du barrage.

% Appel à la fonction Optimise:
[production,prog1,prog2,prog3]=Optimise_Production(50,25,25,5,7,7,50,2,5,2,"arbre",5,10,10)

function [prod_max,Programme1,Programme2,Programme3]=Optimise_Production(L,L2,L3,o,T,S,N,W1,W2,W3,type_graphe,vol_depart,vol_reserve_depart,vol_reserve2_depart)
% Données
    rho=1000;                      
    g=9.80665;
    mu1=0;
    mu2=0;
    mu3=0.8;
    %x=1;
    %y=1;
    %z=1;
    % Définition des matrices
    V=zeros(N+1,L+1,L2+1,L3+1);       % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1,L2+1,L3+1);       % Matrices des valeurs des contrôles, pour la retenue principale.
    U2=zeros(N+1,L+1,L2+1,L3+1);      % Matrices des valeurs des transferts, de la retenue secondaire.
    U3=zeros(N+1,L+1,L2+1,L3+1);      % Matrices des valeurs des transferts, de la retenue tertiaire.
    Volume1=[0:L];           % Vecteur des valeurs des niveaux de remplissages, de la retenue principale du barrage.
    Volume2=[0:L2];         % Vecteur des valeurs des niveaux de remplissages, de la retenue secondaire du barrage.
    Volume3=[0:L3];         % Vecteur des valeurs des niveaux de remplissages, de la retenue tertiaire du barrage.
    Controle=[0:o];         % Vecteur des tailles d'ouvertures de la conduite forcée.
    Transfert=[0:T];        % Vecteur des valeurs possibles de transferts de la retenue secondaire.
    Apport=[0:S];           % Vecteur des valeurs possibles de transferts de la retenue tertiaire.
    Entree=[W1;W2;W3];      % Vecteur pour l'algo
    Volume=zeros(3,1);
    Instruction=zeros(3,1);
    % Création des matrices Arbre et Serie:
    Serie=-eye(3);
    Serie=Serie+diag(ones(1,2),1);
    Arbre=-eye(3);
    Arbre(1,2)=1;
    Arbre(1,3)=1;
    % Choix de l'organisation des retenues:
    if(type_graphe=="serie")
        Matrice=Serie;
    elseif(type_graphe=="arbre")
        Matrice=Arbre;
    end
    % Construction des Matrices U et V, par remontée.
    for i=N:-1:1            % Boucle sur le temps
        for j=1:L+1         % Boucle sur le volume du barrage
            Volume(1)=Volume1(j);
            for k=1:L2+1    % Boucle sur le volume de la retenue secondaire
                Volume(2)=Volume2(k);
                for l=1:L3+1 % Boucle sur le volume de la retenue tertiaire
                    Volume(3)=Volume3(l);
                    optimal2=0; % Contiendra le maximum par rapport aux transferts et apports, pour chaque controle.
                        for s=1:S+1
                            if(Volume3(l)+W3-Apport(s)>=0)
                                Instruction(3)=Apport(s);
                                for t=1:T+1
                                    if(Volume2(k)+W2+Apport(s)-Transfert(t)>=0)
                                        Instruction(2)=Transfert(t);
                                        for u=1:o+1
                                            if((Volume1(j)+W1-Controle(u)+Transfert(t)>=0))
                                                Instruction(1)=Controle(u);
                                                New_Vol=Matrice*Instruction+Entree+Volume;
                                                if(optimal2<=rho*g*(Volume1(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,New_Vol(1)),1)),round(max(min(L2,New_Vol(2)),1)),round(max(min(L3,New_Vol(3)),1))))
                                                    optimal2=rho*g*(Volume1(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,New_Vol(1)),1)),round(max(min(L2,New_Vol(2)),1)),round(max(min(L3,New_Vol(3)),1)));
                                                    x=u;
                                                    y=t;
                                                    z=s;
                                                end
                                            end
                                        end
                                    end
                                 end
                             end
                        end
                   V(i,j,k,l)=optimal2;
                   U(i,j,k,l)=Controle(x);
                   U2(i,j,k,l)=Transfert(y);
                   U3(i,j,k,l)=Apport(z);
                end
            end
        end
    end
        [prod_max,rang]=max(V(1,:,:));
        % Construction des vecteurs des CONTROLES OPTIMAUX Controle_opt et des VOLUMES OPTIMAUX vol_courant, grâce aux matrices U,U2 et V.
        Controle_opt=zeros(1,N+1);
        Controle_opt(1)=U(1,vol_depart+1,vol_reserve_depart+1,vol_reserve2_depart+1);
        Transfert_opt=zeros(1,N+1);
        Transfert_opt(1)=U2(1,vol_depart+1,vol_reserve_depart+1,vol_reserve2_depart+1);
        Apport_opt=zeros(1,N+1);
        Apport_opt(1)=U3(1,vol_depart+1,vol_reserve_depart+1,vol_reserve2_depart+1);
        vol_courant=zeros(1,N+1);
        vol_courant(1)=vol_depart;
        vol_reserve=zeros(1,N+1);
        vol_reserve(1)=vol_reserve_depart;
        vol_reserve2=zeros(1,N+1);
        vol_reserve2(1)=vol_reserve2_depart;
        Volume=[vol_courant(1);vol_reserve(1);vol_reserve2(1)];
        Instruction=[Controle_opt(1);Transfert_opt(1);Apport_opt(1)];
        for i=2:N+1
            New_Vol=Matrice*Instruction+Entree+Volume;
            vol_courant(i)=max(min(L,New_Vol(1)),0);
            vol_reserve(i)=max(min(L2,New_Vol(2)),0);
            vol_reserve2(i)=max(min(L3,New_Vol(3)),0);
            Volume=[vol_courant(i);vol_reserve(i);vol_reserve2(i)];
            Controle_opt(i)=U(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Transfert_opt(i)=U2(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Apport_opt(i)=U3(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Instruction=[Controle_opt(i);Transfert_opt(i);Apport_opt(i)];
        end
    % Récupération des résultats
    Programme1=Controle_opt(1:N);
    Programme2=Transfert_opt(1:N);
    Programme3=Apport_opt(1:N);
    % Construction du graphe, du volume de la situation de production optimale, en fonction du temps.
    % Test fonction sinusoïdale:
    x=[0:N];    % Vecteur abscisses du temps.
    clf
    hold on         
    subplot(3,1,1);
    plot(x,vol_reserve2,'green')
    title('volume d eau de la retenue tertiaire, en fonction du temps')
    subplot(3,1,2);
    plot(x,vol_reserve,'cyan');
    title('volume d eau de la retenue secondaire, en fonction du temps')
    subplot(3,1,3);
    plot(x,vol_courant,'blue');    % Graphe du volume d'eau, du barrage.
    title('Volume d eau de la retenue principale, en fonction du temps')
    hold off
    figure(2)
    clf
    hold on
    subplot(3,1,1);
    plot(x,Apport_opt,'green');
    title('Transfert d eau depuis la retenue 3, en fonction du temps')
    subplot(3,1,2);
    plot(x,Transfert_opt,'cyan');
    title('Transfert d eau depuis la retenue 2, en fonction du temps')
    subplot(3,1,3);
    plot(x,Controle_opt,'red');
    title('Controle envoyé à la centrale, en fonction du temps')
    hold off
end