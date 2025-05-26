% L = taille maximale de la retenue principale du barrage.
% L2 = taille maximale de la retenue secondaire du barrage.
% o = taille maximale de l'ouverture des conduites forcées, de la retenue principale.
% T = taille maximale de l'ouverture du canal de transfert, de la retenue secondaire.
% N = durée totale de la période de production d'électricité.
% type_retenue1 = sélectionne le type d'entrée d'eau dans la retenue, les valeurs possibles sont "periodique" ou "crue".
% type_retenue2 = sélectionne le type d'entrée d'eau dans la retenue, les valeurs possibles sont "periodique" ou "crue".
% vol_depart = valeur arbitraire du volume présent dans le barrage au depart, pour pouvoir construire le graphe.
% vol_reserve_depart = valeur arbitraire du volume au départ, dans la seconde retenue du barrage.

% Appel à la fonction Optimise:
[production,prog1,prog2]=Optimise_Production(100,50,10,15,100,"periodique","crue",5,20)

function [prod_max,Programme1,Programme2]=Optimise_Production(L,L2,o,T,N,type_retenue1,type_retenue2,vol_depart,vol_reserve_depart)
    % Données
    rho=1000;                      
    g=9.80665;
    mu1=0.2;
    mu2=0.8;
    % Définition des matrices
    V=zeros(N+1,L+1,L2+1);       % Matrices des valeurs de production d'électricité entre les instants n et N.
    U=zeros(N+1,L+1,L2+1);       % Matrices des valeurs des contrôles, pour la retenue principale.
    U2=zeros(N+1,L+1,L2+1);       % Matrices des valeurs des transferts, entre la retenue secondaire et la retenue principale.
    Volume=[0:L];           % Vecteur des valeurs des niveaux de remplissages, de la retenue principale du barrage.
    Volume2=[0:L2];         % Vecteur des valeurs des niveaux de remplissages, de la retenue secondaire du barrage.
    Controle=[0:o];         % Vecteur des tailles d'ouvertures de la conduite forcée.
    Transfert=[0:T];        % Vecteur des valeurs possibles de transferts entre la retenue principale et secondaire.
    Production_elec=ones(1,N+1);            % Vecteur des valeurs de production d'électricité, en fonction du temps.
    Production_elec_cumulee=ones(1,N+1);    % Vecteur des valeurs de production d'électricité cumulés, en fonction du temps.
    % Construction des vecteurs des entrées d'eau:
    W1=[];                           % Vecteurs des entrées journalières.
    W2=[];
    if(type_retenue1=="crue")
        for i=0:N
            W1(i+1)=2+(L/4)*exp(-(i-(N/2))^2/(N/4));
        end
    elseif(type_retenue1=="periodique")
        for i=0:N
            W1(i+1)=(L/8)+(L/8)*cos((N/2)*i);
        end
    else
        for i=0:N
            W1(i+1)=2;
        end 
    end
    if(type_retenue2=="crue")
        for i=0:N
            W2(i+1)=2+(L2/4)*exp(-(i-(N/2))^2/(N/4));
        end
    elseif(type_retenue2=="periodique")
        for i=0:N
            W2(i+1)=(L2/8)+(L2/8)*cos((N/2)*i);
        end
    else
        for i=0:N
            W2(i+1)=2;
        end
    end
    % Construction des Matrices U et V, par remontée.
    for i=N:-1:1            % Boucle sur le temps
        for j=1:L+1         % Boucle sur le volume du barrage
            for k=1:L2+1    % Boucle sur le volume de la retenue
                optimal2=zeros(o+1,T+1); % Contiendra le maximum par rapport aux transferts, pour chaque controle.
                    for t=1:T+1
                        if(Volume2(k)+W2(i)-Transfert(t)>=0)
                            for u=1:o+1
                                if((Volume(j)+W1(i)-Controle(u)+Transfert(t)>=0))
                                    optimal2(u,t)=rho*g*(Volume(j)*mu1*Controle(u)+Volume2(k)*mu2*Transfert(t))+V(i+1,round(max(min(L,Volume(j)+W1(i)-Controle(u)+Transfert(t)),1)),round(max(min(L2,Volume2(k)+W2(i)-Transfert(t)),1)));
                                end
                            end
                            
                        end
                    end
                V(i,j,k)=max(max(optimal2));
                [x,y]=find(optimal2==max(max(optimal2)));
                U(i,j,k)=Controle(x(1));
                U2(i,j,k)=Transfert(y(1));
            end
        end
    end
    [prod_max,rang]=max(V(1,:,:));
    % Construction des vecteurs des CONTROLES OPTIMAUX Controle_opt et des VOLUMES OPTIMAUX vol_courant, grâce aux matrices U,U2 et V.
    Controle_opt=zeros(1,N+1);
    Controle_opt(1)=U(1,vol_depart+1,vol_reserve_depart+1);
    Transfert_opt=zeros(1,N+1);
    Transfert_opt(1)=U2(1,vol_depart+1,vol_reserve_depart+1);
    vol_courant=zeros(1,N+1);
    vol_courant(1)=vol_depart;
    vol_reserve=zeros(1,N+1);
    vol_reserve(1)=vol_reserve_depart;
    Production_elec(1)=rho*g*(vol_courant(1)*mu1*Controle_opt(1)+vol_reserve(1)*mu2*Transfert_opt(1));
    Production_elec_cumulee(1)=Production_elec(1);
    for i=2:N+1
        vol_courant(i)=max(min(L,vol_courant(i-1)+W1(i)-Controle_opt(i-1)+Transfert_opt(i-1)),0);
        vol_reserve(i)=max(min(L2,vol_reserve(i-1)+W2(i)-Transfert_opt(i-1)),0);
        Controle_opt(i)=U(i,round(vol_courant(i))+1,round(vol_reserve(i))+1);
        Transfert_opt(i)=U2(i,round(vol_courant(i))+1,round(vol_reserve(i))+1);
        Production_elec(i)=rho*g*(vol_courant(i)*mu1*Controle_opt(i)+vol_reserve(i)*mu2*Transfert_opt(i));
        for j=i:N+1
            Production_elec_cumulee(j)=Production_elec_cumulee(j)+Production_elec(i);
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
    subplot(3,1,1);
    plot(x,vol_reserve,'cyan');
    hold on
    plot(x,W2,'black')
    hold off
    title('volume et entrée d eau de la retenue secondaire, en fonction du temps')
    subplot(3,1,2);
    plot(x,vol_courant,'blue');    % Graphe du volume d'eau, du barrage.
    hold on
    plot(x,W1,'magenta')
    hold off
    title('Volume et entrée d eau de la retenue principale, en fonction du temps')
    subplot(3,1,3);
    plot(x,Transfert_opt,'green');
    title('Transfert d eau, en fonction du temps')
    hold off 
    figure(2)
    clf
    hold on
    subplot(3,1,1);
    plot(x,Controle_opt,'black');
    title('Controle envoyé à la centrale, en fonction du temps')
    subplot(3,1,2);
    plot(x,Production_elec,'red');
    title('Production électrique, en fonction du temps')
    subplot(3,1,3);
    plot(x,Production_elec_cumulee,'green')
    title('Production électrique cumulée, en fonction du temps')
    hold off
end