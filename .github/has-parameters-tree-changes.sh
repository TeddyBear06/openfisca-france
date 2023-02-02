#! /usr/bin/env bash

RED='\033[0;31m'
BLUE='\033[0;34m'
COLOR_RESET='\033[0m'


# openfisca-france array of expected paths for parameters
EXPECTED_PATHS=(
    "openfisca_france"
    "openfisca_france/parameters"    
    "openfisca_france/parameters/chomage"
    "openfisca_france/parameters/chomage/allocation_retour_emploi"
    "openfisca_france/parameters/chomage/allocations_assurance_chomage"
    "openfisca_france/parameters/chomage/allocations_chomage_solidarite"
    "openfisca_france/parameters/chomage/preretraites"
    "openfisca_france/parameters/geopolitique"  # premier niveau bloqué seulement ; n'existe pas dans les barèmes IPP
    "openfisca_france/parameters/impot_revenu"  # + 1 niveau / premier niveau bloqué seulement ; à harmoniser avec les barèmes IPP
    "openfisca_france/parameters/marche_travail"
    "openfisca_france/parameters/marche_travail/epargne"  # bloqué mais n'existe pas dans les barèmes IPP
    "openfisca_france/parameters/marche_travail/remuneration_dans_fonction_publique"
    "openfisca_france/parameters/marche_travail/salaire_minimum"
    "openfisca_france/parameters/prelevements_sociaux"
    "openfisca_france/parameters/prelevements_sociaux/autres_taxes_participations_assises_salaires"
    "openfisca_france/parameters/prelevements_sociaux/contributions_assises_specifiquement_accessoires_salaire"
    "openfisca_france/parameters/prelevements_sociaux/contributions_sociales"
    "openfisca_france/parameters/prelevements_sociaux/cotisations_regime_assurance_chomage"
    "openfisca_france/parameters/prelevements_sociaux/cotisations_secteur_public"
    "openfisca_france/parameters/prelevements_sociaux/cotisations_securite_sociale_regime_general"
    "openfisca_france/parameters/prelevements_sociaux/cotisations_taxes_independants_artisans_commercants"
    "openfisca_france/parameters/prelevements_sociaux/cotisations_taxes_professions_liberales"
    "openfisca_france/parameters/prelevements_sociaux/pss"  # bloqué mais est un dispositif législatif, pas une catégorie métier
    "openfisca_france/parameters/prelevements_sociaux/reductions_cotisations_sociales"
    "openfisca_france/parameters/prelevements_sociaux/regimes_complementaires_retraite_secteur_prive"
    "openfisca_france/parameters/prestations_sociales"
    "openfisca_france/parameters/prestations_sociales/aides_jeunes"
    "openfisca_france/parameters/prestations_sociales/aides_logement"
    "openfisca_france/parameters/prestations_sociales/fonc"
    "openfisca_france/parameters/prestations_sociales/prestations_etat_de_sante"
    "openfisca_france/parameters/prestations_sociales/prestations_etat_de_sante/invalidite"
    "openfisca_france/parameters/prestations_sociales/prestations_etat_de_sante/perte_autonomie_personnes_agees"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/bmaf"  # bloqué mais est un dispositif législatif, pas une catégorie métier
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/def_biactif"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/def_pac"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/education_presence_parentale"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/logement_cadre_vie"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/petite_enfance"
    "openfisca_france/parameters/prestations_sociales/prestations_familiales/prestations_generales"
    "openfisca_france/parameters/prestations_sociales/solidarite_insertion"
    "openfisca_france/parameters/prestations_sociales/solidarite_insertion/autre_solidarite"
    "openfisca_france/parameters/prestations_sociales/solidarite_insertion/minima_sociaux"
    "openfisca_france/parameters/prestations_sociales/solidarite_insertion/minimum_vieillesse"
    "openfisca_france/parameters/prestations_sociales/transport"
    "openfisca_france/parameters/taxation_capital"
    "openfisca_france/parameters/taxation_capital/impot_fortune_immobiliere_ifi_partir_2018"
    "openfisca_france/parameters/taxation_capital/impot_grandes_fortunes_1982_1986"
    "openfisca_france/parameters/taxation_capital/impot_solidarite_fortune_isf_1989_2017"
    "openfisca_france/parameters/taxation_capital/prelevement_forfaitaire"
    "openfisca_france/parameters/taxation_capital/prelevements_sociaux"
    "openfisca_france/parameters/taxation_indirecte"  # + 1 niveau ; premier niveau bloqué seulement ; à harmoniser avec les barèmes IPP
    "openfisca_france/parameters/taxation_societes"  # premier niveau bloqué seulement ; à harmoniser avec les barèmes IPP
    )
