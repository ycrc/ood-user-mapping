require 'optparse'
require 'cgi'

require 'ood_auth_map/version'
require 'ood_auth_map/helpers'
require 'ood_auth_map/admin'

# Class that describes very simple CLI interface
class OodAuthMap
  class << self
    # Options parsed from the command line
    # @return [Hash] options parsed by command line
    def options
      @options ||= {}
    end

    # Block of code called in body of options parser
    # @yield [parser] the option parser to the block
    # @return [void]
    def define_body(&block)
      @body_block = block
    end

    # Block of code called in footer of options parser
    # @yield [parser] the option parser to the block
    # @return [void]
    def define_footer(&block)
      @footer_block = block
    end

    # Block of code called when CLI is run after parsing options
    # @yield [authenticated_user] the url decoded authenticated user name
    # @return [void]
    def define_run(&block)
      @run_block = block
    end

    # Starts the CLI workflow
    # @return [void]
    def run
      ARGV << "--help" if ARGV.empty?
      parser.parse!(ARGV)
      raise ArgumentError, "missing authenticated user argument" if ARGV.empty?
   
      auth_user = CGI.unescape(ARGV.first)
      #default_mapfile = "/etc/ood/config/map_file"
      # If the default mapfile exists, scan it first. 
      # This is used by system admins to impersonate a user for troubleshooting
      if File.file?(ADMIN_MAPFILE)
        if sys_user =  Helpers.parse_mapfile(ADMIN_MAPFILE, auth_user)
          puts sys_user
          exit(true)
        end
      end

      @run_block.call(auth_user)
    rescue
      $stderr.puts "#{$!.to_s}"
      $stderr.puts "Run #{File.basename($0)} --help to see a full list of available options."
      exit(false)
    end
  end

  private
    # Option parser used in parsing CLI
    def self.parser
      OptionParser.new do |p|
        p.banner = "Usage: #{File.basename($0)} [options] <authenticated_user>"

        @body_block.call(p) if @body_block

        p.separator ""
        p.separator "Common options:"
        p.on("-h", "--help", "# Show this help message") do
          puts p
          exit
        end
        p.on("-v", "--version", "# Show version") do
          puts "ood_auth_map, version #{VERSION}"
          exit
        end

        @footer_block.call(p) if @footer_block
      end
    end
end
