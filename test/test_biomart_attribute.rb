require 'test_helper'

class BiomartAttributeTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart_attribute')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  context "A Biomart::Attribute instance" do
    setup do
      @kermits = @htgt.datasets["kermits"]
    end
    
    should "have basic metadata" do
      true_false  = [true,false]
      ens_gene_id = @kermits.attributes["ensembl_gene_id"]
      
      assert( !ens_gene_id.name.nil?, "Biomart::Attribute.name is nil." )
      assert( !ens_gene_id.display_name.nil?, "Biomart::Attribute.display_name is nil." )
      
      assert( true_false.include?( ens_gene_id.hidden? ), "Biomart::Attribute.hidden? is not returning true/false." )
      assert( true_false.include?( ens_gene_id.default? ), "Biomart::Attribute.default? is not returning true/false." )
    end
  end
  
end