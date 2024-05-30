#!/usr/bin/gawk -f

############################################################
# DESCRIPTION
#
# INPUT VARIABLES
## tsv_output_file
## tap_report_file
## dropbox_uuid
#
# INPUT FILE(S)
## 
#
# OUTPUT
## files:  from input
## stdout: 
############################################################

BEGIN{
    FS="="
    OFS="\t"
    if(tsv_output_file == ""){
        error_flag = error_flag "ERROR: tsv_output_file variable is mandatory."
    }
    if(tap_report_file == ""){
        error_flag = error_flag "ERROR: tap_report_file variable is mandatory."
    }
    if(dropbox_uuid == ""){
        error_flag = error_flag "ERROR: dropbox_uuid variable is mandatory."
    }
    if (error_flag != "") exit 1

    header[1]="COHORT"
    header[2]="SAMPLE"
    header[3]="UUID"
    header[4]="WGS_GENDER"
    header[5]="WGS_GENDER_TRANSFORMED"
    header[6]="AUTOSOMAL_MEAN_COV"
    header[7]="X_MEAN_COV"
    header[8]="Y_MEAN_COV"
    header[9]="DUP_RATE"
    header[10]="INSERT_MEDIAN"
    header[11]="PCT_15_X"
    header[12]="MEAN_COV"
    header[13]="Q30_ALIGNED_NB"
    header[14]="Q30_ALIGNED_PCT"
    header[15]="CONTAMINATION"
    header[16]="LOD_SCORE"
    header[17]="SNPTRACE_GENDER"
    header[18]="DEMOGRAPHIC_GENDER"
    header[19]="SNPTRACE_GENDER_TEST_MSG"
    header[20]="WGS_GENDER_TEST_MSG"
    header[21]="TOTAL_GENDER_TEST_MSG"
    header[22]="LOD_SCORE_TEST_MSG"
    header[23]="CONTAMINATION_TEST_MSG"
    header[24]="AUTOCOV_TEST_MSG"
    header[25]="PREAGG_QC_FLAG"

}

{
    data[$1]=$2
}

