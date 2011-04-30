require 'test_helper'

class BiomartServerTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart_server')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  context "A Biomart::Server instance" do
    should "have databases" do
      assert( @htgt_alt.list_databases.is_a?( Array ), "Biomart::Server.list_databases is not returning an array." )
      assert( @htgt_alt.list_databases.include?( "htgt" ), "Biomart::Server datbase parsing is off - htgt is not in htgt!" )
      assert( @htgt.databases["htgt"].is_a?( Biomart::Database ), "Biomart::Server is not creating Biomart::Database objects." )
    end
    
    should "have datasets" do
      assert( @htgt_alt.list_datasets.is_a?( Array ), "Biomart::Server.list_datasets is not returning an array." )
      assert( @htgt_alt.list_datasets.include?( "htgt_targ" ), "Biomart::Server dataset parsing is off - htgt_targ is not in htgt!" )
      assert( @htgt.datasets["htgt_targ"].is_a?( Biomart::Dataset ), "Biomart::Server is not creating Biomart::Dataset objects." )
    end
  end
  
end