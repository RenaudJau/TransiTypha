#' mattrans.calc - Calcul des éléments pour la matrice de transition et les représentations graphiques
#'
#' @param TAILLE vecteur de même dimension que IDSTATION,il s'agit de la dimension en m linéaire amont-aval de la station
#' @param FREQ  vecteur de même dimension que IDSTATION, fréquence de Typha, issue de ligne de point contact ou a minima estimation du pourcentage de recouvrement
#' @param ARB vecteur de même dimension que IDSTATION, le recouvrement en espèces arbustives et arborées : peut provenir de lignes de points contact ou d'estimations visuelles de pourcentages de recouvrement, il est préférable d'avoir donné une estimation totale de ces recouvrements plutôt que la somme des recouvrements de chacune des espèces arborées et arbustives (qui a tendance à surestimer le total..).
#' @param LIMONS vecteur de même dimension que IDSTATION, peut provenir de lignes de points contact ou d'estimation visuelles de pourcentages de recouvrement, servira à classer les petites stations avec beaucoup de galets
#' @param ANNEES vecteur de même dimension que IDSTATION, l'année de visite de la station
#' @param IDSTATION vecteur de même dimension que IDSTATION,l'identifiant de la station/tache : ne doit pas contenir l'année
#' @param SUIVI tableau dont le nombre de colonne correspond à la dimension de IDSTATION et correspondant à la correspondance du devenir des stations
#' @param s_petite_taille valeur unique, valeur seuil pour la taille en dessous de laquelle on entre dans la catégorie "Petite"
#' @param s_petite_freq valeur unique, valeur seuil pour la fréquence en dessous de laquelle on entre dans la catégorie "Petite"
#' @param s_moyenne_freq valeur unique, valeur seuil pour la fréquence en dessous de laquelle on entre dans la catégorie "Moyenne"
#' @param s_limons valeur unique, valeur seuil pour le recouvrement sablo-limoneux en dessous de laquelle on entre dans la catégorie "Galets"
#' @param s_arb valeur unique, valeur seuil pour le recouvrement arbustif et arboré en dessous de laquelle on entre dans la catégorie "Mature"
#'
#' @return \item{Classification}{vecteur de la taille de IDSTATION, donne les types de station pour chacune d'elle}
#' @return \item{Matrice_transition}{matrice carrée de la dimension des types de stations, donne les probabilités de transition d'un état à l'autre, les lignes représentant les points de départs et les colonnes les points d'arrivée}
#' @return \item{Nb_type}{vecteur nommé, donne le nombre de station par type de station}
#' @return \item{N_NA}{Nb de station pour lesquelles il n'y a pas d'info pour la transition (en excluant celles de la dernière année de suivi, évidemment..)}
#' @return \item{NDisptot}{Nb de station ou portion de station disparues, !! ne correspond pas forcément au nombre de stations disparues..}
#' @return \item{Nb_Disp}{vecteur nommé, donne le nombre de station disparue entièrement par type de station}
#' @return \item{Prop_Disp}{vecteur nommé, donne la proportion de portions de stations par type de station}
#' @return \item{Nb_App}{vecteur nommé, donne le nombre de station apparues par type de station}
#' @export
#'
#' @examples # Exemple avec jeu de données inclu dans le package
#' data_ty
#'
#' # contient colonnes avec les ID des stations, les Dates, les longueurs, les limons,
#' # l'abondance arbustif+ arboré, la fréquence et 4 colonnes pour les données de suivi..
#'
#' # On spécifie la partie ‘suivi’ (ici les colonnes 7 à 10) :
#' suivi <- data_ty[,7:10]
#'
#' Typhamat_all <- mattrans.calc(TAILLE = data_ty$Longueur, FREQ = data_ty$Freq,
#'                                ARB = data_ty$ArbuArbo, LIMONS = data_ty$Limon,
#'                                ANNEES = data_ty$Dates, IDSTATION = data_ty$ID, SUIVI = suivi)
#' # On peut voir la Classification des stations
#' Typhamat_all$Classification
#' data.frame(station = data_ty$ID, Dates = data_ty$Dates,
#'            Classification = Typhamat_all$Classification)
#' # On peut voir la matrice de transition
#' Typhamat_all$Matrice_transition
mattrans.calc <- function(TAILLE, FREQ, ARB, LIMONS, ANNEES, IDSTATION, SUIVI,
                           s_petite_taille = 10, s_petite_freq = 0.1,
                           s_moyenne_freq = 0.3, s_limons = 0.2, s_arb = 0.3){

  # Vérif qu'il n'y ait pas plusieurs stations du même nom la même année :
  if(length(IDSTATION)!=length(unique(paste(IDSTATION,ANNEES)))){print("Attention, il ne doit y avoir qu'une seule ligne par station/année")}

  # Messages si jamais des NA dans TAILLE :
  na_taille <- length(which(is.na(TAILLE)))
  if(na_taille!=0) print("Attention, TAILLE contient des NA, les stations correspondantes seront assignées à la catégorie '0_Potentielle'")

  # Vérif : Division par 100 si les estimations sont en % et non plus en proportion.. :
  if(max(FREQ,na.rm=T)>1){FREQ <- FREQ/100}
  if(max(ARB,na.rm=T)>1){ARB <- ARB/100}
  if(max(LIMONS,na.rm=T)>1){LIMONS <- LIMONS/100}

  #Assignation des types :
  #(par étape, histoire de pouvoir retracer d'éventuelles erreurs..)
  Taille <- NULL
  for(i in 1:length(IDSTATION)){
    if(is.na(TAILLE[i])==TRUE){Taille[i] <- "Autre"}else{
      if(TAILLE[i] < s_petite_taille | FREQ[i] < s_petite_freq){Taille[i] <- "Petite"}else{
        if(FREQ[i] < s_moyenne_freq){Taille[i] <- "Moyenne"}else{Taille[i] <- "Grande"}}}}
  Cl_petites <- NULL
  for(i in 1:length(IDSTATION)){
    if(Taille[i]!="Petite"){Cl_petites[i] <- Taille[i]}else{
      if(ARB[i] > s_arb){Cl_petites[i] <- "3_Petite_mature"}else{
        if(LIMONS[i] < s_limons){Cl_petites[i] <- "2_Petite_galets"}else{
          Cl_petites[i] <- "1_Petite_pionniere"}}}}
  Cl_moyennes <- NULL
  for (i in 1:length(IDSTATION)){
    if(Cl_petites[i]!="Moyenne"){Cl_moyennes[i] <- Cl_petites[i]}else{
      if(ARB[i] < s_arb){Cl_moyennes[i] <- "6_Moyenne_pionniere"}else{
        Cl_moyennes[i] <- "7_Moyenne_mature"}}}
  Cl_grandes <- NULL
  for (i in 1:length(IDSTATION)){
    if(Cl_moyennes[i]!="Grande"){Cl_grandes[i] <- Cl_moyennes[i]}else{
      if(ARB[i] < s_arb){Cl_grandes[i] <- "4_Grande_pionniere"}else{
        Cl_grandes[i] <- "5_Grande_mature"}}}
  Classification <- NULL
  for (i in 1:length(IDSTATION)){
    if(Cl_grandes[i]!="Autre"){Classification[i] <- Cl_grandes[i]}else{
      Classification[i] <- "0_Potentielle"}}

  #liste des années possibles
  l_annees <- sort(unique(ANNEES))

  #liste des catégories possibles
  T_classif <- c(sort(unique(Classification)),"8_Disparue")

  # Remplacer station par catégories
  suivi_t <- SUIVI
  # ID tache/annee dans la matrice suivi (pour vérif les apparitions)
  suivi_annee <- SUIVI
  # Remplacer les disp par catégories
  Disp_T <- SUIVI
  for(i in 1:nrow(suivi_t))
  {
    for (j in 1:ncol(suivi_t)) {
      Disp_T[i,j] <- ifelse(SUIVI[i,j]!="DISP", NA, Classification[i])
      suivi_annee[i,j] <- ifelse(is.na(SUIVI[i,j])==TRUE, NA, paste(SUIVI[i,j],ANNEES[i],sep="_"))
      if(is.na(SUIVI[i,j])==TRUE){suivi_ti <- NA}else{
        if(SUIVI[i,j]=="DISP"){suivi_ti <- "8_Disparue"}else{
          if(ANNEES[i]==l_annees[length(l_annees)]){suivi_ti <- NA}else{
            suivi_ti <- Classification[ANNEES==l_annees[which(l_annees==ANNEES[i])+1] & IDSTATION==SUIVI[i,j]]
          }
        }
      }
      suivi_t[i,j] <- suivi_ti
    }
  }

  #Nb de station par type (en retirant tous les NA..)
  Nb_type <- tapply(Classification[is.na(SUIVI[,1])==FALSE & ANNEES!=l_annees[length(l_annees)]],
                    Classification[is.na(SUIVI[,1])==FALSE & ANNEES!=l_annees[length(l_annees)]],length)
  #Nb de disparition (de station) par type
  #Attention pour la disparition, ici il s'agit des station alors que pour la proportion il peut s'agir de portion de stations..
  Nb_Disp <- tapply(Classification[SUIVI[,1]=="DISP" & ANNEES!=l_annees[length(l_annees)]],
                    Classification[SUIVI[,1]=="DISP" & ANNEES!=l_annees[length(l_annees)]],length)
  #Nb NA sauf dernière année :
  N_NA <- length(which(is.na(SUIVI[,1])==TRUE & ANNEES!=l_annees[length(l_annees)]))
  NDisptot <- length(which(is.na(Disp_T)==FALSE & ANNEES!=l_annees[length(l_annees)])) # Nb tot de disparition (tache ou portion de tache)

  # Remplissage de la matrice ce transition :
  Matrice_transition <- matrix(data = NA, ncol=length(T_classif), nrow=length(T_classif))
  colnames(Matrice_transition) <- T_classif
  row.names(Matrice_transition) <- T_classif
  #Proportion des disparitions par type
  Prop_Disp <- NULL
  for(i in 1:length(T_classif))
  {
    Prop_Disp[i] <- length(which(Disp_T==T_classif[i] & is.na(Disp_T)==FALSE & ANNEES!=l_annees[length(l_annees)]))/NDisptot
    for(j in 1:length(T_classif))
    {
      # nombre de type i :
      n_ti <- length(which(is.na(suivi_t[ANNEES!=l_annees[length(l_annees)],][Classification[ANNEES!=l_annees[length(l_annees)]]==T_classif[i],])==FALSE))
      # nombre de transition vers type j :
      n_tj <- length(which(is.na(suivi_t[ANNEES!=l_annees[length(l_annees)],][Classification[ANNEES!=l_annees[length(l_annees)]]==T_classif[i],])==FALSE &
                             suivi_t[ANNEES!=l_annees[length(l_annees)],][Classification[ANNEES!=l_annees[length(l_annees)]]==T_classif[i],]==T_classif[j]))
      Matrice_transition[i,j] <- n_tj/n_ti
      #Matrice_transition[i,j] <- ifelse(n_ti==0,0,n_tj/n_ti)
      # la ligne représentera le point de départ et la colonne le point d'arrivée
    }
  }
  names(Prop_Disp) <- T_classif
  Prop_Disp <- Prop_Disp[Prop_Disp!=0]

  # liste de toutes les stations en n+1 / pour pouvoir les piocher et vérif les apparitions
  unique_suivi <- unique(suivi_annee[,1])
  for(i in 2:ncol(suivi_annee)){unique_suivi <- c(unique_suivi,unique(suivi_annee[,i]))}
  unique_suivi <- unique(unique_suivi[which(is.na(unique_suivi)==FALSE)])

  Apparitions_T <- NULL
  for(i in 1:nrow(SUIVI)){
    Apparitions_T[i] <- ifelse(paste(IDSTATION[i],l_annees[which(l_annees==ANNEES[i])-1],sep="_")%in%unique_suivi,NA,Classification[i])
    Apparitions_T[i] <- ifelse(ANNEES[i]==l_annees[1],NA,Apparitions_T[i])
  }
  # Nb Apparitions par type
  Nb_App <- tapply(Apparitions_T,Apparitions_T,length)

  Output <- list(Classification,Matrice_transition, Nb_type,N_NA,NDisptot,Nb_Disp,Prop_Disp,Nb_App)
  names(Output) <- c("Classification","Matrice_transition","Nb_type","N_NA",
                     "NDisptot","Nb_Disp","Prop_Disp","Nb_App")
  return(Output)
}



