version 1.0

# Copyright (c) 2017 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

task HTSeqCount {
    input {
        Array[File]+ inputBams
        File gtfFile
        String outputTable = "output.tsv"
        String format = "bam"
        String order = "pos"
        String stranded = "no"
        String? featureType
        String? idattr
        Array[String] additionalAttributes = []

        String memory = "40G"
        String dockerImage = "quay.io/biocontainers/htseq:0.11.2--py37h637b7d7_1"
    }

    command {
        set -e
        mkdir -p "$(dirname ~{outputTable})"
        htseq-count \
        -f ~{format} \
        -r ~{order} \
        -s ~{stranded} \
        ~{"--type " + featureType} \
        ~{"--idattr " + idattr} \
        ~{true="--additional-attr " false="" length(additionalAttributes) > 0 }~{sep=" --additional-attr " additionalAttributes} \
        ~{sep=" " inputBams} \
        ~{gtfFile} \
        > ~{outputTable}
    }

    output {
        File counts = outputTable
    }

    runtime {
        memory: memory
        docker: dockerImage
    }

    parameter_meta {
        inputBams: {
            description: "The input BAM files.",
            category: "required"
        }
        gtfFile: {
            description: "A GTF/GFF file containing the features of interest.",
            category: "required"
        }
        outputTable: {
            description: "The path to which the output table should be written.",
            category: "common"
        }
        format: {
            description: "Equivalent to the -f option of htseq-count.",
            category: "advanced"
        }
        order: {
            description: "Equivalent to the -r option of htseq-count.",
            category: "advanced"
        }
        stranded: {
            description: "Equivalent to the -s option of htseq-count.",
            category: "common"
        }
        featureType: {
            description: "Equivalent to the --type option of htseq-count.",
            category: "advanced"
        }
        idattr: {
            description: "Equivalent to the --idattr option of htseq-count.",
            category: "advanced"
        }
        additionalAttributes: {
            description: "Equivalent to the --additional-attr option of htseq-count.",
            category: "advanced"
        }
        memory: {
            description: "The amount of memory the job requires in GB.",
            category: "advanced"
        }
        dockerImage: {
            description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.",
            category: "advanced"
        }
    }
}
