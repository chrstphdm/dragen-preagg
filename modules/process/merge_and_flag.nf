process MERGE_AND_FLAG {

    publishDir "${params.taps_output_folder}",
        pattern: "*.{tap,ALL_METRICS}", 
        mode: "copy", 
        failOnError: true

	tag "${meta.dropbox_uuid}"

    input:
        tuple   val(sample_id),
                val(meta),
                path(common_qc_file),
                val(fingerprint_file)

    output:
        path("${meta.dropbox_uuid}.ALL_METRICS"), emit: all_metrics
        path("${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tap"), emit: tap_reports
        path("${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tsv"), emit: tsv_reports

    script:

    if ( fingerprint_file )
        """
        #############################
        ## WITH FINGERPRINT FILE
        cat "${common_qc_file}" "${fingerprint_file}" > ${meta.dropbox_uuid}.ALL_METRICS
        echo "DEMOGRAPHIC_GENDER=${meta.gender}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "COHORT=${meta.cohort_name}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "SAMPLE=${meta.sample_name}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "UUID=${meta.dropbox_uuid}" >> ${meta.dropbox_uuid}.ALL_METRICS

        PREAGG_QC_FLAG=\$(${meta.cohort_name}_data_get_status.awk -v dropbox_uuid="${meta.dropbox_uuid}" -v tsv_output_file="${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tsv" -v tap_report_file="${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tap" ${meta.dropbox_uuid}.ALL_METRICS)

        if [ ${(params.dry ? 1 : 0)} -eq 0 ]; then
            echo -e "${meta.gvcf_file}\n${params.dragen_preagg_instance_id}" > "${params.preagg_flags_path}/${meta.cohort_name}/${meta.dropbox_uuid}.\${PREAGG_QC_FLAG}"
        fi

        """
    else
        """
        #############################
        ## NO FINGERPRINT FILE
        cat "${common_qc_file}" > ${meta.dropbox_uuid}.ALL_METRICS
        echo "DEMOGRAPHIC_GENDER=${meta.gender}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "COHORT=${meta.cohort_name}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "SAMPLE=${meta.sample_name}" >> ${meta.dropbox_uuid}.ALL_METRICS
        echo "UUID=${meta.dropbox_uuid}" >> ${meta.dropbox_uuid}.ALL_METRICS

        PREAGG_QC_FLAG=\$(${meta.cohort_name}_data_get_status.awk -v dropbox_uuid="${meta.dropbox_uuid}" -v tsv_output_file="${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tsv" -v tap_report_file="${meta.dropbox_uuid}.${meta.cohort_name}.check_qc.tap" ${meta.dropbox_uuid}.ALL_METRICS)

        if [ ${(params.dry ? 1 : 0)} -eq 0 ]; then
            echo -e "${meta.gvcf_file}\n${params.dragen_preagg_instance_id}" > "${params.preagg_flags_path}/${meta.cohort_name}/${meta.dropbox_uuid}.\${PREAGG_QC_FLAG}"
        fi

        """
}