#' Typha_transition_graph - permet de tracer les états et les transitions
#' @param MATTRANS la matrice de transition calculée avec mattrans.calc cf $Matrice_transition
#' @param CLASSIF la classification calculée avec mattrans.calc cf $Classification
#' @param ANNEES vecteur de même dimension que IDSTATION, l'année de visite de la station
#' @param LISTCOUL (facultatif) liste de couleurs à utiliser pour les types de stations
#' @param WIDTH (facultatif) épaisseur des transitions
#' @param DEL (facultatif) la proportion minimale de transition pour faire apparaître un lien (doit être compris entre 0 et 1)
#' @param CURVE (facultatif) courbure des transitions
#' @param ARROW (facultatif) taille des flèches
#' @param SIZE (facultatif) taille des noeuds (qui sera de toutes façons proportionnels au nombre de stations de départ par type)
#' @param LABELS (facultatif) étiquettes des noeuds
#'
#' @return
#' @export
#' @import igraph
#'
#' @examples # Exemple avec jeu de données inclu dans le package
#' data_ty
#'
#' # contient colonnes avec les ID des stations, les Dates, les longueurs, les limons,
#' # l'abondance arbustif+ arboré, la fréquence et 4 colonnes pour les données de suivi..
#'
#' # On spécifie la partie ‘suivi’ (ici les colonnes 7 à 10) :
#' suivi <- data_ty[,7:10]
#'
#' Typhamat_all <- mattrans.calc(TAILLE = data_ty$Longueur, FREQ = data_ty$Freq,
#'                                ARB = data_ty$ArbuArbo, LIMONS = data_ty$Limon,
#'                                ANNEES = data_ty$Dates, IDSTATION = data_ty$ID, SUIVI = suivi)
#' # On peut voir la Classification des stations
#' Typhamat_all$Classification
#' data.frame(station = data_ty$ID, Dates = data_ty$Dates,
#'            Classification = Typhamat_all$Classification)
#' # On peut voir la matrice de transition
#' Typhamat_all$Matrice_transition
#'
#' # On peut tracer le graphe des transitions :
#' Typha_transition_graph(MATTRANS = Typhamat_all$Matrice_transition,
#'                        CLASSIF = Typhamat_all$Classification,
#'                        ANNEES = data_ty$Dates, SIZE = 150)
Typha_transition_graph <- function(MATTRANS, CLASSIF, ANNEES,
                                    LISTCOUL = c("#FFCCB6","#B9B9B9",
                                                 "#FC8D1D","#2DB30C","#305B25",
                                                 "#EAC931","#977D09","#606060"),
                                    WIDTH = 15, DEL = 0.1, CURVE=.2, ARROW = .7, SIZE = 100,
                                    LABELS = NULL)
{

  #
  if(length(which(is.na(MATTRANS)))!=0){
    # print("Il y a des NAs dans la matrice de transition, sans doute certaines catégories ne sont pas présentes en point de départ - ces NAs sont transformé en une probabilité de 0 pour le graphique")
    MATTRANS <- apply(MATTRANS, c(1,2), function(x) ifelse(is.na(x)==TRUE, 0, x))}

  # Pour ne prendre que les types hors dernières années (qui ne font pas de transitions..)
  l_annees <- sort(unique(ANNEES))
  Departs <- CLASSIF[ANNEES!=l_annees[length(l_annees)]]

  from <- rep(colnames(MATTRANS),length(colnames(MATTRANS)))
  to <- rep(colnames(MATTRANS),each = length(colnames(MATTRANS)))
  weight <- MATTRANS[,1]
  for(i in 2:nrow(MATTRANS))
  {
    weight <- c(weight,MATTRANS[,i])
  }
  links <- data.frame(from,to,weight)

  id <- colnames(MATTRANS)
  typha <- colnames(MATTRANS)
  nodes <- data.frame(id,typha)

  net <- graph_from_data_frame(d=links, vertices=nodes,directed = TRUE)

  V(net)$color <- LISTCOUL
  E(net)$width <- E(net)$weight*WIDTH+0.01
  net.sp <- delete_edges(net, E(net)[ifelse(is.na(weight)==TRUE,0,weight)<DEL])
  l <- layout_in_circle(net.sp)

  edge.start <- ends(net.sp, es=E(net.sp), names=F)[,1]
  edge.col <- V(net.sp)$color[edge.start]

  nb_type <- NULL
  for(i in 1:ncol(MATTRANS))
  {
    nb_type[i] <- length(Departs[is.na(Departs)==FALSE][Departs[is.na(Departs)==FALSE]==colnames(MATTRANS)[i]])
  }
  nb_type <- nb_type/length(Departs[is.na(Departs)==FALSE])

  if(is.null(LABELS)==TRUE){LABELS <- colnames(MATTRANS)}

  # Pour les angles :
  tab_angle <- data.frame(angle = c(0,7*pi/4,3*pi/2,5*pi/4,pi,3*pi/4,pi/2),
                          from_a = colnames(MATTRANS)[-8])


  from_i <- rep(names(net.sp[[1]]),length(net.sp[[1]][[1]]))
  to_i <- names(net.sp[[1]][[1]])
  for(i in 2:8)
  {
    from_i <- c(from_i,rep(names(net.sp[[i]]),length(net.sp[[i]][[1]])))
    to_i <- c(to_i,names(net.sp[[i]][[1]]))
  }

  angle_ii <- NULL
  for(i in 1:length(from_i))
  {
    angle_ii_i <- tab_angle$angle[tab_angle$from_a==from_i[i]]
    angle_ii[i] <- ifelse(from_i[i]==to_i[i],angle_ii_i,0)
  }
  n_type_to <- substr(x = to_i,start = 1,stop = 1)
  n_type_from <- substr(x = from_i,start = 1,stop = 1)
  comb<-as.numeric(paste0(n_type_to,n_type_from))
  #data.frame(from_i,to_i,n_type_to,n_type_from,comb,angle_ii)[order(comb),]
  angles_ordre <- angle_ii[order(comb)]

  plot(net.sp,edge.curved=CURVE, vertex.size=SIZE*nb_type,vertex.label=LABELS,layout=l,edge.loop.angle=angles_ordre,
       edge.arrow.size = ARROW, edge.color=edge.col)

}

