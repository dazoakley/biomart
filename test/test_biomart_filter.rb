require 'test_helper'

class BiomartFilterTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end

  def teardown
    VCR.eject_cassette
  end

  context "A Biomart::Filter instance" do
    setup do
      @kermits = @htgt.datasets["kermits"]
    end

    should "have basic metadata" do
      true_false  = [true,false]
      ens_gene_id = @kermits.filters["ensembl_gene_id"]

      assert( !ens_gene_id.name.nil?, "Biomart::Filter.name is nil." )
      assert( !ens_gene_id.display_name.nil?, "Biomart::Filter.display_name is nil." )
      assert( !ens_gene_id.type.nil?, "Biomart::Filter.type is nil." )

      assert( true_false.include?( ens_gene_id.hidden? ), "Biomart::Filter.hidden? is not returning true/false." )
      assert( true_false.include?( ens_gene_id.default? ), "Biomart::Filter.default? is not returning true/false." )
      assert( true_false.include?( ens_gene_id.multiple_values? ), "Biomart::Filter.multiple_values? is not returning true/false." )
    end
  end

end
