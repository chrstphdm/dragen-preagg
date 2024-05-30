process FINGERPRINT {
    
    label 'GATK4'

    clusterOptions = '-P PreAgg -q my_org-production-low  '

	tag "${meta.dropbox_uuid}"

    input:
        tuple   val(sample_id),
                val (meta)
		path (map_file)

    output:
		tuple   val(sample_id), 
                val (meta), 
                path("${meta.dropbox_uuid}.FINGERPRINT")

    script:

    """
        gatk CheckFingerprint \\
            --INPUT ${meta.vcf_file} \\
            --GENOTYPES ${meta.snptrace_vcf_file} \\
            --HAPLOTYPE_MAP ${map_file} \\
            --GENOTYPE_LOD_THRESHOLD 5 \\
            --TMP_DIR . \\
            --OUTPUT ${meta.dropbox_uuid} 

        LOD_SCORE=\$(grep -A 1 \"^READ_GROUP\" ${meta.dropbox_uuid}.fingerprinting_summary_metrics | tail -n1 | cut -f5)
        RAW_GENDER=\$(zgrep -v \"^#\" ${meta.snptrace_vcf_file} | head -n1 | cut -f8 | sed -e \'s/.*Fluidigm_GENDER=\\(.*\\)/\\1/\')
        SNPTRACE_GENDER=\${RAW_GENDER^^}

        echo "LOD_SCORE=\${LOD_SCORE}" > ${meta.dropbox_uuid}.FINGERPRINT
        echo "SNPTRACE_GENDER=\${SNPTRACE_GENDER}" >> ${meta.dropbox_uuid}.FINGERPRINT
	"""

}