EXPECTED_PATHS_MAX_DEPTH=4  # ! EXPECTED_PATHS and EXPECTED_PATHS_MAX_DEPTH should be consistent


# compare with last published git tag: 
# list indexed parameters paths indexed in current branch according to EXPECTED_PATHS_MAX_DEPTH
BRANCH_PATHS_ROOT="openfisca_france/parameters/"
last_tagged_commit=`git describe --tags --abbrev=0 --first-parent`  # --first-parent ensures we don't follow tags not published in master through an unlikely intermediary merge commit
checked_tree=`git ls-tree ${last_tagged_commit} -d --name-only -r ${BRANCH_PATHS_ROOT} | cut -d / -f-${EXPECTED_PATHS_MAX_DEPTH} | uniq`


# compare current indexed parameters tree with EXPECTED_PATHS
all_paths=`echo ${EXPECTED_PATHS[@]} ${checked_tree[@]} | tr ' ' '\n' | sort | uniq -D | uniq`
error_status=0

added=`echo ${all_paths[@]} ${checked_tree[@]} | tr ' ' '\n' | sort | uniq -u | uniq`
added_checked=()
if [[ ${added[@]} ]]; then
    for item in $added; do
        # DEBUG echo "😈  "$item
        # item seems new; should we list it or should we ignore this depth ?
        item_parent=`dirname $item`
        item_parent_depth=`echo $item_parent | grep -o / | wc -l`

        if [[ " ${EXPECTED_PATHS[*]} " =~ " ${item_parent} " ]]; then            
            # est-ce qu'il existe des sous-répertoires (de même niveau que item ou plus bas) à respecter ?
            parent_and_subdirs_expected=`echo ${EXPECTED_PATHS[@]} | tr ' ' '\n' | grep ${item_parent}`
            parent_and_subdirs_expected_array=($parent_and_subdirs_expected)
            list_length=`echo "$parent_and_subdirs_expected"  | wc -l`
            
            # DEBUG echo "> le parent "$item_parent" est dans la liste à respecter avec ce nombre d'occurrences : "$list_length
            # DEBUG printf '%s\n' "${parent_and_subdirs_expected[@]}"

            j=0
            while [ $j -lt $list_length ]; do
                expected_item_depth=`echo ${parent_and_subdirs_expected_array[$j]} | grep -o / | wc -l`
                
                # DEBUG echo "$j on compare ce répertoire supposément ajouté à la liste des répertoires obligatoires : "${parent_and_subdirs_expected_array[$j]}
                
                if [ $expected_item_depth -gt $item_parent_depth ]; then
                    # 👹 il existe au moins un répertoire de même profondeur ou plus que l'item courant donc, l'item courant est louche
                    added_checked+=($item)
                    break
                fi
                ((j++))
            done            
        fi 
    done

    echo "${BLUE}INFO Ces répertoires de paramètres ont été ajoutés :${COLOR_RESET}"
    printf '%s\n' ${added_checked[@]}
    error_status=1
fi

lost=`echo ${all_paths[@]} ${EXPECTED_PATHS[@]} | tr ' ' '\n' | sort | uniq -u | uniq`
if [[ ${lost[@]} ]]; then
    echo "${BLUE}INFO Ces répertoires de paramètres ont été supprimés :${COLOR_RESET}"
    printf '%s\n' "${lost[@]}"
    error_status=2
fi


if [[ ${error_status} ]]; then
    echo "${RED}ERREUR L'arborescence des paramètres a été modifiée.${COLOR_RESET}"
    echo "Elle est commune à openfisca-france et aux Barèmes IPP sur ${EXPECTED_PATHS_MAX_DEPTH} niveaux." 
    echo "Corriger les écarts constatés ci-dessus ou proposer la modification de cette arborescence commune"
    echo "dans une nouvelle issue : https://github.com/openfisca/openfisca-france/issues/new"
    echo "Pour en savoir plus : https://github.com/openfisca/openfisca-france/issues/1811"
fi
exit ${error_status}