#' barplot_devenir - trace pour un type de station, les proportions de ses devenirs
#'
#' @param TYPE le nom d'un des types de stations 'doit êre entre guillemets et respecter la syntaxe..)
#' @param ANNEES vecteur de même dimension que IDSTATION, l'année de visite de la station
#' @param MATTRANS la matrice de transition calculée avec mattrans.calc cf $Matrice_transition
#' @param CLASSIF la classification calculée avec mattrans.calc cf $Classification
#' @param POS "left" ou "right" donne la position des noms et nombre des types..
#' @param XLIM permet de changer les limites de l'axe des x doit être sous format c(n,n)
#' @param XLAB permet de changer le titre de l'axe des x doit être entre guillemets
#' @param MAIN permet de changer le titre du graphique doit être entre guillemets
#' @param COUL permet de changer les couleurs des barplot
#' @param LISTCOUL permet de donner la liste complète des couleurs de tous les types (y compris ceux absents du graphe..)
#'
#' @return
#' @export
#'
#' @examples # Exemple avec jeu de données inclu dans le package
#' data_ty
#'
#' # contient colonnes avec les ID des stations, les Dates, les longueurs, les limons,
#' # l'abondance arbustif+ arboré, la fréquence et 4 colonnes pour les données de suivi..
#'
#' # On spécifie la partie ‘suivi’ (ici les colonnes 7 à 10) :
#' suivi <- data_ty[,7:10]
#'
#' Typhamat_all <- mattrans.calc(TAILLE = data_ty$Longueur, FREQ = data_ty$Freq,
#'                                ARB = data_ty$ArbuArbo, LIMONS = data_ty$Limon,
#'                                ANNEES = data_ty$Dates, IDSTATION = data_ty$ID, SUIVI = suivi)
#' # On peut voir la Classification des stations
#' Typhamat_all$Classification
#' data.frame(station = data_ty$ID, Dates = data_ty$Dates,
#'            Classification = Typhamat_all$Classification)
#' # On peut voir la matrice de transition
#' Typhamat_all$Matrice_transition
#'
#' # Pour tracer le bilan des transitions pour les grandes pionnières
#' barplot_devenir(TYPE = "4_Grande_pionniere",ANNEES = data_ty$Dates,
#'                 MATTRANS = Typhamat_all$Matrice_transitio,CLASSIF = Typhamat_all$Classification)
#'
barplot_devenir <- function(TYPE, ANNEES, MATTRANS, CLASSIF, POS = "left", XLIM = c(0,100),
                            XLAB = "Proportion de destination (%)",MAIN = NULL, COUL = NULL,
                            LISTCOUL = c("#FFCCB6","#B9B9B9","#FC8D1D","#2DB30C",
                                         "#305B25","#EAC931","#977D09","#606060")){

  #
  if(length(which(is.na(MATTRANS)))!=0){
    MATTRANS <- apply(MATTRANS, c(1,2), function(x) ifelse(is.na(x)==TRUE, 0, x))}

  l_annees <- sort(unique(ANNEES))
  Depart_T <- length(CLASSIF[ANNEES!=l_annees[length(l_annees)] & CLASSIF==TYPE])
  Transi_T <- sort(MATTRANS[TYPE,][MATTRANS[TYPE,]!=0],decreasing = TRUE)

  if(is.null(COUL)==TRUE){
    names(LISTCOUL) <- colnames(MATTRANS)
    COUL <- LISTCOUL[names(Transi_T)]
  }

  if(is.null(MAIN)==TRUE){
    MAIN <-paste0(
      "Devenir des stations de type   '",TYPE,"'
  nombre de stations = ",Depart_T)
  }

  if(Depart_T==0){
    barplot(0, horiz = T, xlim = XLIM, xlab = XLAB, yaxt="n",
            col = COUL, border = NA, main = MAIN)
  }else{
    xcoo <- barplot(100*Transi_T, horiz = T, xlim = XLIM, xlab = XLAB, yaxt="n",
                    col = COUL, border = NA, main = MAIN)
    if(POS=="right"){side <- 2 ; pos <- 100}else{side <- 4 ; pos <- 0}
    axis(side = side, at = xcoo, labels = names(Transi_T), tick = F, pos = pos, las = 2)
  }

}

#' barplot_disparitions - trace pour l'ensemble des stations disparues, la proportion par type de station
#'
#' @param PROP_DISP vecteur nommé, donne la proportion de portions de stations par type de station, calculé par mattrans.calc cf $Prop_Disp
#' @param STAT_DISP vecteur nommé, donne le nombre de station disparue entièrement par type de station, calculé par mattrans.calc cf $Nb_Disp
#' @param MATTRANS la matrice de transition calculée avec mattrans.calc cf $Matrice_transition
#' @param POS "left" ou "right" donne la position des noms et nombre des types..
#' @param XLIM permet de changer les limites de l'axe des x doit être sous format c(n,n)
#' @param XLAB permet de changer le titre de l'axe des x doit être entre guillemets
#' @param MAIN permet de changer le titre du graphique doit être entre guillemets
#' @param COUL permet de changer les couleurs des barplot
#' @param LISTCOUL permet de donner la liste complète des couleurs de tous les types (y compris ceux absents du graphe..)
#'
#' @return
#' @export
#'
#' @examples # Exemple avec jeu de données inclu dans le package
#' data_ty
#'
#' # contient colonnes avec les ID des stations, les Dates, les longueurs, les limons,
#' # l'abondance arbustif+ arboré, la fréquence et 4 colonnes pour les données de suivi..
#'
#' # On spécifie la partie ‘suivi’ (ici les colonnes 7 à 10) :
#' suivi <- data_ty[,7:10]
#'
#' Typhamat_all <- mattrans.calc(TAILLE = data_ty$Longueur, FREQ = data_ty$Freq,
#'                                ARB = data_ty$ArbuArbo, LIMONS = data_ty$Limon,
#'                                ANNEES = data_ty$Dates, IDSTATION = data_ty$ID, SUIVI = suivi)
#' # On peut voir la Classification des stations
#' Typhamat_all$Classification
#' data.frame(station = data_ty$ID, Dates = data_ty$Dates,
#'            Classification = Typhamat_all$Classification)
#' # On peut voir la matrice de transition
#' Typhamat_all$Matrice_transition
#'
#' # Pour tracer le bilan des disparitions
#' barplot_disparitions(PROP_DISP = Typhamat_all$Prop_Disp, STAT_DISP = Typhamat_all$Nb_Disp,
#'                      MATTRANS = Typhamat_all$Matrice_transition)
barplot_disparitions <- function(PROP_DISP, STAT_DISP, MATTRANS, POS = "left", XLIM = c(0,100),
                                  XLAB = "Proportion des disparitions (%)",MAIN = NULL, COUL = NULL,
                                  LISTCOUL = c("#FFCCB6","#B9B9B9","#FC8D1D","#2DB30C",
                                               "#305B25","#EAC931","#977D09","#606060")){

  PROP_DISP <- PROP_DISP[names(PROP_DISP)!="8_Disparue"]
  if(is.null(COUL)==TRUE){
    names(LISTCOUL) <- colnames(MATTRANS)
    COUL <- LISTCOUL[names(PROP_DISP)]
  }

  if(is.null(MAIN)==TRUE){
    MAIN <-paste0(
      "Provenance des stations disparues
  nombre de stations concernées = ",sum(STAT_DISP))
  }
  xcoo <- barplot(100*PROP_DISP, horiz = T, xlim = XLIM, xlab = XLAB, yaxt="n",
                  col = COUL, border = NA, main = MAIN)
  if(POS=="right"){side <- 2 ; pos <- 100}else{side <- 4 ; pos <- 0}
  lab_disp <- NULL
  for(i in 1:length(names(PROP_DISP))){
    lab_disp[i] <- paste(names(PROP_DISP)[i],"; n =",ifelse(names(PROP_DISP)[i]%in%names(STAT_DISP)==FALSE,0,STAT_DISP[names(STAT_DISP)==names(PROP_DISP)[i]]))
  }
  axis(side = side, at = xcoo, labels = lab_disp, tick = F, pos = pos, las = 2)

}

#' barplot_apparitions - trace pour l'ensemble des stations apparues, les proportions par type
#'
#' @param APPAR le nombre d'apparition par type, calculé avec mattrans.calc cf $Nb_App
#' @param MATTRANS la matrice de transition calculée avec mattrans.calc cf $Matrice_transition
#' @param POS "left" ou "right" donne la position des noms et nombre des types..
#' @param XLIM permet de changer les limites de l'axe des x doit être sous format c(n,n)
#' @param XLAB permet de changer le titre de l'axe des x doit être entre guillemets
#' @param MAIN permet de changer le titre du graphique doit être entre guillemets
#' @param COUL permet de changer les couleurs des barplot
#' @param LISTCOUL permet de donner la liste complète des couleurs de tous les types (y compris ceux absents du graphe..)
#'
#' @return
#' @export
#'
#' @examples # Exemple avec jeu de données inclu dans le package
#' data_ty
#'
#' # contient colonnes avec les ID des stations, les Dates, les longueurs, les limons,
#' # l'abondance arbustif+ arboré, la fréquence et 4 colonnes pour les données de suivi..
#'
#' # On spécifie la partie ‘suivi’ (ici les colonnes 7 à 10) :
#' suivi <- data_ty[,7:10]
#'
#' Typhamat_all <- mattrans.calc(TAILLE = data_ty$Longueur, FREQ = data_ty$Freq,
#'                                ARB = data_ty$ArbuArbo, LIMONS = data_ty$Limon,
#'                                ANNEES = data_ty$Dates, IDSTATION = data_ty$ID, SUIVI = suivi)
#' # On peut voir la Classification des stations
#' Typhamat_all$Classification
#' data.frame(station = data_ty$ID, Dates = data_ty$Dates,
#'            Classification = Typhamat_all$Classification)
#' # On peut voir la matrice de transition
#' Typhamat_all$Matrice_transition
#'
#' # Pour tracer le bilan des apparitions
#' barplot_apparitions(APPAR = Typhamat_all$Nb_App, MATTRANS = Typhamat_all$Matrice_transition)
#'
barplot_apparitions <- function(APPAR, MATTRANS, POS = "left", XLIM = c(0,100),
                                 XLAB = "Proportion des apparitions (%)",MAIN = NULL, COUL = NULL,
                                 LISTCOUL = c("#FFCCB6","#B9B9B9","#FC8D1D","#2DB30C",
                                              "#305B25","#EAC931","#977D09","#606060")){


  Apparitions <- APPAR/sum(APPAR)

  if(is.null(COUL)==TRUE){
    names(LISTCOUL) <- colnames(MATTRANS)
    COUL <- LISTCOUL[names(Apparitions)]
  }

  if(is.null(MAIN)==TRUE){
    MAIN <-paste0(
      "Classification des stations apparues
  nombre de stations concernées = ",sum(APPAR))
  }
  xcoo <- barplot(100*Apparitions, horiz = T, xlim = XLIM, xlab = XLAB, yaxt="n",
                  col = COUL, border = NA, main = MAIN)
  if(POS=="right"){side <- 2 ; pos <- 100}else{side <- 4 ; pos <- 0}
  lab_app <- paste(names(Apparitions),"; n =",APPAR)
  axis(side = side, at = xcoo, labels = lab_app, tick = F, pos = pos, las = 2)
}
