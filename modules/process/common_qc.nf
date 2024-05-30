process COMMON_QC {
    
	tag "${meta.dropbox_uuid}"

    input:
        tuple val(sample_id), val(meta)

    output:
        tuple   val(sample_id), 
                val (meta), 
                path("${meta.dropbox_uuid}.COMMON_QC")

    script:

    """
	WGS_GENDER=\$(grep \'PLOIDY ESTIMATION,,Ploidy estimation,\' ${meta.ploidy_estimation_metrics_file} | cut -f 4 -d ,)
	WGS_GENDER_TRANSFORMED='OTHER'

	if [ "\$WGS_GENDER" == "XX" ]; then
		WGS_GENDER_TRANSFORMED='FEMALE'
	elif [ "\$WGS_GENDER" == "XY" ]; then
		WGS_GENDER_TRANSFORMED='MALE'
    elif  [ "\$WGS_GENDER" == "" ]; then
        WGS_GENDER="NA"
        WGS_GENDER_TRANSFORMED="NA"
	fi



	X_MEAN_COV=\$(grep \'COVERAGE SUMMARY,,Average chr X coverage over genome\'  ${meta.wgs_coverage_metrics_file} | cut -f 4 -d ,)

	Y_MEAN_COV=\$(grep \'COVERAGE SUMMARY,,Average chr Y coverage over genome\'  ${meta.wgs_coverage_metrics_file} | cut -f 4 -d ,)

	AUTOSOMAL_MEAN_COV=\$(grep \'COVERAGE SUMMARY,,Average autosomal coverage over genome\'  ${meta.wgs_coverage_metrics_file} | cut -f 4 -d ,)

	CONTAMINATION=\$(grep \'MAPPING/ALIGNING SUMMARY,,Estimated sample contamination,\' ${meta.mapping_metrics_file} | cut -f 4 -d ,)

	DUP_RATE=\$(grep \'MAPPING/ALIGNING SUMMARY,,Number of duplicate marked reads,\' ${meta.mapping_metrics_file} | cut -f 5 -d ,)

	INSERT_MEDIAN=\$(grep \'MAPPING/ALIGNING SUMMARY,,Insert length: median,\' ${meta.mapping_metrics_file} | cut -f 4 -d ,)

	PCT_15_X=\$(grep \'COVERAGE SUMMARY,,PCT of genome with coverage \\[  15x: inf),\' ${meta.wgs_coverage_metrics_file} | cut -f 4 -d ,)

	MEAN_COV=\$(grep \'COVERAGE SUMMARY,,Average alignment coverage over genome,\' ${meta.wgs_coverage_metrics_file} | cut -f 4 -d ,)

	Q30_ALIGNED_NB=\$(grep \'MAPPING/ALIGNING SUMMARY,,Q30 bases,\' ${meta.mapping_metrics_file} | cut -f 4 -d ,)

	Q30_ALIGNED_PCT=\$(grep \'MAPPING/ALIGNING SUMMARY,,Q30 bases,\' ${meta.mapping_metrics_file} | cut -f 5 -d ,)

    echo "WGS_GENDER=\${WGS_GENDER}" > ${meta.dropbox_uuid}.COMMON_QC
    echo "WGS_GENDER_TRANSFORMED=\${WGS_GENDER_TRANSFORMED}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "AUTOSOMAL_MEAN_COV=\${AUTOSOMAL_MEAN_COV}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "X_MEAN_COV=\${X_MEAN_COV}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "Y_MEAN_COV=\${Y_MEAN_COV}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "DUP_RATE=\${DUP_RATE}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "INSERT_MEDIAN=\${INSERT_MEDIAN}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "PCT_15_X=\${PCT_15_X}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "MEAN_COV=\${MEAN_COV}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "Q30_ALIGNED_NB=\${Q30_ALIGNED_NB}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "Q30_ALIGNED_PCT=\${Q30_ALIGNED_PCT}" >> ${meta.dropbox_uuid}.COMMON_QC
    echo "CONTAMINATION=\${CONTAMINATION}" >> ${meta.dropbox_uuid}.COMMON_QC

	"""

}
