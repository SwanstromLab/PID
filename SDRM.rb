$sdrm_version_number = "0.3.0"
require_relative "viral_seq"

# Version 0.3.0-09MAY2019 by Shuntai Zhou
# SDRM analysis for PR, RT and IN regions.
# Calculate Pi for recency, require R (3.5.0 and above). List of R packages required: phangorn, ape, ggplot2, scales, ggforce, cowplot, magrittr, gridExtra

# gem install prawn
# gem install prawn-table
# gem install csv
# gem install combine_pdf
require 'prawn'
require 'prawn/table'
require 'csv'
require 'combine_pdf'

#require MUSCLE, define path_to_muscle
$path_to_muscle = "muscle"

R_SCRIPT = 'setwd("PATH_TO_FASTA")
library(phangorn)
library(ape)
library(ggplot2)
library(scales)
library(ggforce)
library(cowplot)
library(magrittr)
library(gridExtra)
pdf("OUTPUT_PDF", onefile=T, width=11, height=8.5)
fileNames <- list.files()
for (fileName in fileNames) {
dna <- read.dna(fileName, format="fasta")
class(dna)
D<- dist.dna(dna, model="raw")
pi <- mean(D)
dist20 <- quantile(D, prob=c(0.20))
alldist <- data.frame(File=fileName, pi, dist20)
write.table(alldist,"OUTPUT_CSV",append=TRUE, sep = ",", row.names = FALSE, col.names=FALSE)
D2 <- dist.dna(dna, model="TN93")*100
def.par <- par(no.readonly = TRUE)
par(mfrow=c(1,2))
hist<-hist(D, main=fileName, xlab="% Pairwise Distance", ylab="Frequency", col="gray")
abline(v=dist20, col="royalblue",lwd=2)
abline(v=pi, col="red", lwd=2)
legend(x="topright", c("dist20", "pi"), col = c("royalblue", "red"), lwd = c(2,2), cex=0.5)
njtree<-NJ(D2)
njtreeplot <- plot(njtree, show.tip.label=F, "unrooted", main=fileName)
add.scale.bar(cex=0.7, font=2, col="red")
}
dev.off()'

indir = ARGV[0]
libs = Dir[indir + "/*"]
outdir = indir + "_SDRM"
Dir.mkdir(outdir) unless File.directory?(outdir)

