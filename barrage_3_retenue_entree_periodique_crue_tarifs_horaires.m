% L = taille maximale de la retenue principale du barrage.
% L2 = taille maximale de la retenue secondaire du barrage.
% L3 = taille maximale de la retenue tertiaire du barrage.
% o = taille maximale de l'ouverture des conduites forcées, de la retenue principale.
% T = taille maximale de l'ouverture du canal de transfert, de la retenue secondaire.
% S = taille maximale de l'ouverture du canal des apports, de la retenue tertiaire.
% N = durée totale de la période de production d'électricité.
% type_retenue1 = sélectionne le type d'entrée d'eau dans la retenue1, les valeurs possibles sont "periodique" ou "crue".
% type_retenue2 = sélectionne le type d'entrée d'eau dans la retenue2, les valeurs possibles sont "periodique" ou "crue".
% type_retenue3 = sélectionne le type d'entrée d'eau dans la retenue3, les valeurs possibles sont "periodique" ou "crue".
% type_graphe = sélectionne le type de liaison entre les 3 retenues, les valeurs possibles sont "arbre" ou "serie".
% vol_depart = valeur arbitraire du volume présent dans le barrage au depart, pour pouvoir construire le graphe.
% vol_reserve_depart = valeur arbitraire du volume au départ, dans la seconde retenue du barrage.
% vol_reserve2_depart = valeur arbitraire du volume au départ, dans la troisième retenue du barrage.
% P_H_Pleine = Prix de l'électricité, en heure pleine.
% P_H_Creuse = Prix de l'électricité, en heure creuse.
% Periode_H = Période entre les changements de tarifs, heures pleines et heures creuses.

% Appel à la fonction Optimise:
[production,prog1,prog2,prog3]=Optimise_Production(50,25,25,5,7,7,50,"periodique","periodique","periodique","serie",5,10,10,0.18,0.04,2)

