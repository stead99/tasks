task CollectMultipleMetrics {
    String? preCommand
    File bamFile
    File bamIndex
    File refFasta
    File refDict
    File refFastaIndex
    String basename

    # These should proably be optional, but I'm not sure how to handle the ouput in that
    # case (without a null literal).
    Boolean collectAlignmentSummaryMetrics = true
    Boolean collectInsertSizeMetrics = true
    Boolean qualityScoreDistribution = true
    Boolean meanQualityByCycle = true
    Boolean collectBaseDistributionByCycle = true
    Boolean collectGcBiasMetrics = true
    #Boolean? rnaSeqMetrics = false # There is a bug in picard https://github.com/broadinstitute/picard/issues/999
    Boolean collectSequencingArtifactMetrics = true
    Boolean collectQualityYieldMetrics = true

    String? picardJar

    Float? memory
    Float? memoryMultiplier

    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
        then "java -Xmx" + mem + "G -jar " + picardJar
        else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        mkdir -p $(dirname "${basename}")
        ${preCommand}
        ${toolCommand} \
        CollectMultipleMetrics \
        I=${bamFile} \
        R=${refFasta} \
        O=${basename} \
        PROGRAM=null \
        ${true="PROGRAM=CollectAlignmentSummaryMetrics" false="" collectAlignmentSummaryMetrics} \
        ${true="PROGRAM=CollectInsertSizeMetrics" false="" collectInsertSizeMetrics} \
        ${true="PROGRAM=QualityScoreDistribution" false="" qualityScoreDistribution} \
        ${true="PROGRAM=MeanQualityByCycle" false="" meanQualityByCycle} \
        ${true="PROGRAM=CollectBaseDistributionByCycle" false="" collectBaseDistributionByCycle} \
        ${true="PROGRAM=CollectGcBiasMetrics" false="" collectGcBiasMetrics} \
        ${true="PROGRAM=CollectSequencingArtifactMetrics" false=""
            collectSequencingArtifactMetrics} \
        ${true="PROGRAM=CollectQualityYieldMetrics" false="" collectQualityYieldMetrics}
    }

    output {
        File aligmentSummary = basename + ".alignment_summary_metrics"
        File baitBiasDetail = basename + ".bait_bias_detail_metrics"
        File baitBiasSummary = basename + ".bait_bias_summary_metrics"
        File baseDistributionByCycle = basename + ".base_distribution_by_cycle_metrics"
        File baseDistributionByCyclePdf = basename + ".base_distribution_by_cycle.pdf"
        File errorSummary = basename + ".error_summary_metrics"
        File gcBiasDetail = basename + ".gc_bias.detail_metrics"
        File gcBiasPdf = basename + ".gc_bias.pdf"
        File gcBiasSummary = basename + ".gc_bias.summary_metrics"
        File insertSizeHistogramPdf = basename + ".insert_size_histogram.pdf"
        File insertSize = basename + ".insert_size_metrics"
        File preAdapterDetail = basename + ".pre_adapter_detail_metrics"
        File preAdapterSummary = basename + ".pre_adapter_summary_metrics"
        File qualityByCycle = basename + ".quality_by_cycle_metrics"
        File qualityByCyclePdf = basename + ".quality_by_cycle.pdf"
        File qualityDistribution = basename + ".quality_distribution_metrics"
        File qualityDistributionPdf = basename + ".quality_distribution.pdf"
        File qualityYield = basename + ".quality_yield_metrics"
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

task CollectRnaSeqMetrics {
    String? preCommand
    File bamFile
    File bamIndex
    File refRefflat
    String basename
    String? strandSpecificity = "NONE"

    String? picardJar

    Float? memory
    Float? memoryMultiplier

    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
        then "java -Xmx" + mem + "G -jar " + picardJar
        else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        mkdir -p $(dirname "${basename}")
        ${preCommand}
        ${toolCommand} \
        CollectRnaSeqMetrics \
        I=${bamFile} \
        O=${basename}.RNA_Metrics \
        CHART_OUTPUT=${basename}.RNA_Metrics.pdf \
        ${"STRAND_SPECIFICITY=" + strandSpecificity} \
        REF_FLAT=${refRefflat}
    }

    output {
        File chart = basename + ".RNA_Metrics.pdf"
        File metrics = basename + ".RNA_Metrics"
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

task CollectTargetedPcrMetrics {
    String? preCommand
    File bamFile
    File bamIndex
    File refFasta
    File refDict
    File refFastaIndex
    File ampliconIntervals
    Array[File]+ targetIntervals
    String basename

    String? picardJar

    Float? memory
    Float? memoryMultiplier

    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
        then "java -Xmx" + mem + "G -jar " + picardJar
        else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        mkdir -p $(dirname "${basename}")
        ${preCommand}
        ${toolCommand} \
        CollectTargetedPcrMetrics \
        I=${bamFile} \
        R=${refFasta} \
        AMPLICON_INTERVALS=${ampliconIntervals} \
        TARGET_INTERVALS=${sep=" TARGET_INTERVALS=" targetIntervals} \
        O=${basename}.targetPcrMetrics \
        PER_BASE_COVERAGE=${basename}.targetPcrPerBaseCoverage \
        PER_TARGET_COVERAGE=${basename}.targetPcrPerTargetCoverage
    }

    output {
        File perTargetCoverage = basename + ".targetPcrPerTargetCoverage"
        File perBaseCoverage = basename + ".targetPcrPerBaseCoverage"
        File metrics = basename + "targetPcrMetrics"
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

# Combine multiple recalibrated BAM files from scattered ApplyRecalibration runs
task GatherBamFiles {
    String? preCommand
    Array[File]+ input_bams
    String output_bam_path
    Int? compression_level
    String? picardJar

    Float? memory
    Float? memoryMultiplier

    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
    then "java -Xmx" + mem + "G -jar " + picardJar
    else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        ${preCommand}
        ${toolCommand} \
          GatherBamFiles \
          INPUT=${sep=' INPUT=' input_bams} \
          OUTPUT=${output_bam_path} \
          CREATE_INDEX=true \
          CREATE_MD5_FILE=true
    }

    output {
        File output_bam = "${output_bam_path}"
        File output_bam_index = sub(output_bam_path, ".bam$", ".bai")
        File output_bam_md5 = "${output_bam_path}.md5"
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

# Mark duplicate reads to avoid counting non-independent observations
task MarkDuplicates {
    String? preCommand
    Array[File] input_bams
    String output_bam_path
    String metrics_path
    Int? compression_level
    String? picardJar

    Float? memory
    Float? memoryMultiplier

    # The program default for READ_NAME_REGEX is appropriate in nearly every case.
    # Sometimes we wish to supply "null" in order to turn off optical duplicate detection
    # This can be desirable if you don't mind the estimated library size being wrong and optical duplicate detection is taking >7 days and failing
    String? read_name_regex

    # Task is assuming query-sorted input so that the Secondary and Supplementary reads get marked correctly
    # This works because the output of BWA is query-grouped and therefore, so is the output of MergeBamAlignment.
    # While query-grouped isn't actually query-sorted, it's good enough for MarkDuplicates with ASSUME_SORT_ORDER="queryname"
    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
    then "java -Xmx" + mem + "G -jar " + picardJar
    else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        ${preCommand}
        mkdir -p $(dirname ${output_bam_path})
        ${toolCommand} \
          MarkDuplicates \
          INPUT=${sep=' INPUT=' input_bams} \
          OUTPUT=${output_bam_path} \
          METRICS_FILE=${metrics_path} \
          VALIDATION_STRINGENCY=SILENT \
          ${"READ_NAME_REGEX=" + read_name_regex} \
          OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
          CLEAR_DT="false" \
          CREATE_INDEX=true \
          ADD_PG_TAG_TO_READS=false
    }

    output {
        File output_bam = output_bam_path
        File output_bam_index = sub(output_bam_path, ".bam$", ".bai")
        File duplicate_metrics = metrics_path
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

# Combine multiple VCFs or GVCFs from scattered HaplotypeCaller runs
task MergeVCFs {
    String? preCommand
    Array[File] inputVCFs
    Array[File] inputVCFsIndexes
    String outputVCFpath
    Int? compressionLevel
    String? picardJar

    Float? memory
    Float? memoryMultiplier

    # Using MergeVcfs instead of GatherVcfs so we can create indices
    # See https://github.com/broadinstitute/picard/issues/789 for relevant GatherVcfs ticket
    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
    then "java -Xmx" + mem + "G -jar " + picardJar
    else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        ${preCommand}
        ${toolCommand} \
          MergeVcfs \
          INPUT=${sep=' INPUT=' inputVCFs} \
          OUTPUT=${outputVCFpath}
    }

    output {
        File outputVCF = outputVCFpath
        File outputVCFindex = outputVCFpath + ".tbi"
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

task SamToFastq {
    String? preCommand
    File inputBam
    String outputRead1
    String? outputRead2
    String? outputUnpaired
    String? picardJar
    Float? memory
    Float? memoryMultiplier
    Int mem = ceil(select_first([memory, 16.0])) # High memory default to avoid crashes.

    String toolCommand = if defined(picardJar)
    then "java -Xmx" + mem + "G -jar " + picardJar
    else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        ${preCommand}
        ${toolCommand} \
        SamToFastq \
        I=${inputBam} \
        ${"FASTQ=" + outputRead1} \
        ${"SECOND_END_FASTQ=" + outputRead2} \
        ${"UNPAIRED_FASTQ=" + outputUnpaired}
    }

    output {
        File read1 = outputRead1
        File? read2 = outputRead2
        File? unpairedRead = outputUnpaired
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}

task ScatterIntervalList {
    String? preCommand
    File interval_list
    Int scatter_count
    String? picardJar

    Float? memory
    Float? memoryMultiplier

    Int mem = ceil(select_first([memory, 4.0]))

    String toolCommand = if defined(picardJar)
    then "java -Xmx" + mem + "G -jar " + picardJar
    else "picard -Xmx" + mem + "G"

    command {
        set -e -o pipefail
        ${preCommand}
        mkdir scatter_list
        ${toolCommand} \
          IntervalListTools \
          SCATTER_COUNT=${scatter_count} \
          SUBDIVISION_MODE=BALANCING_WITHOUT_INTERVAL_SUBDIVISION_WITH_OVERFLOW \
          UNIQUE=true \
          SORT=true \
          INPUT=${interval_list} \
          OUTPUT=scatter_list
    }

    output {
        Array[File] out = glob("scatter_list/*/*.interval_list")
        Int interval_count = read_int(stdout())
    }

    runtime {
        memory: ceil(mem * select_first([memoryMultiplier, 3.0]))
    }
}