process MITOCONDRION_DOWNLOAD {
	
	tag "Downloading mito genomes."
	
	input:
	val(mito_genomes)

	output:
	path("mito_concatenated_output.fna.gz"), emit: mito_ref
	
	script:
	"""
	#genomes from db
	wget -O html.txt ${mito_genomes}
	grep -oP '(?<=href=\")[^\"]*\\.genomic\\.fna\\.gz' html.txt > mito_names.txt
	awk '{print "${params.mito_dw}" \$0}' mito_names.txt > mito_html.txt
	wget -r -np -nd  -i mito_html.txt -P downloaded_files && zcat downloaded_files/*.genomic.fna.gz | gzip > mito_concatenated_output.fna.gz
	"""
}
