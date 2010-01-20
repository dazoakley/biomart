require File.dirname(__FILE__) + '/test_helper.rb'

class BiomartTest < Test::Unit::TestCase
  def setup
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
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
  
  context "A Biomart::Database instance" do
    setup do
      @htgt_database = @htgt.databases["htgt"]
    end
    
    should "have basic metadata" do
      assert( @htgt_database.display_name, "Biomart::Database does not have a 'display name'." )
      assert( @htgt_database.name, "Biomart::Database does not have a 'name'." )
      assert( @htgt_database.visible != nil, "Biomart::Database does not have a 'visible' flag." )
    end
    
    should "have datasets" do
      assert( @htgt_database.list_datasets.is_a?( Array ), "Biomart::Database.list_datasets is not returning an array." )
      assert( @htgt_database.list_datasets.include?( "htgt_targ" ), "Biomart::Database dataset parsing is off - htgt_targ is not in htgt!" )
      assert( @htgt_database.datasets["htgt_targ"].is_a?( Biomart::Dataset ), "Biomart::Database is not creating Biomart::Dataset objects." )
    end
  end
  
  context "A Biomart::Dataset instance" do
    setup do
      @htgt_targ = @htgt.datasets["htgt_targ"]
      @htgt_trap = @htgt.datasets["htgt_trap"]
      @kermits   = @htgt.datasets["kermits"]
    end
    
    should "have basic metadata" do
      assert( @htgt_targ.display_name, "Biomart::Dataset does not have a 'display name'." )
      assert( @htgt_targ.name, "Biomart::Dataset does not have a 'name'." )
      assert( @htgt_targ.visible != nil, "Biomart::Dataset does not have a 'visible' flag." )
    end
    
    should "have filters" do
      assert( @htgt_targ.list_filters.is_a?( Array ), "Biomart::Dataset.list_filters is not returning an array." )
      assert( @htgt_targ.list_filters.include?( "ensembl_gene_id" ), "Biomart::Dataset filter parsing is off - ensembl_gene_id is not in htgt_targ!" )
      assert( @kermits.filters["ensembl_gene_id"].is_a?( Biomart::Filter ), "Biomart::Dataset is not creating Biomart::Filter objects." )
    end
    
    should "have attributes" do
      assert( @htgt_targ.list_attributes.is_a?( Array ), "Biomart::Dataset.list_attributes is not returning an array." )
      assert( @htgt_targ.list_attributes.include?( "ensembl_gene_id" ), "Biomart::Dataset attribute parsing is off - ensembl_gene_id is not in htgt_targ!" )
      assert( @kermits.attributes["ensembl_gene_id"].is_a?( Biomart::Attribute ), "Biomart::Dataset is not creating Biomart::Attribute objects." )
    end
    
    should "perform count/search queries" do
      perform_count_queries("net/http")
      perform_search_queries("net/http")
      
      #if CURB_AVAILABLE
      #  perform_count_queries("curb")
      #  perform_search_queries("curb")
      #  Biomart.use_net_http = true
      #  perform_count_queries("net/http")
      #  perform_search_queries("net/http")
      #else
      #  perform_count_queries("net/http")
      #  perform_search_queries("net/http")
      #end
    end
    
    should "perform search queries whilst altering the timeout property" do
      search = @htgt_trap.search( :timeout => 60 )
      assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options except per-request timeout) is not returning a hash." )
      assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options except per-request timeout) is not returning an array." )
      
      Biomart.timeout = 60
      search = @htgt_trap.search()
      assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options except global timeout) is not returning a hash." )
      assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options except global timeout) is not returning an array." )
    end
    
    should "handle search queries that will generate poorly formatted TSV data" do
      search = @htgt_targ.search(
        :filters => { "mgi_accession_id" => [ "MGI:1921569", "MGI:1913402", "MGI:1913300" ] },
        :attributes => [
          "is_eucomm", "is_komp_csd", "is_komp_regeneron", "is_norcomm",
          "is_mgp", "mgi_accession_id", "marker_symbol", "ensembl_gene_id",
          "status", "status_code", "status_type", "status_description",
          "status_sequence", "pipeline_stage", "ikmc_project_id", "bac",
          "design_id", "design_plate", "design_well", "intvec_plate",
          "intvec_well", "intvec_distribute", "targvec_plate", "targvec_well",
          "targvec_distribute", "backbone", "cassette", "allele_name",
          "escell_clone", "escell_distribute", "escell_line", "colonies_picked",
          "is_latest_for_gene", "targeted_trap"
        ]
      )
      assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options) is not returning a hash." )
      assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options) is not returning an array." )
      assert( search[:data].size > 0, "Biomart::Dataset.search[:data] for poorly formatted TSV data is empty." )
    end
    
  end
  
  def perform_count_queries( library )
    htgt_count = @htgt_targ.count()
    assert( htgt_count.is_a?( Integer ), "Biomart::Dataset.count is not returning integers. [using #{library} for HTTP communication]" )
    assert( htgt_count > 0, "Biomart::Dataset.count is returning zero - this is wrong! [using #{library} for HTTP communication]" )
    
    htgt_count_single_filter = @htgt_targ.count( :filters => { "is_eucomm" => "1" } )
    assert( htgt_count_single_filter.is_a?( Integer ), "Biomart::Dataset.count (with single filter) is not returning integers. [using #{library} for HTTP communication]" )
    assert( htgt_count_single_filter > 0, "Biomart::Dataset.count (with single filter) is returning zero - this is wrong! [using #{library} for HTTP communication]" )
    
    htgt_count_single_filter_group_value = @htgt_targ.count( :filters => { "marker_symbol" => ["Cbx1","Cbx7","Art4"] } )
    assert( htgt_count_single_filter_group_value.is_a?( Integer ), "Biomart::Dataset.count (with single filter, group value) is not returning integers. [using #{library} for HTTP communication]" )
    assert( htgt_count_single_filter_group_value > 0, "Biomart::Dataset.count (with single filter, group value) is returning zero - this is wrong! [using #{library} for HTTP communication]" )
  end
  
  def perform_search_queries( library )
    search = @htgt_trap.search()
    assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options) is not returning a hash. [using #{library} for HTTP communication]" )
    assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options) is not returning an array. [using #{library} for HTTP communication]" )
    
    search1 = @htgt_targ.search( :filters => { "marker_symbol" => "Cbx1" }, :process_results => true )
    assert( search1.is_a?( Array ), "Biomart::Dataset.search (filters defined with processing) is not returning an array. [using #{library} for HTTP communication]" )
    assert( search1.first.is_a?( Hash ), "Biomart::Dataset.search (filters defined with processing) is not returning an array of hashes. [using #{library} for HTTP communication]" )
    assert( search1.first["marker_symbol"] == "Cbx1", "Biomart::Dataset.search (filters defined with processing) is not returning the correct info. [using #{library} for HTTP communication]" )
    
    search2 = @htgt_targ.search( :filters => { "marker_symbol" => "Cbx1" }, :attributes => ["marker_symbol","ensembl_gene_id"], :process_results => true )
    assert( search2.is_a?( Array ), "Biomart::Dataset.search (filters and attributes defined with processing) is not returning an array. [using #{library} for HTTP communication]" )
    assert( search2.first.is_a?( Hash ), "Biomart::Dataset.search (filters and attributes defined with processing) is not returning an array of hashes. [using #{library} for HTTP communication]" )
    assert( search2.first["marker_symbol"] == "Cbx1", "Biomart::Dataset.search (filters and attributes defined with processing) is not returning the correct info. [using #{library} for HTTP communication]" )
  end
  
  context "The Biomart module" do
    setup do
      @not_biomart  = Biomart::Server.new( "http://www.sanger.ac.uk" )
      @htgt_targ    = @htgt.datasets["htgt_targ"]
      @bad_dataset  = Biomart::Dataset.new( "http://www.sanger.ac.uk/htgt/biomart", { :name => "wibble" } )
      @good_biomart = Biomart::Server.new( "http://www.sanger.ac.uk/htgt/biomart" )
    end
    
    should "allow you to ping a server" do
      assert( @good_biomart.alive?, "A good biomart does not respond 'true' to .alive?." )
      assert( @htgt_targ.alive?, "A good biomart datasetdoes not respond 'true' to .alive?." )
      assert_equal( false, @not_biomart.alive?, "A non-biomart server does not respond 'false' to .alive?." )
    end
    
    should "handle user/configuration errors (i.e. incorrect URLs etc)" do
      begin
        @not_biomart.list_databases
      rescue Biomart::HTTPError => e
        http_error = e
      end
      
      assert( http_error.is_a?( Biomart::HTTPError ), "Biomart.request is not processing HTTP errors correctly." )
    end
    
    should "handle biomart server errors gracefully" do
      begin
        @htgt_targ.count( :filters => { "wibbleblibbleblip" => "1" } )
      rescue Biomart::FilterError => e
        filter_error = e
      end
      
      begin
        @htgt_targ.search( :attributes => ["wibbleblibbleblip"] )
      rescue Biomart::AttributeError => e
        attribute_error = e
      end
      
      begin
        @bad_dataset.count()
      rescue Biomart::DatasetError => e
        dataset_error = e
      end
      
      begin
        @bad_dataset.count()
      rescue Biomart::BiomartError => e
        general_error = e
      end
      
      assert( filter_error.is_a?( Biomart::FilterError ), "Biomart.request is not handling Biomart filter errors correctly." )
      assert( attribute_error.is_a?( Biomart::AttributeError ), "Biomart.request is not handling Biomart attribute errors correctly." )
      assert( dataset_error.is_a?( Biomart::DatasetError ), "Biomart.request is not handling Biomart dataset errors correctly." )
      assert( general_error.is_a?( Biomart::BiomartError ), "Biomart.request is not handling general Biomart errors correctly." )
    end
  end
end
