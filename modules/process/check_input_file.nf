process CHECK_INPUT_FILE{

    executor "local"

    publishDir "${params.dragen_preagg_instance_path}", 
        mode: "copy", 
        failOnError: true

    input:
        path tsv_input_file

    output:
        path (tsv_input_file), emit: original_tsv
        path ("${tsv_input_file}.QC_processed"), emit: QC_processed
        path "${tsv_input_file}.already_qc_flagged", emit: already_qc_flagged, optional: true
        path "${tsv_input_file}.delivered_missing", emit: delivered_missing, optional: true
        path "${tsv_input_file}.QC_pending", emit: should_be_preagg, optional: true

    script:
    """
    #################################
    ## check the header
    expected_header="SAMPLE_NAME\tCOHORT\tGENDER"
    actual_header=\$(head -n 1 "${tsv_input_file}")
    if [[ "\${actual_header}" != "\${expected_header}" ]]; then
        echo "ERROR: sample_cohort_gender FILE HEADER is not correct. Should contains [\${expected_header}]. Can not continue."
        exit 1
    fi

    #################################
    ## snapshot of the situation
    find ${params.my_org_flags_path} -maxdepth 1 -type f -regextype posix-extended -regex ".*_[0-9a-fA-F-]+_[0-9]{8}.DELIVERED" > all_delivered
    find ${params.preagg_flags_path} -maxdepth 2 -type f -regextype posix-extended -regex ".*_[0-9a-fA-F-]+_[0-9]{8}.QC_(OK|FAILED|FORCED)" > all_qc_checked

    #################################
    check_and_get.awk -v to_preagg="${tsv_input_file}.QC_processed" -v already_qc_delivered_file="${tsv_input_file}.already_qc_flagged" -v delivered_missing_file="${tsv_input_file}.delivered_missing" -v should_be_preagg_file="${tsv_input_file}.QC_pending" all_delivered all_qc_checked ${tsv_input_file}

    #################################
    if [ ! -f "${tsv_input_file}.QC_processed" ]; then
        echo -e "ERROR: as the to_preagg file [${tsv_input_file}.QC_processed] does not exist, no samples can be analyzed by preagg.\nPlease, check the files\n - already_qc_flagged [${tsv_input_file}.already_qc_flagged]\n - delivered_missing [${tsv_input_file}.delivered_missing]\ndirectly from the WORKDIR of the current process to understand what is going on." > /dev/stderr
        exit 1
    fi

    #################################
    awk 'BEGIN{FS="\t"}{print \$2}' ${tsv_input_file}.QC_processed | sort -u | while read cohort_value; do
        if [ ! -d "${params.preagg_flags_path}/\${cohort_value}" ]; then
            echo "ERROR: COHORT folder [${params.preagg_flags_path}/\${cohort_value}] MUST exists. Please, contact the administrator ".
            exit 1
        fi
        if ! which \${cohort_value}_data_get_status.awk >/dev/null 2>&1; then
            echo "ERROR: a specific script [\${cohort_value}_data_get_status.awk] must be created in the current pipeline (bin folder). Please, contact the administrator."
            exit 1
        fi
    done

    """
}
