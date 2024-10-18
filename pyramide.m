pyramide1=[[3,0,0,0];       %Exemple 1
           [7,4,0,0];
           [2,4,6,0];
           [9,5,9,3]];
pyramide2=[[6,0,0,0,0,0];   %Exemple 2
           [2,3,0,0,0,0];
           [5,8,1,0,0,0];
           [8,5,3,9,0,0];
           [2,3,4,7,2,0];
           [2,9,2,5,3,1]];

% Teste des fonctions sur les 2 exemples et affichages des résultats
[sol1,chem1]=chemin_max(pyramide1)
[sol2,chem2]=chemin_min(pyramide1)
[sol3,chem3]=chemin_max(pyramide2)
[sol4,chem4]=chemin_min(pyramide2)

% Fonction qui calcule le chemin dans la pyramide, qui maximise la somme
% des valeurs des cases traversées et renvoie également la valeur de cette
% somme.
function [solution,chemin]=chemin_max(pyramide)
    n=size(pyramide);                   % On récupère la taille de la pyramide, pour connaître le nombre d'étage à traiter. 
    intermediaire=zeros(n);             % On génère la matrice, qui va contenir les coefficients des sommes intermédiaires de la remontée de la pyramide.
    intermediaire(1,:)=pyramide(n(1),:);% La 1ère ligne d'inermédiaire est toujours la dernière de la pyramide, l'ordre des lignes est inversée entre les deux matrices.
    l=1;                                % Variable d'incrémentation, servant à décaler la ligne d'Intermediaire, pour le traitement de la ligne suivante, ci-dessous.
    chemin=zeros(1,n(1));               % On génère un vecteur ligne, tel que dans chacune de ses colonnes, on stocke la valeur de l'indice de colonne, à choisir dans Intermédiaire, pour construire le chemin optimale.
                                        % Chaque colonne de chemin, correspondant bien sûr, à une ligne de la matrice pyramide d'origine.
    chemin(1,1)=1;                      % Dans la pyramide, le chemin optimal commence toujours par le coefficient au sommet de celle-ci.
    for i=n(1)-1:-1:1                   % On itère en sens inverse pour construire Intermédiaire, car l'ordre des lignes avec la pyramide est inversé. 
        courant=[pyramide(i,:)];        % On récupère la ligne de pyramide, pour la quelle on va tester les sommes intermédiaires maximales.
        for j=1:i                       % Pour chaque colonne, dont le coefficient est non nul, sur cette ligne. 
            courant(j)=max(intermediaire(l,j)+courant(j),intermediaire(l,j+1)+courant(j)); 
        end                             % Pour chaque coefficient, on prend la plus grande des deux sommes intermédiaires potentielles, pour maximiser la valeur du chemin.
        l=l+1;                          % On incrémente la variable, pour passer à la prochaine ligne d'Intermédiaire, au tire de boucle suivant. 
        intermediaire(l,:)=courant;
        %intermediaire                                %test fonctionnement
    end
    solution=intermediaire(n(1),1);  % On récupère la valeur de somme optimale, tout en bas de la matrice intermédiaire, vu que l'ordre des lignes est inversé.
    for i=2:n(1)                     % On construit maintenant le chemin optimale, situé le plus en haut à gauche, dans la pyramide en cas, de solution optimale non unique, à l'aide la matrice Intermédiaire. 
        sous=intermediaire(n(1)+1-i,chemin(i-1)); % On utilise la valeur précédente de chemin, pour la colonne, pour obtenir les 2 bons coefficient somme.
        sur=intermediaire(n(1)+1-i,chemin(i-1)+1);% On récupère le deuxième et on prend le max des deux, pour savoir quel chemin prendre.
        if max(sous,sur)==sous      % En partant du dernier coefficient sommé, on prend le plus grand des 2 coefficients sommes, situé sur la ligne du dessus, dans Intermédiaire.
            chemin(i)=chemin(i-1);  % On élimine ainsi un grand nombre de possibilité, en remontant dans ce sens et on effectue que n-1 opérations.
        else
            chemin(i)=chemin(i-1)+1;
        end
    end
end

% Fonction qui calcule le chemin dans la pyramide, qui minimise la somme
% des valeurs des cases traversées et renvoie également la valeur de cette
% somme.
function [solution,chemin]=chemin_min(pyramide)
    n=size(pyramide);                   % On récupère la taille de la pyramide, pour connaître le nombre d'étage à traiter. 
    intermediaire=zeros(n);             % On génère la matrice, qui va contenir les coefficients des sommes intermédiaires de la remontée de la pyramide.
    intermediaire(1,:)=pyramide(n(1),:);% La 1ère ligne d'inermédiaire est toujours la dernière de la pyramide, l'ordre des lignes est inversée entre les deux matrices.
    l=1;                                % Variable d'incrémentation, servant à décaler la ligne d'Intermediaire, pour le traitement de la ligne suivante, ci-dessous.
    chemin=zeros(1,n(1));               % On génère un vecteur ligne, tel que dans chacune de ses colonnes, on stocke la valeur de l'indice de colonne, à choisir dans Intermédiaire, pour construire le chemin optimale.
                                        % Chaque colonne de chemin, correspondant bien sûr, à une ligne de la matrice pyramide d'origine.
    chemin(1,1)=1;                      % Dans la pyramide, le chemin optimal commence toujours par le coefficient au sommet de celle-ci.
    for i=n(1)-1:-1:1                   % On itère en sens inverse pour construire Intermédiaire, car l'ordre des lignes avec la pyramide est inversé. 
        courant=[pyramide(i,:)];        % On récupère la ligne de pyramide, pour la quelle on va tester les sommes intermédiaires minimales.
        for j=1:i                       % Pour chaque colonne, dont le coefficient est non nul, sur cette ligne. 
            courant(j)=min(intermediaire(l,j)+courant(j),intermediaire(l,j+1)+courant(j));
        end                             % Pour chaque coefficient, on prend la plus grande des deux sommes intermédiaires potentielles, pour maximiser la valeur du chemin.
        l=l+1;                          % On incrémente la variable, pour passer à la prochaine ligne d'Intermédiaire, au tire de boucle suivant. 
        intermediaire(l,:)=courant;     
        %intermediaire                                %test fonctionnement
    end
    solution=intermediaire(n(1),1);     % On récupère la valeur de somme optimale, tout en bas de la matrice intermédiaire, vu que l'ordre des lignes est inversé.
    for i=2:n(1)                        % On construit maintenant le chemin optimale, situé le plus en haut à gauche, dans la pyramide en cas, de solution optimale non unique, à l'aide la matrice Intermédiaire. 
        sous=intermediaire(n(1)+1-i,chemin(i-1));   % On utilise la valeur précédente de chemin, pour la colonne, pour obtenir les 2 bons coefficient somme.
        sur=intermediaire(n(1)+1-i,chemin(i-1)+1);  % On récupère le deuxième et on prend le max des deux, pour savoir quel chemin prendre.
        if min(sous,sur)==sous          % En partant du dernier coefficient sommé, on prend le plus grand des 2 coefficients sommes, situé sur la ligne du dessus, dans Intermédiaire.
            chemin(i)=chemin(i-1);      % On élimine ainsi un grand nombre de possibilité, en remontant dans ce sens et on effectue que n-1 opérations.
        else
            chemin(i)=chemin(i-1)+1;
        end
    end
end