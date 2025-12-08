#!/usr/bin/env ruby

# Script to merge all Rails model files into a single models.rb file
# Usage: ruby merge_models.rb

require 'fileutils'

# Configuration
MODELS_DIR = 'app/models'
OUTPUT_FILE = 'models.rb'

def merge_models
  puts "🔍 Scanning models directory: #{MODELS_DIR}"
  
  # Get all .rb files from models directory (excluding concerns)
  model_files = Dir.glob("#{MODELS_DIR}/**/*.rb").reject { |f| f.include?('/concerns/') }
  
  if model_files.empty?
    puts "❌ No model files found in #{MODELS_DIR}"
    return
  end
  
  puts "📂 Found #{model_files.length} model files"
  
  # Create/overwrite output file
  File.open(OUTPUT_FILE, 'w') do |output|
    # Add header
    output.puts "# =========================================="
    output.puts "# All Rails Models - Merged for AI Context"
    output.puts "# Generated: #{Time.now}"
    output.puts "# Total Models: #{model_files.length}"
    output.puts "# =========================================="
    output.puts "\n"
    
    model_files.sort.each_with_index do |file, index|
      model_name = File.basename(file, '.rb')
      
      output.puts "\n"
      output.puts "# " + ("=" * 60)
      output.puts "# Model #{index + 1}: #{model_name}"
      output.puts "# File: #{file}"
      output.puts "# " + ("=" * 60)
      output.puts "\n"
      
      # Read and write file contents
      output.puts File.read(file)
      
      puts "  ✅ Merged: #{model_name} (#{file})"
    end
    
    # Add footer
    output.puts "\n"
    output.puts "# =========================================="
    output.puts "# End of Models"
    output.puts "# =========================================="
  end
  
  puts "\n🎉 Success! All models merged into: #{OUTPUT_FILE}"
  puts "📊 File size: #{File.size(OUTPUT_FILE)} bytes"
  puts "\n💡 You can now share this file with Reena for context!"
end

# Run the script
begin
  merge_models
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
end