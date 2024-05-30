#!/usr/bin/gawk -f

############################################################
# DESCRIPTION
#
# INPUT VARIABLES
## to_preagg
## already_qc_delivered_file
## delivered_missing_file
## should_be_preagg_file
#
#
# OUTPUT
## files from input
############################################################

BEGIN{
    FS="/"
    OFS="\t"

    counter=1

    if(to_preagg == ""){
        error_flag = error_flag "ERROR: to_preagg variable is mandatory.\n"
    }
    if(already_qc_delivered_file == ""){
        error_flag = error_flag "ERROR: already_qc_delivered_file variable is mandatory.\n"
    }
    if(delivered_missing_file == ""){
        error_flag = error_flag "ERROR: delivered_missing_file variable is mandatory.\n"
    }
    if(should_be_preagg_file == ""){
        error_flag = error_flag "ERROR: should_be_preagg_file variable is mandatory.\n"
    }

    if (error_flag != "") exit 1
}

ARGIND == 1{
    ## all_delivered 
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})\.(.*)/,arr)
    sample_id=arr[1]
    uuid=arr[2]
    date=arr[3]
    flag=arr[4]

    wgs_data[sample_id][sample_id"_"uuid"_"date]["DELIVERED"]=$0
}

ARGIND == 2{
    ## all_qc_checked 
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})\.(.*)/,arr)
    sample_id=arr[1]
    uuid=arr[2]
    date=arr[3]
    flag=arr[4]
    cohort=$(NF-1)

    wgs_data[sample_id][sample_id"_"uuid"_"date]["QC_FLAG"][cohort]=$0
}

ARGIND == 3 && FNR > 1{
    ## sample_cohort_gender_list
    split($NF, arr, "\t")
    sample_id=arr[1]
    cohort=arr[2]
    gender=arr[3]

    if(sample_id in user_data){
        error_flag = error_flag "ERROR: line "FNR", sample_name ["arr[1]"] has already been encountered in the input file. Please, correct the input file and relaunch\n"
        exit 1
    }
    user_data[arr[1]][arr[2]]=$0
}

END{
    if(error_flag != "" ){
        printf "%s", error_flag > "/dev/stderr"
        exit 1
    }
    for(sample_id in user_data){
        for(current_cohort in user_data[sample_id]){
            all_line=user_data[sample_id][current_cohort]
            if(sample_id in wgs_data){
                if(length(wgs_data[sample_id]) > 1){
                    print "ERROR: the sample "sample_id" is linked to many DROPBOX_UUID. Contact the admin."
                    exit 1
                }else{
                    ## fake 'for' loop as there is only one element
                    for(dropbox_uuid in wgs_data[sample_id]){ 
                        if("DELIVERED" in wgs_data[sample_id][dropbox_uuid]){
                            ## DELIVERED flag exists for the current sample_id
                            if("QC_FLAG" in wgs_data[sample_id][dropbox_uuid]){
                                ## at leat one QC_FLAG flag exists for the current sample_id
                                ## need to check which cohort(s)
                                if(current_cohort in wgs_data[sample_id][dropbox_uuid]["QC_FLAG"]){
                                    ## already analyzed with the same cohort
                                    print all_line,wgs_data[sample_id][dropbox_uuid]["QC_FLAG"][current_cohort] > already_qc_delivered_file
                                    delete wgs_data[sample_id]
                                }else{
                                    ## already analyzed BUT with a different cohort
                                    ## so it can be analyzed
                                    print all_line,dropbox_uuid > to_preagg
                                    delete wgs_data[sample_id]
                                }
                            }else{
                                ## no QC_FLAG
                                ## can be analyzed
                                print all_line,dropbox_uuid > to_preagg
                                delete wgs_data[sample_id]
                            }
                        }else if("QC_FLAG" in wgs_data[sample_id][dropbox_uuid]){
                            ## not DELIVERED but already analyzed in at least one COHORT
                            ## this is strange
                            print "ERROR: the sample "sample_id" is not DELIVERED but a QC_FLAG exists ["wgs_data[sample_id][dropbox_uuid]["QC_FLAG"]"]. Contact the admin."
                            exit 1
                        }else{
                            ## neither DELIVERED nor QC_FLAGED
                            ## so the DELIVERY process is still pending
                            print all_line > delivered_missing_file
                            delete wgs_data[sample_id]
                        }
                    }
                }
            }else{
                ## neither DELIVERED nor QC_FLAGED
                ## so the DELIVERY process is still pending
                print all_line > delivered_missing_file
                delete wgs_data[sample_id]
            }
        }
    }
    for(sample_id in wgs_data){
        if(length(wgs_data[sample_id]) > 1){
            print "ERROR: the sample "sample_id" is linked to many DROPBOX_UUID. Contact the admin."
            exit 1
        }else{
            for(dropbox_uuid in wgs_data[sample_id]){
                if("DELIVERED" in wgs_data[sample_id][dropbox_uuid]){
                    if("QC_FLAG" in wgs_data[sample_id][dropbox_uuid]){
                    }else{
                        ## this is DELIVERED data
                        ## without QC_FLAG
                        ## not in the user list
                        ## so, should be preagg
                        print wgs_data[sample_id][dropbox_uuid]["DELIVERED"] > should_be_preagg_file
                    }
                }
            }
        }
    }
}