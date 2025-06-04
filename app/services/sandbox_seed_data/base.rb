module SandboxSeedData
  class Base
  protected

    def log_plant_info(name)
      logger.info("\r\n🪴  Planting #{name}...\r\n")
    end

    def log_seed_info(message, indent: 2, colour: nil, blank_lines_before: 0)
      blank_lines_before.times { logger.info("🌱") }

      if colour
        logger.info("🌱 " + (" " * indent) + Colourize.text(message, colour))
      else
        logger.info("🌱" + (" " * indent) + message)
      end
    end

    def plantable?
      Rails.env.sandbox? || Rails.env.development?
    end

  private

    def logger
      @logger ||= Logger.new($stdout).tap do |stdout_logger|
        stdout_logger.level = Logger::INFO
        stdout_logger.formatter = Rails.logger.formatter
      end
    end
  end
end
