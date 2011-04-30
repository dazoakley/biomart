require 'test_helper'

class BiomartTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart_module')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end
  
  def teardown
    VCR.eject_cassette
  end
  
  context "The Biomart module" do
    setup do
      @not_biomart  = Biomart::Server.new( "http://www.sanger.ac.uk" )
      @htgt_targ    = @htgt.datasets["htgt_targ"]
      @bad_dataset  = Biomart::Dataset.new( "http://www.sanger.ac.uk/htgt/biomart", { :name => "wibble" } )
      @good_biomart = Biomart::Server.new( "http://www.knockoutmouse.org/biomart" )
    end
    
    should "allow you to ping a server" do
      assert( @good_biomart.alive?, "A good biomart does not respond 'true' to .alive?." )
      assert( @htgt_targ.alive?, "A good biomart datasetdoes not respond 'true' to .alive?." )
      assert_equal( false, @not_biomart.alive?, "A non-biomart server does not respond 'false' to .alive?." )
    end
    
    should "handle user/configuration errors (i.e. incorrect URLs etc)" do
      assert_raise( Biomart::HTTPError ) { @not_biomart.list_databases }
    end
    
    should "handle biomart server errors gracefully" do
      assert_raise( Biomart::ArgumentError )  { @htgt_targ.count( :filters => { "wibbleblibbleblip" => "1" } ) }
      assert_raise( Biomart::AttributeError ) { @htgt_targ.search( :attributes => ["wibbleblibbleblip"] ) }
      assert_raise( Biomart::DatasetError )   { @bad_dataset.count() }
      
      begin
        @bad_dataset.count()
      rescue Biomart::BiomartError => e
        general_error = e
      end
      
      assert( general_error.is_a?(Biomart::BiomartError), "Biomart.request is not handling general Biomart errors correctly." )
    end
  end
  
end
