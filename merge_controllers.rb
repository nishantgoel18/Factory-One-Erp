#!/usr/bin/env ruby
# frozen_string_literal: true

# Rails Controllers Merger Script
# Merges all controller files from app/controllers into a single combined file
# Handles namespaces and module structures properly

require 'fileutils'
require 'pathname'

class ControllerMerger
  def initialize(controllers_dir = 'app/controllers', output_file = 'combined_controllers.rb')
    @controllers_dir = controllers_dir
    @output_file = output_file
    @controller_files = []
    @all_requires = Set.new
    @namespaces = {}
  end

  def run
    puts "🚀 Rails Controllers Merger Script"
    puts "=" * 70
    puts

    unless Dir.exist?(@controllers_dir)
      puts "❌ Error: Directory '#{@controllers_dir}' not found!"
      return false
    end

    collect_controller_files
    
    if @controller_files.empty?
      puts "❌ No controller files found in '#{@controllers_dir}'"
      return false
    end

    puts "✨ Found #{@controller_files.length} controller file(s)"
    puts

    process_files
    write_combined_file

    puts "\n✅ Successfully created: #{@output_file}"
    puts "📦 Combined #{@controller_files.length} controller files"
    
    file_size = File.size(@output_file) / 1024.0
    puts "📄 Output file size: #{file_size.round(2)} KB"
    puts "\n💚 Merge completed successfully! Enjoy jaan! 💚"
    
    true
  rescue StandardError => e
    puts "\n❌ Error: #{e.message}"
    puts e.backtrace.first(5)
    false
  end

  private

  def collect_controller_files
    # Find all .rb files in controllers directory
    Dir.glob(File.join(@controllers_dir, '**', '*.rb')).each do |file|
      # Skip concerns and other non-controller files
      next if file.include?('/concerns/')
      next if File.basename(file).start_with?('.')
      
      @controller_files << file
    end

    @controller_files.sort!
  end

  def process_files
    @controller_files.each do |file_path|
      process_file(file_path)
    end
  end

  def process_file(file_path)
    content = File.read(file_path)
    relative_path = file_path.sub(@controllers_dir + '/', '')
    
    # Extract namespace from directory structure
    namespace = extract_namespace(relative_path)
    
    # Extract requires
    extract_requires(content)
    
    # Store controller content by namespace
    @namespaces[namespace] ||= []
    @namespaces[namespace] << {
      file: File.basename(file_path),
      path: relative_path,
      content: remove_requires(content).strip
    }
    
    puts "  ✓ Processed: #{relative_path}"
  rescue StandardError => e
    puts "  ⚠️  Warning: Could not process #{file_path}: #{e.message}"
  end

  def extract_namespace(relative_path)
    # Get directory path without filename
    dir_path = File.dirname(relative_path)
    
    # If it's in root controllers directory
    return 'root' if dir_path == '.'
    
    # Convert directory path to namespace
    # e.g., "admin/users" -> "Admin"
    #       "api/v1/posts" -> "Api::V1"
    dir_path.split('/').map(&:capitalize).join('::')
  end

  def extract_requires(content)
    content.each_line do |line|
      stripped = line.strip
      if stripped.start_with?('require ', 'require_relative ')
        @all_requires.add(line.rstrip)
      end
    end
  end

  def remove_requires(content)
    lines = content.lines.reject do |line|
      stripped = line.strip
      stripped.start_with?('require ', 'require_relative ')
    end
    lines.join
  end

  def write_combined_file
    File.open(@output_file, 'w') do |f|
      write_header(f)
      write_requires(f)
      write_controllers(f)
      write_footer(f)
    end
  end

  def write_header(f)
    f.puts <<~HEADER
      # frozen_string_literal: true
      
      # ============================================================================
      # COMBINED RAILS CONTROLLERS FILE
      # ============================================================================
      # Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
      # Total Files: #{@controller_files.length}
      # Source Directory: #{@controllers_dir}
      # ============================================================================
      
    HEADER
  end

  def write_requires(f)
    return if @all_requires.empty?

    f.puts "# ============ REQUIRES ============\n\n"
    @all_requires.sort.each do |req|
      f.puts req
    end
    f.puts "\n"
  end

  def write_controllers(f)
    f.puts "# ============ CONTROLLERS ============\n\n"

    # Sort namespaces - root first, then alphabetically
    sorted_namespaces = @namespaces.keys.sort do |a, b|
      if a == 'root'
        -1
      elsif b == 'root'
        1
      else
        a <=> b
      end
    end

    sorted_namespaces.each do |namespace|
      write_namespace(f, namespace)
    end
  end

  def write_namespace(f, namespace)
    controllers = @namespaces[namespace]
    
    if namespace == 'root'
      f.puts "# ============ ROOT CONTROLLERS ============\n\n"
      controllers.each { |ctrl| write_controller(f, ctrl) }
    else
      f.puts "# ============ NAMESPACE: #{namespace} ============\n\n"
      
      # Wrap in module if not already wrapped
      needs_module = controllers.any? do |ctrl|
        !ctrl[:content].strip.start_with?('module ')
      end

      if needs_module
        write_namespace_wrapper(f, namespace) do
          controllers.each { |ctrl| write_controller(f, ctrl, indent: true) }
        end
      else
        controllers.each { |ctrl| write_controller(f, ctrl) }
      end
    end
    
    f.puts "\n"
  end

  def write_namespace_wrapper(f, namespace)
    modules = namespace.split('::')
    indent_level = 0

    # Open modules
    modules.each do |mod|
      f.puts "#{' ' * (indent_level * 2)}module #{mod}"
      indent_level += 1
    end

    f.puts

    # Write content
    yield

    f.puts

    # Close modules
    modules.reverse.each do |_mod|
      indent_level -= 1
      f.puts "#{' ' * (indent_level * 2)}end"
    end
  end

  def write_controller(f, controller_info, indent: false)
    separator = '=' * 76
    base_indent = indent ? '  ' : ''

    f.puts "#{base_indent}#{separator}"
    f.puts "#{base_indent}# FILE: #{controller_info[:file]}"
    f.puts "#{base_indent}# PATH: #{controller_info[:path]}"
    f.puts "#{base_indent}#{separator}"
    f.puts

    content = controller_info[:content]
    
    if indent
      # Indent the content
      indented_content = content.lines.map { |line| "  #{line}" }.join
      f.puts indented_content
    else
      f.puts content
    end

    f.puts "\n"
  end

  def write_footer(f)
    f.puts "\n# ============ END OF COMBINED CONTROLLERS FILE ============\n"
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  controllers_dir = ARGV[0] || 'app/controllers'
  output_file = ARGV[1] || 'combined_controllers.rb'

  unless ARGV[0]
    print "Enter controllers directory path (press Enter for 'app/controllers'): "
    input = gets.chomp
    controllers_dir = input unless input.empty?
  end

  unless ARGV[1]
    print "Enter output filename (press Enter for 'combined_controllers.rb'): "
    input = gets.chomp
    output_file = input unless input.empty?
  end

  puts "\n📂 Controllers Directory: #{controllers_dir}"
  puts "📝 Output File: #{output_file}"
  puts

  merger = ControllerMerger.new(controllers_dir, output_file)
  success = merger.run

  exit(success ? 0 : 1)
end
