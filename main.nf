#!/usr/bin/env nextflow

/**
 * This Nextflow script represents a workflow for processing genetic data using the Dragen Preagg pipeline.
 * It takes input files and parameters, performs quality control, fingerprinting, merging, and flagging of the data.
 * The workflow outputs TSV and TAP reports containing the processed data.
 *
 * Workflow Steps:
 * 1. Check if the mandatory parameter `sample_cohort_gender_list` is specified. If not, log an error and exit.
 * 2. Read input files and parameters.
 * 3. Check the existence of the `sample_cohort_gender_list` file.
 * 4. Split the processed QC file into individual samples and create a tuple for each sample containing relevant information and file paths.
 * 5. Perform common QC on the samples.
 * 6. Perform fingerprinting on the samples that have a corresponding SNPtrace VCF file.
 * 7. Merge the common QC and fingerprinting outputs and flag the samples.
 * 8. Collect the TSV reports and save them to a file.
 * 9. Collect the TAP reports and save them to a file.
 * 10. Print the completion status of the pipeline.
 */


nextflow.enable.dsl=2

include { CHECK_INPUT_FILE  } from './modules/process/check_input_file.nf'
include { FINGERPRINT       } from './modules/process/fingerprint.nf'
include { COMMON_QC         } from './modules/process/common_qc.nf'
include { MERGE_AND_FLAG    } from './modules/process/merge_and_flag.nf'

workflow {
    // Step 1: Check if the mandatory parameter `sample_cohort_gender_list` is specified. If not, log an error and exit.
    if (params.sample_cohort_gender_list == "") {
        log.error "No sample_cohort_gender_list specified. This is a mandatory parameter."
        exit 1
    }
    
    // Step 2: Read input files and parameters.
    map_file            = file(params.snptrace_map_file         ,checkIfExists:true)
    my_org_flags_path   = file(params.my_org_flags_path           ,checkIfExists:true)
    preagg_flags_path   = file(params.preagg_flags_path         ,checkIfExists:true)
    delivered_path      = file(params.delivered_path            ,checkIfExists:true)

    // Step 3: Check the existence of the `sample_cohort_gender_list` file.
    CHECK_INPUT_FILE(file(params.sample_cohort_gender_list, checkIfExists: true))

    // Step 4: Split the processed QC file into individual samples and create a tuple for each sample containing relevant information and file paths.
    to_preagg_list = CHECK_INPUT_FILE.out.QC_processed
        .splitCsv(sep: "\t").map { 
            row-> tuple(row[0],[
                dropbox_uuid: row[3], 
                sample_name: row[0], 
                cohort_name: row[1], 
                gender: row[2],
                gvcf_file: file("${delivered_path}/${row[3]}/${row[0]}.hard-filtered.gvcf.gz", checkIfExists:true), 
                vcf_file: file("${delivered_path}/${row[3]}/${row[0]}.hard-filtered.vcf.gz", checkIfExists:true), 
                vcf_idx_file: file("${delivered_path}/${row[3]}/${row[0]}.hard-filtered.vcf.gz.tbi", checkIfExists:true), 
                mapping_metrics_file: file("${delivered_path}/${row[3]}/${row[0]}.mapping_metrics.csv", checkIfExists:true), 
                ploidy_estimation_metrics_file: file("${delivered_path}/${row[3]}/${row[0]}.ploidy_estimation_metrics.csv", checkIfExists:true), 
                wgs_coverage_metrics_file: file("${delivered_path}/${row[3]}/${row[0]}.wgs_coverage_metrics.csv", checkIfExists:true),
                snptrace_vcf_file: file("${params.snptrace_files_path}/${row[0]}.SNPtrace-96Var-FingerPrint.processed.vcf.sorted.vcf.gz"), 
                snptrace_vcf_idx_file: file("${params.snptrace_files_path}/${row[0]}.SNPtrace-96Var-FingerPrint.processed.vcf.sorted.vcf.gz.tbi")
            ]) 
        }

    // Step 5: Perform common QC on the samples.
    COMMON_QC(to_preagg_list)

    // Step 6: Perform fingerprinting on the samples that have a corresponding SNPtrace VCF file.
    FINGERPRINT(
        to_preagg_list.filter{it[1].snptrace_vcf_file.exists()}, 
        map_file
    )

    // Step 7: Merge the common QC and fingerprinting outputs and flag the samples.
    MERGE_AND_FLAG(
        COMMON_QC.out.join(FINGERPRINT.out, remainder: true).map{
            it ->
                if(it.size == 5)
                    tuple( it[0],it[1]+it[3],it[2],it[4])
                else
                    tuple( it[0],it[1],it[2],"")
        }
    )

    // Step 8: Collect the TSV reports and save them to a file.
    MERGE_AND_FLAG.out.tsv_reports.collectFile(
        name: "${params.today}.global${params.dry?".dry":""}.tsv", 
        newLine: false,
        keepHeader: true,
        storeDir: "${params.dragen_preagg_instance_path}",
        sort:false
    ).subscribe {
        println "Entries are saved to file: $it"
    }

    // Step 9: Collect the TAP reports and save them to a file.
    MERGE_AND_FLAG.out.tap_reports.collectFile(
        name: "${params.today}.global${params.dry?".dry":""}.tap", 
        newLine: false,
        keepHeader: true,
        storeDir: "${params.dragen_preagg_instance_path}",
        sort:false
    ).subscribe {
        println "Entries are saved to file: $it"
    }
}

workflow.onComplete {
    // Step 10: Print the completion status of the pipeline.
    println ""
    println "####################################################################"
    println "#"
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'ERROR' }"
    println "#"
    println "####################################################################"
    println ""
}
