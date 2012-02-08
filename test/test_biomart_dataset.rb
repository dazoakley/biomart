require 'test_helper'

class BiomartDatasetTest < Test::Unit::TestCase
  def setup
    VCR.insert_cassette('test_biomart')
    @htgt     = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
    @htgt_alt = Biomart::Server.new('http://www.sanger.ac.uk/htgt/biomart')
  end

  def teardown
    VCR.eject_cassette
  end

  context "A Biomart::Dataset instance" do
    setup do
      @htgt_targ   = @htgt.datasets["htgt_targ"]
      @htgt_trap   = @htgt.datasets["htgt_trap"]
      @kermits     = @htgt.datasets["kermits"]
      @ensembl     = @htgt.datasets["mmusculus_gene_ensembl"]
      @ensembl_var = Biomart::Dataset.new( "http://www.ensembl.org/biomart", { :name => "hsapiens_snp" } )
      @emma        = Biomart::Dataset.new( "http://www.emmanet.org/biomart", { :name => "strains" } )
      @dcc         = Biomart::Dataset.new( "http://www.knockoutmouse.org/biomart", { :name => "dcc" } )
      @mgi         = Biomart::Dataset.new( "http://biomart.informatics.jax.org/biomart", { :name => "markers" } )
    end

    should "have basic metadata" do
      assert( @htgt_targ.display_name, "Biomart::Dataset does not have a 'display name'." )
      assert( @htgt_targ.name, "Biomart::Dataset does not have a 'name'." )
      assert( @htgt_targ.visible != nil, "Biomart::Dataset does not have a 'visible' flag." )
    end

    should "have filters" do
      assert( @htgt_targ.list_filters.is_a?( Array ), "Biomart::Dataset.list_filters is not returning an array." )
      assert( @htgt_targ.list_filters.include?( "ensembl_gene_id" ), "Biomart::Dataset filter parsing is off - ensembl_gene_id is not in htgt_targ!" )
      assert( @mgi.list_filters.include?( "ancestor_term_1023_filter" ), "Biomart::Dataset filter parsing is off - ancestor_term_1023_filter is not in mgi markers!" )
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

    should "perform searches that involve boolean filters" do
      search_opts = {
        :filters         => { 'with_variation_annotation' => true, 'ensembl_gene' => 'ENSG00000244734' },
        :attributes      => [ 'refsnp_id','chr_name','chrom_start' ],
        :process_results => true,
        :timeout => 2000
      }

      true_results = {}
      assert_nothing_raised( Biomart::BiomartError ) { true_results = @ensembl_var.search( search_opts ) }
      assert( !true_results.empty?, "The search using a boolean filter is empty." )

      search_opts[:filters].merge!({ 'with_variation_annotation' => 'included' })
      true_results2 = {}
      assert_nothing_raised( Biomart::BiomartError ) { true_results2 = @ensembl_var.search( search_opts ) }
      assert( !true_results2.empty?, "The search using a boolean filter is empty." )
      assert_equal( true_results, true_results2, "Using 'included' for a boolean filter does not give the same result as 'true'." )

      search_opts[:filters].merge!({ 'with_variation_annotation' => 'only' })
      true_results3 = {}
      assert_nothing_raised( Biomart::BiomartError ) { true_results3 = @ensembl_var.search( search_opts ) }
      assert( !true_results3.empty?, "The search using a boolean filter is empty." )
      assert_equal( true_results, true_results3, "Using 'only' for a boolean filter does not give the same result as 'true'." )

      search_opts[:filters].merge!({ 'with_variation_annotation' => false })
      false_results = {}
      assert_nothing_raised( Biomart::BiomartError ) { false_results = @ensembl_var.search( search_opts ) }
      assert( !false_results.empty?, "The search using a boolean filter is empty." )

      search_opts[:filters].merge!({ 'with_variation_annotation' => 'excluded' })
      false_results2 = {}
      assert_nothing_raised( Biomart::BiomartError ) { false_results2 = @ensembl_var.search( search_opts ) }
      assert( !false_results2.empty?, "The search using a boolean filter is empty." )
      assert_equal( false_results, false_results2, "Using 'excluded' for a boolean filter does not give the same result as 'false'." )

      search_opts[:filters].merge!({ 'with_variation_annotation' => 'flibble' })
      assert_raise( Biomart::ArgumentError ) { @ensembl_var.search( search_opts ) }

      search_opts[:filters].merge!({ 'with_variation_annot' => true })
      assert_raise( Biomart::ArgumentError ) { @ensembl_var.search( search_opts ) }
    end
  end

end