libs.each do |lib|
  r_script = R_SCRIPT.dup
  next unless File.directory?(lib)
  lib_name = File.basename(lib)
  out_lib_dir = outdir + "/" + lib_name
  Dir.mkdir(out_lib_dir) unless File.directory?(out_lib_dir)
  sub_seq_files = Dir[lib + "/*"]
  seq_summary_file = out_lib_dir + "/" + lib_name + "_summary.csv"
  seq_summary_out = File.open(seq_summary_file, "w")
  seq_summary_out.puts "Region,TCS,TCS with A3G/F hypermutation,TCS with stop codon,TCS w/o hypermutation and stop codon, Poisson cutoff for minority mutation (>=),Pi,Dist20"

  point_mutation_file = out_lib_dir + "/" + lib_name + "_substitution.csv"
  point_mutation_out = File.open(point_mutation_file, "w")
  point_mutation_out.puts "region,TCS,AA position,wild type,mutation,number,percentage,95% CI low, 95% CI high, notes"

  linkage_file = out_lib_dir + "/" + lib_name + "_linkage.csv"
  linkage_out = File.open(linkage_file, "w")
  linkage_out.puts "region,TCS,mutation linkage,number,percentage,95% CI low, 95% CI high, notes"

  aa_report_file = out_lib_dir + "/" + lib_name + "_aa.csv"
  aa_report_out = File.open(aa_report_file, "w")
  aa_report_out.puts "region,ref.aa.positions,TCS.number," + $amino_acid_list.join(",")

  summary_line_file = out_lib_dir + "/" + lib_name + "_lines.csv"
  line_out = File.open(summary_line_file,"w")

  filtered_seq_dir = out_lib_dir + "/" + lib_name + "_filtered_seq"
  Dir.mkdir(filtered_seq_dir) unless File.directory?(filtered_seq_dir)

  aln_seq_dir = out_lib_dir + "/" + lib_name + "_aln_seq"
  Dir.mkdir(aln_seq_dir) unless File.directory?(aln_seq_dir)

  point_mutation_list = []
  linkage_list = []
  aa_report_list = []
  summary_hash = {}

  sub_seq_files.each do |sub_seq|
    seq_basename = File.basename(sub_seq)
    seqs = fasta_to_hash(sub_seq)
    next if seqs.size < 3
    if seq_basename =~ /V1V3/i
      summary_hash["V1V3"] = "#{seqs.size.to_s},NA,NA,NA,NA"
      print `cp #{sub_seq} #{filtered_seq_dir}`
    elsif seq_basename =~ /PR/i
      hypermut_seq = a3g_hypermut_seq_hash(seqs)[0]
      stop_codon_seq = stop_codon_seq_hash(seqs, 0)
      filtered_seq = seqs.difference(hypermut_seq).difference(stop_codon_seq)
      p_cutoff = poisson_minority_cutoff(filtered_seq.values, 0.0001, 20)
      summary_hash["PR"] = "#{seqs.size.to_s},#{hypermut_seq.size.to_s},#{stop_codon_seq.size.to_s},#{filtered_seq.size.to_s},#{p_cutoff.to_s}"
      next if filtered_seq.size < 3
      filtered_out = File.open((filtered_seq_dir + "/" + seq_basename), "w")
      filtered_seq.each {|k,v| filtered_out.puts k; filtered_out.puts v}
      sdrm = sdrm_pr_bulk(filtered_seq, p_cutoff, out_lib_dir)
      point_mutation_list += sdrm[0]
      linkage_list += sdrm[1]
      aa_report_list += sdrm[2]
      filtered_out.close
    elsif seq_basename =~/IN/i
      hypermut_seq = a3g_hypermut_seq_hash(seqs)[0]
      stop_codon_seq = stop_codon_seq_hash(seqs, 2)
      filtered_seq = seqs.difference(hypermut_seq).difference(stop_codon_seq)
      p_cutoff = poisson_minority_cutoff(filtered_seq.values, 0.0001, 20)
      summary_hash["IN"] = "#{seqs.size.to_s},#{hypermut_seq.size.to_s},#{stop_codon_seq.size.to_s},#{filtered_seq.size.to_s},#{p_cutoff.to_s}"
      next if filtered_seq.size < 3
      filtered_out = File.open((filtered_seq_dir + "/" + seq_basename), "w")
      filtered_seq.each {|k,v| filtered_out.puts k; filtered_out.puts v}
      sdrm = sdrm_in_bulk(filtered_seq, p_cutoff, out_lib_dir)
      point_mutation_list += sdrm[0]
      linkage_list += sdrm[1]
      aa_report_list += sdrm[2]
      filtered_out.close
    elsif seq_basename =~/RT/i
      rt_seq1 = {}
      rt_seq2 = {}
      seqs.each do |k,v|
        rt_seq1[k] = v[0,267]
        rt_seq2[k] = v[267..-1]
      end
      hypermut_seq_rt1 = a3g_hypermut_seq_hash(rt_seq1)[0]
      hypermut_seq_rt2 = a3g_hypermut_seq_hash(rt_seq2)[0]
      stop_codon_seq_rt1 = stop_codon_seq_hash(rt_seq1, 1)
      stop_codon_seq_rt2 = stop_codon_seq_hash(rt_seq2, 2)
      hypermut_seq_keys = (hypermut_seq_rt1.keys | hypermut_seq_rt2.keys)
      stop_codon_seq_keys = (stop_codon_seq_rt1.keys | stop_codon_seq_rt2.keys)
      reject_keys = (hypermut_seq_keys | stop_codon_seq_keys)
      filtered_seq = seqs.reject {|k,v| reject_keys.include?(k) }
      p_cutoff = poisson_minority_cutoff(filtered_seq.values, 0.0001, 20)
      summary_hash["RT"] = "#{seqs.size.to_s},#{hypermut_seq_keys.size.to_s},#{stop_codon_seq_keys.size.to_s},#{filtered_seq.size.to_s},#{p_cutoff.to_s}"
      next if filtered_seq.size < 3
      filtered_out = File.open((filtered_seq_dir + "/" + seq_basename), "w")
      filtered_seq.each {|k,v| filtered_out.puts k; filtered_out.puts v}
      sdrm = sdrm_rt_bulk(filtered_seq, p_cutoff, out_lib_dir)
      point_mutation_list += sdrm[0]
      linkage_list += sdrm[1]
      aa_report_list += sdrm[2]
      filtered_out.close
    end
  end

  point_mutation_list.each do |record|
    point_mutation_out.puts record.join(",")
  end
  linkage_list.each do |record|
    linkage_out.puts record.join(",")
  end
  aa_report_list.each do |record|
    aa_report_out.puts record.join(",")
  end

  filtered_seq_files = Dir[filtered_seq_dir + "/*"]

  out_r_csv = out_lib_dir + "/" + lib_name + "_pi.csv"
  out_r_pdf = out_lib_dir + "/" + lib_name + "_pi.pdf"

  if filtered_seq_files.size > 0

    temp_sampled_seq_dir = out_lib_dir + "/" + lib_name + "_temp_seq"
    Dir.mkdir(temp_sampled_seq_dir) unless File.directory?(temp_sampled_seq_dir)

    filtered_seq_files.each do |seq_file|
      bn = File.basename(seq_file)
      temp_file = temp_sampled_seq_dir + "/" + bn
      filtered_seq1 = fasta_to_hash(seq_file)
      next if filtered_seq1.size < 3
      temp_out = File.open(temp_file,"w")
      filtered_seq1.keys.sample(1000).each do |k|
        temp_out.puts k + "\n" + filtered_seq1[k]
      end
      temp_out.close
    end

    temp_seq_files = Dir[temp_sampled_seq_dir + "/*"]
    temp_seq_files.each do |seq_file|
      print `#{$path_to_muscle} -in #{seq_file} -out #{aln_seq_dir + "/" + File.basename(seq_file)} -maxiters 2 -quiet`
    end

    r_script.gsub!(/PATH_TO_FASTA/,aln_seq_dir)
    File.unlink(out_r_csv) if File.exist?(out_r_csv)
    File.unlink(out_r_pdf) if File.exist?(out_r_pdf)
    r_script.gsub!(/OUTPUT_CSV/,out_r_csv)
    r_script.gsub!(/OUTPUT_PDF/,out_r_pdf)
    r_script_file = out_lib_dir + "/pi.R"
    File.open(r_script_file,"w") {|line| line.puts r_script}
    print `Rscript #{r_script_file} 1> /dev/null 2> /dev/null`
    if File.exist?(out_r_csv)
      pi_csv = File.readlines(out_r_csv)
      pi_csv.each do |line|
        line.chomp!
        data = line.split(",")
        tag = data[0].split("_")[-1].gsub(/\W/,"")
        summary_hash[tag] += "," + data[1].to_f.round(4).to_s + "," + data[2].to_f.round(4).to_s
      end
      ["PR", "RT", "IN", "V1V3"].each do |regions|
        next unless summary_hash[regions]
        seq_summary_out.puts regions + "," + summary_hash[regions]
      end
      File.unlink(out_r_csv)
    end
    File.unlink(r_script_file)
    print `rm -rf #{temp_sampled_seq_dir}`
    print `rm -rf #{filtered_seq_dir}`
  end

  seq_summary_out.close
  point_mutation_out.close
  linkage_out.close
  aa_report_out.close

  summary_lines = File.readlines(seq_summary_file)

  summary_lines.shift
  tcs_PR = 0
  tcs_RT = 0
  tcs_IN = 0
  tcs_V1V3 = 0
  pi_RT = 0.0
  pi_V1V3 = 0.0
  dist20_RT = 0.0
  dist20_V1V3 = 0.0
  recency = ""

  summary_lines.each do |line|
      data = line.chomp.split(",")
      if data[0] == "PR"
          tcs_PR = data[4].to_i
      elsif data[0] == "RT"
          tcs_RT = data[4].to_i
          pi_RT = data[6].to_f
          dist20_RT = data[7].to_f
      elsif data[0] == "IN"
          tcs_IN = data[4].to_i
      elsif data[0] == "V1V3"
          tcs_V1V3 = data[1].to_i
          pi_V1V3 = data[6].to_f
          dist20_V1V3 = data[7].to_f
      end
  end
  if tcs_RT >= 3 and tcs_V1V3 >= 3
    if (pi_RT + pi_V1V3) < 0.0103
        recency = "recent"
    elsif (pi_RT + pi_V1V3) >= 0.0103 and (dist20_RT + dist20_V1V3) >= 0.006
        recency = "chronic"
    else
        recency = "possible dual"
    end
  elsif tcs_RT >= 3 and tcs_V1V3 < 3
    if pi_RT < 0.0021
      recency = "RT only recent"
    elsif pi_RT >= 0.0021 and dist20_RT >= 0.001
      recency = "RT only chronic"
    else
      recency = "RT only possible dual"
    end
  else
    recency = "? (RT missing)"
  end

  sdrm_lines = File.readlines(point_mutation_file)
  sdrm_lines.shift
  sdrm_PR = ""
  sdrm_RT = ""
  sdrm_IN = ""
  sdrm_lines.each do |line|
      data = line.chomp.split(",")
      next if data[-1] == "*"
      if data[0] == "PR"
          sdrm_PR += data[3] + data[2] + data[4] + ":" + (data[6].to_f * 100).round(2).to_s + "(" + (data[7].to_f * 100).round(2).to_s + "-" + (data[8].to_f * 100).round(2).to_s + "); "
      elsif data[0] =~ /NRTI/
          sdrm_RT += data[3] + data[2] + data[4] + ":" + (data[6].to_f * 100).round(2).to_s + "(" + (data[7].to_f * 100).round(2).to_s + "-" + (data[8].to_f * 100).round(2).to_s + "); "
      elsif data[0] == "IN"
          sdrm_IN += data[3] + data[2] + data[4] + ":" + (data[6].to_f * 100).round(2).to_s + "(" + (data[7].to_f * 100).round(2).to_s + "-" + (data[8].to_f * 100).round(2).to_s + "); "
      end
  end
  line_out.print [tcs_PR.to_s,tcs_RT.to_s,tcs_IN.to_s,tcs_V1V3.to_s,pi_RT.to_s,pi_V1V3.to_s,dist20_RT.to_s,dist20_V1V3.to_s,recency,sdrm_PR,sdrm_RT,sdrm_IN].join(",") + "\n"
  line_out.close

  csvs = [
    {
      name: "summary",
      title: "Summary",
      file: seq_summary_file,
      newPDF: "",
      table_width: [65,55,110,110,110,110,60,60],
      extra_text: ""
    },
    {
      name: "substitution",
      title: "Surveillance Drug Resistance Mutations",
      file: point_mutation_file,
      newPDF: "",
      table_width: [65,55,85,80,60,65,85,85,85,45],
      extra_text: "* Mutation below Poisson cut-off for minority mutations"
    },
    {
      name: "linkage",
      title: "Mutation Linkage",
      file: linkage_file,
      newPDF: "",
      table_width: [55,50,250,60,80,80,80,45],
      extra_text: "* Mutation below Poisson cut-off for minority mutations"
    }
  ]

  csvs.each do |csv|
    file_name = out_lib_dir + "/" + csv[:name] + ".pdf"
    next unless File.exist? csv[:file]
    Prawn::Document.generate(file_name, :page_layout => :landscape) do |pdf|
      pdf.text((File.basename(lib, ".*") + ': ' + csv[:title]),
      :size => 20,
      :align => :center,
      :style => :bold)
      pdf.move_down 20
      table_data = CSV.open(csv[:file]).to_a
      header = table_data.first
      pdf.table(table_data,
        :header => header,
        :position => :center,
        :column_widths => csv[:table_width],
        :row_colors => ["B6B6B6", "FFFFFF"],
        :cell_style => {:align => :center, :size => 10}) do |table|
        table.row(0).style :font_style => :bold, :size => 12 #, :background_color => 'ff00ff'
      end
      pdf.move_down 5
      pdf.text(csv[:extra_text], :size => 8, :align => :justify,)
    end
    csv[:newPDF] = file_name
  end

  pdf = CombinePDF.new
  csvs.each do |csv|
    pdf << CombinePDF.load(csv[:newPDF]) if File.exist?(csv[:newPDF])
  end
  pdf << CombinePDF.load(out_r_pdf) if File.exist?(out_r_pdf)

  pdf.number_pages location: [:bottom_right],
  number_format: "Swanstrom\'s lab HIV SDRM Pipeline, version #{$sdrm_version_number} by S.Z. and M.U.C.   Page %s",
  font_size: 6,
  opacity: 0.5

  pdf.save out_lib_dir + "/" + lib_name + ".pdf"

  csvs.each do |csv|
    File.unlink csv[:newPDF]
  end
end

`touch #{outdir}/.done`
