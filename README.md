# Dragen Preagg Workflow

This Nextflow Pipelne represents a workflow for processing genetic data generated with the `dragen-wrapper` script. It takes input files and parameters, performs quality control, fingerprinting, merging, and flagging of the data. The workflow outputs TSV and TAP reports containing the processed data.

## Usage

The pipeline must be launched with a wrapper `dragen-preagg`. It sets up the environment, loads necessary modules, and executes the Nextflow workflow. The script also handles user interruptions, captures logs, and saves the exit status of the workflow.