END{
    if(error_flag != "" ){
        printf "%s\t%s", error_flag > "/dev/stderr"
        exit 1
    }

    # print the header for the TAP report
    print "COHORT\tUUID\tTEST_NAME\tTEST_STATUS\tVARIABLE_VALUE\tDETAILED_MESSAGE" > tap_report_file

    # SNPTRACE_GENDER_TEST
    if ("SNPTRACE_GENDER" in data){
        if ("DEMOGRAPHIC_GENDER" in data){
            if (data["SNPTRACE_GENDER"] != data["DEMOGRAPHIC_GENDER"]){
                printf "%s\t%s\tSNPTRACE_GENDER_TEST\tNOK\t%s\tSNPTRACE_GENDER [%s] != DEMOGRAPHIC_GENDER [%s]\n",data["COHORT"],dropbox_uuid,data["SNPTRACE_GENDER"],data["SNPTRACE_GENDER"],data["DEMOGRAPHIC_GENDER"] > tap_report_file
                SNPTRACE_GENDER_TEST=0
                data["SNPTRACE_GENDER_TEST"]=0
                data["SNPTRACE_GENDER_TEST_MSG"]="NOK"
            }else{
                printf "%s\t%s\tSNPTRACE_GENDER_TEST\tOK\t%s\tSNPTRACE_GENDER [%s] == DEMOGRAPHIC_GENDER [%s]\n",data["COHORT"],dropbox_uuid,data["SNPTRACE_GENDER"],data["SNPTRACE_GENDER"],data["DEMOGRAPHIC_GENDER"] > tap_report_file
                SNPTRACE_GENDER_TEST=2
                data["SNPTRACE_GENDER_TEST"]=2
                data["SNPTRACE_GENDER_TEST_MSG"]="OK"
            }
        }else{
            print "ERROR: mandatory data [DEMOGRAPHIC_GENDER] is missing. Please, contact the administrator." > "/dev/stderr"
            exit 1
        }
    }else{
        printf "%s\t%s\tSNPTRACE_GENDER_TEST\tUNCONCLUSIVE\tNA\tSNPTRACE_GENDER not available. Set to 'NA'\n",data["COHORT"],dropbox_uuid > tap_report_file
        data["SNPTRACE_GENDER"]="NA"
        SNPTRACE_GENDER_TEST=1
        data["SNPTRACE_GENDER_TEST"]=1
        data["SNPTRACE_GENDER_TEST_MSG"]="NA"
    }

    # WGS_GENDER_TEST
    if ("WGS_GENDER_TRANSFORMED" in data){
        if(data["WGS_GENDER_TRANSFORMED"] == "NA"){
            printf "%s\t%s\tWGS_GENDER_TEST\tUNCONCLUSIVE\t%s\tWGS_GENDER_TRANSFORMED [%s] not available\n",data["COHORT"],dropbox_uuid,data["WGS_GENDER_TRANSFORMED"],data["WGS_GENDER_TRANSFORMED"] > tap_report_file
            WGS_GENDER_TEST=1
            data["WGS_GENDER_TEST"]=1
            data["WGS_GENDER_TEST_MSG"]="UNCONCLUSIVE"
        }else if ("DEMOGRAPHIC_GENDER" in data){
            if (data["WGS_GENDER_TRANSFORMED"] != data["DEMOGRAPHIC_GENDER"]){
                printf "%s\t%s\tWGS_GENDER_TEST\tNOK\t%s\tWGS_GENDER_TRANSFORMED [%s] != DEMOGRAPHIC_GENDER [%s]\n",data["COHORT"],dropbox_uuid,data["WGS_GENDER_TRANSFORMED"],data["WGS_GENDER_TRANSFORMED"],data["DEMOGRAPHIC_GENDER"] > tap_report_file
                WGS_GENDER_TEST=0
                data["WGS_GENDER_TEST"]=0
                data["WGS_GENDER_TEST_MSG"]="NOK"
            }else{
                printf "%s\t%s\tWGS_GENDER_TEST\tOK\t%s\tWGS_GENDER_TRANSFORMED [%s] == DEMOGRAPHIC_GENDER [%s]\n",data["COHORT"],dropbox_uuid,data["WGS_GENDER_TRANSFORMED"],data["WGS_GENDER_TRANSFORMED"],data["DEMOGRAPHIC_GENDER"] > tap_report_file
                WGS_GENDER_TEST=2
                data["WGS_GENDER_TEST"]=2
                data["WGS_GENDER_TEST_MSG"]="OK"
            }
        }else{
            print "ERROR: mandatory data [DEMOGRAPHIC_GENDER] is missing. Please, contact the administrator." > "/dev/stderr"
            exit 1
        }
    }else{
        print "ERROR: mandatory data [WGS_GENDER_TRANSFORMED] is missing. Please, contact the administrator." > "/dev/stderr"
        exit 1
    }

    # TOTAL_GENDER_TEST
    if(WGS_GENDER_TEST == 0 || (WGS_GENDER_TEST == 2 && SNPTRACE_GENDER_TEST == 0)){
        printf "%s\t%s\tTOTAL_GENDER_TEST\tNOK\t%s%s\tWGS_GENDER_TEST [%s] ; SNPTRACE_GENDER_TEST [%s] -> TOTAL_GENDER_TEST [%s]\n",data["COHORT"],dropbox_uuid,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,TOTAL_GENDER_TEST > tap_report_file
        TOTAL_GENDER_TEST=0
        data["TOTAL_GENDER_TEST"]=0
        data["TOTAL_GENDER_TEST_MSG"]="NOK"
    }else if(WGS_GENDER_TEST == 1){
        printf "%s\t%s\tTOTAL_GENDER_TEST\tUNCONCLUSIVE\t%s%s\tWGS_GENDER_TEST [%s] ; SNPTRACE_GENDER_TEST [%s] -> TOTAL_GENDER_TEST [%s]\n",data["COHORT"],dropbox_uuid,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,TOTAL_GENDER_TEST > tap_report_file
        TOTAL_GENDER_TEST=1
        data["TOTAL_GENDER_TEST"]=1
        data["TOTAL_GENDER_TEST_MSG"]="UNCONCLUSIVE"
    }else if(WGS_GENDER_TEST == 2 && SNPTRACE_GENDER_TEST > 0){
        printf "%s\t%s\tTOTAL_GENDER_TEST\tOK\t%s%s\tWGS_GENDER_TEST [%s] ; SNPTRACE_GENDER_TEST [%s] -> TOTAL_GENDER_TEST [%s]\n",data["COHORT"],dropbox_uuid,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,WGS_GENDER_TEST,SNPTRACE_GENDER_TEST,TOTAL_GENDER_TEST > tap_report_file
        TOTAL_GENDER_TEST=2
        data["TOTAL_GENDER_TEST"]=2
        data["TOTAL_GENDER_TEST_MSG"]="OK"
    }else{
        print "ERROR: an error occurs. Please, contact the administrator." > "/dev/stderr"
        exit 1
    }

    # LOD_SCORE_TEST
    if ("LOD_SCORE" in data){
        if(data["LOD_SCORE"] < -4){
            printf "%s\t%s\tLOD_SCORE_TEST\tNOK\t%s\tLOD [%s] < -4\n",data["COHORT"],dropbox_uuid,data["LOD_SCORE"],data["LOD_SCORE"] > tap_report_file
            LOD_SCORE_TEST=0
            data["LOD_SCORE_TEST"]=0
            data["LOD_SCORE_TEST_MSG"]="NOK"
        }else if(data["LOD_SCORE"] >= 4){
            printf "%s\t%s\tLOD_SCORE_TEST\tOK\t%s\tLOD [%s] >= 4\n",data["COHORT"],dropbox_uuid,data["LOD_SCORE"],data["LOD_SCORE"] > tap_report_file
            LOD_SCORE_TEST=2
            data["LOD_SCORE_TEST"]=2
            data["LOD_SCORE_TEST_MSG"]="OK"
        }else{
            printf "%s\t%s\tLOD_SCORE_TEST\tUNCONCLUSIVE\t%s\t-4 < LOD [%s] < 4, consider as OK\n",data["COHORT"],dropbox_uuid,data["LOD_SCORE"],data["LOD_SCORE"] > tap_report_file
            # specific case, even if it is UNCONCLUSIVE, we set the TESTS result to 2
            LOD_SCORE_TEST=2
            data["LOD_SCORE_TEST"]=2
            data["LOD_SCORE_TEST_MSG"]="UNCONCLUSIVE"
        }
    }else{
        ## no fingerprint results
        ## consider this test as OK
        printf "%s\t%s\tLOD_SCORE_TEST\tOK\tNA\tLOD not available, set to 'NA' and consider as OK\n",data["COHORT"],dropbox_uuid > tap_report_file
        data["LOD_SCORE"]="NA"
        LOD_SCORE_TEST=2
        data["LOD_SCORE_TEST"]=2
        data["LOD_SCORE_TEST_MSG"]="NA"
    }

    # CONTAMINATION_TEST
    if ("CONTAMINATION" in data){
        if (data["CONTAMINATION"] ~ /^[+-]?[0-9]*\.?[0-9]+$/) {
            if(data["CONTAMINATION"] <= 0.02){
                printf "%s\t%s\tCONTAMINATION_TEST\tOK\t%s\tCONTAMINATION [%s] <= 0.02\n",data["COHORT"],dropbox_uuid,data["CONTAMINATION"],data["CONTAMINATION"] > tap_report_file
                CONTAMINATION_TEST=2
                data["CONTAMINATION_TEST"]=2
                data["CONTAMINATION_TEST_MSG"]="OK"
            }else{
                printf "%s\t%s\tCONTAMINATION_TEST\tNOK\t%s\tCONTAMINATION [%s] > 0.02\n",data["COHORT"],dropbox_uuid,data["CONTAMINATION"],data["CONTAMINATION"] > tap_report_file
                CONTAMINATION_TEST=0
                data["CONTAMINATION_TEST"]=0
                data["CONTAMINATION_TEST_MSG"]="NOK"
            }
        }else{
            printf "%s\t%s\tCONTAMINATION_TEST\tUNCONCLUSIVE\t%s\tCONTAMINATION [%s] is not a number\n",data["COHORT"],dropbox_uuid,data["CONTAMINATION"],data["CONTAMINATION"] > tap_report_file
            CONTAMINATION_TEST=1
            data["CONTAMINATION_TEST"]=1
            data["CONTAMINATION_TEST_MSG"]="UNCONCLUSIVE"
        }
    }else{
        print "ERROR: mandatory data [CONTAMINATION] is missing. Please, contact the administrator." > "/dev/stderr"
        exit 1
    }

    # AUTOCOV_TEST
    if("AUTOSOMAL_MEAN_COV" in data){
        if(data["AUTOSOMAL_MEAN_COV"] < 15){
            printf "%s\t%s\tAUTOCOV_TEST\tNOK\t%s\tAUTOSOMAL_MEAN_COV [%s] < 15\n",data["COHORT"],dropbox_uuid,data["AUTOSOMAL_MEAN_COV"],data["AUTOSOMAL_MEAN_COV"] > tap_report_file
            AUTOCOV_TEST=0
            data["AUTOCOV_TEST"]=0
            data["AUTOCOV_TEST_MSG"]="NOK"
        }else{
            printf "%s\t%s\tAUTOCOV_TEST\tOK\t%s\tAUTOSOMAL_MEAN_COV [%s] >= 15\n",data["COHORT"],dropbox_uuid,data["AUTOSOMAL_MEAN_COV"],data["AUTOSOMAL_MEAN_COV"] > tap_report_file
            AUTOCOV_TEST=2
            data["AUTOCOV_TEST"]=2
            data["AUTOCOV_TEST_MSG"]="OK"
        }
    }else{
        print "ERROR: mandatory data [AUTOSOMAL_MEAN_COV] is missing. Please, contact the administrator." > "/dev/stderr"
        exit 1
    }

    # set OK|FAILED for FLAG
    TOTAL=TOTAL_GENDER_TEST+LOD_SCORE_TEST+CONTAMINATION_TEST+AUTOCOV_TEST
    if(TOTAL == 8){
        printf "%s\t%s\tPREAGG_QC_FLAG_TEST\tOK\t%s\tsum of the TESTS [%i] == 8, set FLAG to QC_OK\n",data["COHORT"],dropbox_uuid,TOTAL,TOTAL  > tap_report_file
        data["PREAGG_QC_FLAG"]="QC_OK"
    }else{
        printf "%s\t%s\tPREAGG_QC_FLAG_TEST\tNOK\t%s\tsum of the TESTS [%i] != 8, set FLAG to QC_FAILED\n",data["COHORT"],dropbox_uuid,TOTAL,TOTAL  > tap_report_file
        data["PREAGG_QC_FLAG"]="QC_FAILED"
    }

    # print the header
    for(i=1;i<=length(header);i++){
        if (i == 1) {
            printf "%s", header[i] > tsv_output_file
            first = 0;
        } else {
            printf "%s%s", OFS, header[i] > tsv_output_file
        }
    }
    printf "\n" > tsv_output_file

    # print the content
    for(i=1;i<=length(header);i++){
        if(header[i] in data){
            if (i == 1) {
                printf "%s", data[header[i]] > tsv_output_file
                first = 0;
            } else {
                printf "%s%s", OFS, data[header[i]] > tsv_output_file
            }
        }else{
            printf "ERROR: mandatory data [%s] is missing. Please, contact the administrator.",header[i] > "/dev/stderr"
            exit 1
        }
    }
    printf "\n" > tsv_output_file

    # print the FLAG on stdout
    print data["PREAGG_QC_FLAG"]
}