function [prod_max,Programme1,Programme2,Programme3]=Optimise_Production(L,L2,L3,o,T,S,N,type_retenue1,type_retenue2,type_retenue3,type_graphe,vol_depart,vol_reserve_depart,vol_reserve2_depart,P_H_Pleine,P_H_Creuse,Periode_H)
% Données
    rho=1000;                      
    g=9.80665;
    mu1=0.75;
    mu2=0.8;
    mu3=0.7;
    %x=1;
    %y=1;
    %z=1;
    % Définition des matrices
    V=zeros(N+1,L+1,L2+1,L3+1);       % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1,L2+1,L3+1);       % Matrices des valeurs des contrôles, pour la retenue principale.
    U2=zeros(N+1,L+1,L2+1,L3+1);      % Matrices des valeurs des transferts, de la retenue secondaire.
    U3=zeros(N+1,L+1,L2+1,L3+1);      % Matrices des valeurs des transferts, de la retenue tertiaire.
    Volume=[0:L];           % Vecteur des valeurs des niveaux de remplissages, de la retenue principale du barrage.
    Volume2=[0:L2];         % Vecteur des valeurs des niveaux de remplissages, de la retenue secondaire du barrage.
    Volume3=[0:L3];         % Vecteur des valeurs des niveaux de remplissages, de la retenue tertiaire du barrage.
    Controle=[0:o];         % Vecteur des tailles d'ouvertures de la conduite forcée.
    Transfert=[0:T];        % Vecteur des valeurs possibles de transferts de la retenue secondaire.
    Apport=[0:S];           % Vecteur des valeurs possibles de transferts de la retenue tertiaire.
    Production_elec_Prix=ones(1,N+1);       % Vecteur des valeurs de production d'électricité, en prix, en fonction du temps.
    Production_elec_cumulee=ones(1,N+1);    % Vecteur des valeurs des gains de production cumulés, en prix, en fonction du temps.
    % Construction des vecteurs des entrées d'eau:
    W1=zeros(1,N+1);                           % Vecteurs des entrées d'eaux.
    W2=zeros(1,N+1);
    W3=zeros(1,N+1);
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
    if(type_retenue3=="crue")
        for i=0:N
            W3(i+1)=0+(L3/4)*exp(-(i-(N/2))^2/(N/4));
        end
    elseif(type_retenue3=="periodique")
        for i=0:N
            W3(i+1)=(L3/8)+(L3/8)*cos((6*N)*i);
        end
    else
        for i=0:N
            W3(i+1)=0;
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
    if(type_graphe=="serie")
        % Construction des Matrices U et V, par remontée.
        for i=N:-1:1            % Boucle sur le temps
            for j=1:L+1         % Boucle sur le volume du barrage
                for k=1:L2+1    % Boucle sur le volume de la retenue secondaire
                    for l=1:L3+1 % Boucle sur le volume de la retenue tertiaire
                        optimal2=0; % Contiendra le maximum par rapport aux transferts et apports, pour chaque controle.
                            for s=1:S+1
                                if(Volume3(l)+W3(i)-Apport(s)>=0)
                                    for t=1:T+1
                                        if(Volume2(k)+W2(i)+Apport(s)-Transfert(t)>=0)
                                            for u=1:o+1
                                                if((Volume(j)+W1(i)-Controle(u)+Transfert(t)>=0))
                                                    if(optimal2<=Prix(i)*rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,Volume(j)+W1(i)-Controle(u)+Transfert(t)),1)),round(max(min(L2,Volume2(k)+W2(i)+Apport(s)-Transfert(t)),1)),round(max(min(L3,Volume3(l)+W3(i)-Apport(s)),1))));
                                                       optimal2=Prix(i)*rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,Volume(j)+W1(i)-Controle(u)+Transfert(t)),1)),round(max(min(L2,Volume2(k)+W2(i)+Apport(s)-Transfert(t)),1)),round(max(min(L3,Volume3(l)+W3(i)-Apport(s)),1)));
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
        Production_elec_Prix(1)=rho*g*(vol_courant(1)*mu1*Controle_opt(1)+vol_reserve(1)*mu2*Transfert_opt(1)+vol_reserve2(1)*mu3*Apport_opt(1))*Prix(1);
        Production_elec_cumulee(1)=Production_elec_Prix(1);
        for i=2:N+1
            vol_courant(i)=max(min(L,vol_courant(i-1)+W1(i-1)-Controle_opt(i-1)+Transfert_opt(i-1)),0);
            vol_reserve(i)=max(min(L2,vol_reserve(i-1)+W2(i-1)+Apport_opt(i-1)-Transfert_opt(i-1)),0);
            vol_reserve2(i)=max(min(L3,vol_reserve2(i-1)+W3(i-1)-Apport_opt(i-1)),0);
            Controle_opt(i)=U(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Transfert_opt(i)=U2(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Apport_opt(i)=U3(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Production_elec_Prix(i)=rho*g*(vol_courant(i)*mu1*Controle_opt(i)+vol_reserve(i)*mu2*Transfert_opt(i)+vol_reserve2(i)*mu3*Apport_opt(i))*Prix(i);
            for j=i:N+1
                Production_elec_cumulee(j)=Production_elec_cumulee(j)+Production_elec_Prix(i);
            end
        end
    elseif(type_graphe=="arbre")
        % Construction des Matrices U et V, par remontée.
        for i=N:-1:1            % Boucle sur le temps
            for j=1:L+1         % Boucle sur le volume du barrage
                for k=1:L2+1    % Boucle sur le volume de la retenue secondaire
                    for l=1:L3+1 % Boucle sur le volume de la retenue tertiaire
                        optimal2=0; % Contiendra le maximum par rapport aux transferts et apports, pour chaque controle.
                            for s=1:S+1
                                if(Volume3(l)+W3(i)-Apport(s)>=0)
                                    for t=1:T+1
                                        if(Volume2(k)+W2(i)-Transfert(t)>=0)
                                            for u=1:o+1
                                                if((Volume(j)+W1(i)-Controle(u)+Transfert(t)+Apport(s)>=0))
                                                    if(optimal2<=Prix(i)*rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,Volume(j)+W1(i)-Controle(u)+Transfert(t)+Apport(s)),1)),round(max(min(L2,Volume2(k)+W2(i)-Transfert(t)),1)),round(max(min(L3,Volume3(l)+W3(i)-Apport(s)),1))))
                                                    optimal2=Prix(i)*rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t)+Volume3(l)*mu3*Apport(s))+V(i+1,round(max(min(L,Volume(j)+W1(i)-Controle(u)+Transfert(t)+Apport(s)),1)),round(max(min(L2,Volume2(k)+W2(i)-Transfert(t)),1)),round(max(min(L3,Volume3(l)+W3(i)-Apport(s)),1)));
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
        Production_elec_Prix(1)=rho*g*(vol_courant(1)*mu1*Controle_opt(1)+vol_reserve(1)*mu2*Transfert_opt(1)+vol_reserve2(1)*mu3*Apport_opt(1))*Prix(1);
        Production_elec_cumulee(1)=Production_elec_Prix(1);
        for i=2:N+1
            vol_courant(i)=max(min(L,vol_courant(i-1)+W1(i-1)-Controle_opt(i-1)+Transfert_opt(i-1)+Apport_opt(i-1)),0);
            vol_reserve(i)=max(min(L2,vol_reserve(i-1)+W2(i-1)-Transfert_opt(i-1)),0);
            vol_reserve2(i)=max(min(L3,vol_reserve2(i-1)+W3(i-1)-Apport_opt(i-1)),0);
            Controle_opt(i)=U(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Transfert_opt(i)=U2(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Apport_opt(i)=U3(i,round(vol_courant(i))+1,round(vol_reserve(i))+1,round(vol_reserve2(i))+1);
            Production_elec_Prix(i)=rho*g*(vol_courant(i)*mu1*Controle_opt(i)+vol_reserve(i)*mu2*Transfert_opt(i)+vol_reserve2(i)*mu3*Apport_opt(i))*Prix(i);
            for j=i:N+1
                Production_elec_cumulee(j)=Production_elec_cumulee(j)+Production_elec_Prix(i);
            end
        end
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
    hold on
    plot(x,W3,'black');
    hold off
    subplot(3,1,2);
    plot(x,vol_reserve,'cyan');
    title('volume d eau de la retenue secondaire, en fonction du temps')
    hold on
    plot(x,W2,'red');
    hold off
    subplot(3,1,3);
    plot(x,vol_courant,'blue');    % Graphe du volume d'eau, du barrage.
    title('Volume d eau de la retenue principale, en fonction du temps')
    hold on
    plot(x,W1,'magenta')
    hold off
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
    figure(3)
    clf
    hold on
    subplot(3,1,1);
    plot(x,Prix,'green');
    title('Tarifs horraires de l électricité, en fonction du temps')
    subplot(3,1,2);
    plot(x,Production_elec_Prix,'cyan');
    title('Production électrique journalières en Prix, en fonction du temps')
    subplot(3,1,3);    
    plot(x,Production_elec_cumulee,'red');
    title('Gain total cumulee, en fonction du temps')
    hold off
end