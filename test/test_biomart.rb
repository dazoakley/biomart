require 'test_helper'

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
  
  context "A Biomart::Dataset instance" do
    setup do
      @htgt_targ = @htgt.datasets["htgt_targ"]
      @htgt_trap = @htgt.datasets["htgt_trap"]
      @kermits   = @htgt.datasets["kermits"]
      @ensembl   = @htgt.datasets["mmusculus_gene_ensembl"]
      @emma      = Biomart::Dataset.new( "http://www.emmanet.org/biomart", { :name => "strains" } )
      @dcc       = Biomart::Dataset.new( "http://www.i-dcc.org/biomart", { :name => "dcc" } )
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
    
    should "perform count queries" do
      htgt_count = @htgt_targ.count()
      assert( htgt_count.is_a?( Integer ), "Biomart::Dataset.count is not returning integers." )
      assert( htgt_count > 0, "Biomart::Dataset.count is returning zero - this is wrong!" )

      htgt_count_single_filter = @htgt_targ.count( :filters => { "is_eucomm" => "1" } )
      assert( htgt_count_single_filter.is_a?( Integer ), "Biomart::Dataset.count (with single filter) is not returning integers." )
      assert( htgt_count_single_filter > 0, "Biomart::Dataset.count (with single filter) is returning zero - this is wrong!" )

      htgt_count_single_filter_group_value = @htgt_targ.count( :filters => { "marker_symbol" => ["Cbx1","Cbx7","Art4"] } )
      assert( htgt_count_single_filter_group_value.is_a?( Integer ), "Biomart::Dataset.count (with single filter, group value) is not returning integers." )
      assert( htgt_count_single_filter_group_value > 0, "Biomart::Dataset.count (with single filter, group value) is returning zero - this is wrong!" )
    end
    
    should "perform search queries" do
      search = @htgt_trap.search()
      assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options) is not returning a hash." )
      assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options) is not returning an array." )

      search1 = @htgt_targ.search( :filters => { "marker_symbol" => "Cbx1" }, :process_results => true )
      assert( search1.is_a?( Array ), "Biomart::Dataset.search (filters defined with processing) is not returning an array." )
      assert( search1.first.is_a?( Hash ), "Biomart::Dataset.search (filters defined with processing) is not returning an array of hashes." )
      assert( search1.first["marker_symbol"] == "Cbx1", "Biomart::Dataset.search (filters defined with processing) is not returning the correct info." )

      search2 = @htgt_targ.search( :filters => { "marker_symbol" => "Cbx1" }, :attributes => ["marker_symbol","ensembl_gene_id"], :process_results => true )
      assert( search2.is_a?( Array ), "Biomart::Dataset.search (filters and attributes defined with processing) is not returning an array." )
      assert( search2.first.is_a?( Hash ), "Biomart::Dataset.search (filters and attributes defined with processing) is not returning an array of hashes." )
      assert( search2.first["marker_symbol"] == "Cbx1", "Biomart::Dataset.search (filters and attributes defined with processing) is not returning the correct info." )
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
      assert( search.is_a?( Hash ), "Biomart::Dataset.search (no options) is not returning a hash. (HTGT Query)" )
      assert( search[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options) is not returning an array. (HTGT Query)" )
      assert( search[:data].size > 20, "Biomart::Dataset.search[:data] for poorly formatted TSV data is empty. (HTGT Query)" )
      
      search2 = @emma.search(
        :filters    => { "emma_id" => ["EM:03629"] },
        :attributes => [
          "emma_id", "international_strain_name", "synonym", "maintained_background", 
          "mutation_main_type", "mutation_sub_type", "alls_form", "genetic_description", 
          "phenotype_description", "reference", "pubmed_id", "availability", "owner"
        ]
      )
      
      assert( search2.is_a?( Hash ), "Biomart::Dataset.search (no options) is not returning a hash. (EMMA Query)" )
      assert( search2[:data].is_a?( Array ), "Biomart::Dataset.search[:data] (no options) is not returning an array. (EMMA Query)" )
      assert( search2[:data].size > 0, "Biomart::Dataset.search[:data] for poorly formatted TSV data is empty. (EMMA Query)" )
    end
    
    should "perform federated search queries" do
      search_opts = {
        :filters => {
          "status" => [
            "Mice - Genotype confirmed", "Mice - Germline transmission",
            "Mice - Microinjection in progress", "ES Cells - Targeting Confirmed"
          ]
        },
        :attributes => [ "marker_symbol", "mgi_accession_id", "status" ],
        :federate => [
          {
            :dataset => @ensembl,
            :filters => { "chromosome_name" => "1", "start" => "1", "end" => "10000000" },
            :attributes => []
          }
        ]
      }
      
      results = @htgt_targ.search( search_opts )
      
      assert( results.is_a?(Hash), "Biomart::Dataset.search is not returning a hash. [federated search]" )
      assert( results[:data].is_a?(Array), "Biomart::Dataset.search[:data] is not returning an array. [federated search]" )
      assert( results[:data][0].size === 3, "Biomart::Dataset.search[:data] is not returning 3 attributes. [federated search]" )
      assert( results[:headers].size === 3, "Biomart::Dataset.search[:headers] is not returning 3 elements. [federated search]" )

      assert_raise( Biomart::ArgumentError ) { @htgt_targ.count( search_opts ) }
      
      assert_raise Biomart::ArgumentError do
        search_opts[:federate] = [
          {
            :dataset => "mmusculus_gene_ensembl",
            :filters => { "chromosome_name" => "1", "start" => "1", "end" => "10000000" },
            :attributes => []
          }
        ]
        results = @htgt_targ.search( search_opts )
      end
      
      assert_raise Biomart::ArgumentError do
        search_opts[:federate] = {
          :dataset => "mmusculus_gene_ensembl",
          :filters => { "chromosome_name" => "1", "start" => "1", "end" => "10000000" },
          :attributes => []
        }
        results = @htgt_targ.search( search_opts )
      end
      
      assert_raise Biomart::ArgumentError do
        search_opts[:federate] = [
          {
            :dataset => @ensembl,
            :filters => { "chromosome_name" => "1", "start" => "1", "end" => "10000000" },
            :attributes => []
          },
          {
            :dataset => @ensembl,
            :filters => { "chromosome_name" => "1", "start" => "1", "end" => "10000000" },
            :attributes => []
          }
        ]
        results = @htgt_targ.search( search_opts )
      end
    end
    
    should "perform search queries with the :required_attributes option" do
      search_opts = {
        :filters => {
          "chromosome_name" => "1",
          "start"           => "1",
          "end"             => "10000000"
        },
        :attributes => [
          "ensembl_gene_id", "ensembl_transcript_id",
          "mouse_paralog_ensembl_gene", "mouse_paralog_chromosome"
        ],
        :required_attributes => ["mouse_paralog_ensembl_gene"]
      }
      
      results = @ensembl.search( search_opts )
      
      assert( results.is_a?(Hash), "Biomart::Dataset.search is not returning a hash. [required_attributes search]" )
      assert( results[:data].is_a?(Array), "Biomart::Dataset.search[:data] is not returning an array. [required_attributes search]" )
      results[:data].each do |data_row|
        assert_equal( false, data_row[2].nil?, "The required_attributes search has not filtered out nil values." )
      end
      
      assert_raise( Biomart::ArgumentError ) { @ensembl.count( search_opts ) }
      assert_raise Biomart::ArgumentError do
        search_opts[:required_attributes] = "mouse_paralog_ensembl_gene"
        @ensembl.search( search_opts )
      end
      
      results = @dcc.search(
        :filters => {
          "marker_symbol" => [
            "Lrrc32", "Dub3", "Hs3st4", "Hs3st4", "Hs3st4", "Hs3st4",
            "Hs3st4", "Hs3st4", "Hs3st4", "Tcrg-C", "Gm5195", "Gm5198",
            "Gm5199", "Gm5625", "Rpl13-ps2", "Gm5664", "Gm5928", "Gm6035",
            "Gm6049"
          ]
        },
        :required_attributes => ["ikmc_project","ikmc_project_id"],
        :process_results => true
      )
      
      results.each do |data_row|
        assert_equal( false, data_row["ikmc_project"].nil?, "The required_attributes search has not filtered out nil values." )
        assert_equal( false, data_row["ikmc_project_id"].nil?, "The required_attributes search has not filtered out nil values." )
      end
    end
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
  
  context "A Biomart::Filter instance" do
    setup do
      @kermits = @htgt.datasets["kermits"]
    end
    
    should "have basic metadata" do
      true_false  = [true,false]
      ens_gene_id = @kermits.filters["ensembl_gene_id"]
      
      assert( !ens_gene_id.name.nil?, "Biomart::Filter.name is nil." )
      assert( !ens_gene_id.display_name.nil?, "Biomart::Filter.display_name is nil." )
      
      assert( true_false.include?( ens_gene_id.hidden? ), "Biomart::Filter.hidden? is not returning true/false." )
      assert( true_false.include?( ens_gene_id.default? ), "Biomart::Filter.default? is not returning true/false." )
      assert( true_false.include?( ens_gene_id.multiple_values? ), "Biomart::Filter.multiple_values? is not returning true/false." )
    end
  end
  
  context "The Biomart module" do
    setup do
      @not_biomart  = Biomart::Server.new( "http://www.sanger.ac.uk" )
      @htgt_targ    = @htgt.datasets["htgt_targ"]
      @bad_dataset  = Biomart::Dataset.new( "http://www.sanger.ac.uk/htgt/biomart", { :name => "wibble" } )
      @good_biomart = Biomart::Server.new( "http://www.i-dcc.org/biomart" )
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
      assert_raise( Biomart::FilterError )    { @htgt_targ.count( :filters => { "wibbleblibbleblip" => "1" } ) }
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
