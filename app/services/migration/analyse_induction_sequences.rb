module Migration
  # Main service for analysing induction sequences and providing reports
  #
  # This service orchestrates the analysis of participant induction records,
  # identifying timeline gaps, overlaps, and data quality issues during migration.
  #
  # @example With specific participants and options
  #   participants = ParticipantProfile.where(id: [1, 2, 3])
  #   results = Migration::AnalyseInductionSequences.call(
  #     participants,
  #     verbose: true,
  #     export: true
  #   )
  class AnalyseInductionSequences
    # Public API for running the analysis
    # @param participant_profiles [ActiveRecord::Relation, Array] Profiles to analyse
    def self.call(participant_profiles, verbose: false, export: false, filename: nil, batch_size: 1000)
      new(participant_profiles, batch_size:).call(
        verbose:,
        export:,
        filename:
      )
    end

    def initialize(participant_profiles, batch_size: 1000)
      @participant_profiles = participant_profiles
      @batch_size = batch_size
    end

    # Run the analysis with optional display and export
    def call(verbose: false, export: false, filename: nil)
      Rails.logger.info("AnalyseInductionSequences: Starting analysis")

      # Perform the core analysis
      results = analyser.analyse

      Rails.logger.info("AnalyseInductionSequences: Analysis completed. Found #{results.size} results")

      # Display results to console if requested
      display_results(results) if verbose

      # Export to CSV if requested
      export_results(results, filename) if export

      results
    end

    def export_to_csv(results: nil, filename: nil)
      results ||= analyser.analyse
      export_results(results, filename)
    end

  private

    def analyser
      @analyser ||= InductionSequenceAnalyser.new(@participant_profiles, batch_size: @batch_size)
    end

    def display_results(results)
      formatter = InductionSequenceFormatter.new(results)
      formatter.display_results
    end

    def export_results(results, filename)
      exporter = InductionSequenceExporter.new(results)
      file_path = exporter.export_to_csv(filename:)

      Rails.logger.info("AnalyseInductionSequences: Results exported to #{file_path}")
      file_path
    end
  end
end
