require 'test_helper'

class BiomartDatabaseTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart_database')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end

  def teardown
    VCR.eject_cassette
  end

  context "A Biomart::Database instance" do
    setup do
      @htgt_database = @htgt.databases["htgt"]
    end

    should "have basic metadata" do
      true_false  = [true,false]
      assert( @htgt_database.display_name, "Biomart::Database does not have a 'display name'." )
      assert( @htgt_database.name, "Biomart::Database does not have a 'name'." )
      assert( @htgt_database.visible != nil, "Biomart::Database does not have a 'visible' flag." )
      assert( true_false.include?( @htgt_database.visible? ), "Biomart::Database.visible? is not returning true/false." )
    end

    should "have datasets" do
      assert( @htgt_database.list_datasets.is_a?( Array ), "Biomart::Database.list_datasets is not returning an array." )
      assert( @htgt_database.list_datasets.include?( "htgt_targ" ), "Biomart::Database dataset parsing is off - htgt_targ is not in htgt!" )
      assert( @htgt_database.datasets["htgt_targ"].is_a?( Biomart::Dataset ), "Biomart::Database is not creating Biomart::Dataset objects." )
    end
  end

end
