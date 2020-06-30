# JBrowse

## Version

 | | |
---|---
__Program Version__|1.12.1
__Databiology Application Version__|2.3.1

## Deploying

If you want to deploy the latest version of this app, this is the pull you should do:

     docker pull hub.databiology.net/dbio/jbrowse:2.3.1

If you want to deploy a previous version, the pull should be:

     docker pull hub.databiology.net/dbio/jbrowse:{VERSION}

Just replace {VERSION} with the Version you're interested in. For full deployment instructions, please see [our in-depth guide on application deployment](https://docs.databiology.net/tiki-index.php?page=Operations%3ADeploying+an+Application).

## Application Changelog

 | | |
---|---
__Version__|__Release Notes__
2.3.1|Fix references and update documentation
2.3.0|Update base image v5.0.1, references and namespace migration
2.2.2|Add parameter to concatenate, sort and index VCF files. The VCF files are per individual and one file per chr.
2.2.1|Use Base image 4.2.3
2.2.0|Added MethylationPlugin and Soybean v2.0 reference.
2.1.1|Use CIAO5.
2.1.0|Use Base image 4.2.0, Add a 'Status bar' to wait until Jbrowse is Ready.
2.0.1|Initial port to CIAO

## Description

JBrowse is a fast, embeddable genome browser built completely with JavaScript and HTML5, with optional run-once data formatting tools written in Perl.

### Terminate the WorkUnit

To finish the WU correctly, go to the top menu and click on Terminate Workunit -> click Stop.

![Terminate JBrowser](https://appreadmesdatabiologynet.blob.core.windows.net/app-readme-resources/JBrowse/terminate_jbrowser.png)

## Supported architectures

* x86_64

## I/O

### Input files

* BAM and BAI files ({filename}.bam and {filename}.bai) or
* VCF and TBI compressed files ({filename}.vcf.gz and {filename}.vcf.gz.tbi)

#### Optional

* Methylation Tracks (For [Methylation Plugin](https://github.com/bhofmei/jbplugin-methylation) three files are required: *.cg, *.chg and *.chh)

### Output files

* None
* If __Concatenate, Sort and Index VCF files__ is Active, then outputs are VCF and TBI compressed files.

## Parameters

 | | | | |
---|---|---|---
__Name__|__Description__|__Values__|__Default__
Genome|Reference genome|Human genome GRCh37, Human genome GRCh38, Soybean|Human genome GRCh37
Concatenate, Sort and Index VCF files|If this is Active, the VCF files will be concatenated in a single VCF per individual, sorted by chromosomal order, and indexed. Result files will be *.sort.vcf.gz and *.sort.vcf.gz.tbi|Active/Inactive|Inactive

If __Concatenate, Sort and Index VCF files__ is Active, the input VCF files ({filename}.vcf.gz) must be associated with an Extract, Sample and Subject. Extract type contains all VCF files per individual, one file per Chr.

If __Concatenate, Sort and Index VCF files__ is Inactive, it is optional that input files (BAM or VCF files) are associated with an Extract, Sample and Subject.

## License

[GNU Lesser General Public License v2.1](https://github.com/GMOD/jbrowse/blob/master/LICENSE)

## External link

[Homepage](http://jbrowse.org/)

__Copyright ©2020. All Rights Reserved. Confidential Databiology Ltd.__
