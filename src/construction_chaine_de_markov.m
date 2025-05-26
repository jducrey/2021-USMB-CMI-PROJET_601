% n=longueur de la chaine de markov.
% nbr_detats=nombre d'états que le système peut atteindre.
% etat_initial=état initial du système.
[chaine]=cree_chaine_markov(10,5,2)

function [W]=cree_chaine_markov(n,nbr_detats,etat_initial)
    % On génère la matrice P de transition:
    P=0.8*eye(nbr_detats);
    P=P+diag(0.1*ones(1,nbr_detats-1),1);
    P=P+diag(0.1*ones(1,nbr_detats-1),-1);
    P(nbr_detats,nbr_detats)=0.9;P(1,1)=0.9;
    P
    % On initialise l'état initial de notre système:
    W=[etat_initial];
    % Algorithme de génération:
    for i=1:n-1
        aleatoire=rand;
        j=W(i);    
        somme=P(j,1);
        compteur=1;
        while (somme<=aleatoire) && (compteur<nbr_detats)
            compteur=compteur+1;
            somme=somme+P(j,compteur);
        end
        W(i+1)=compteur;
    end
end