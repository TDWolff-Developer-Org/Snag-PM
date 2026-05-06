#!/usr/bin/env ruby
# frozen_string_literal: true

# Packages each directory under examples/ into a versioned .tar.gz in dist/,
# computes SHA256, and patches Formula/registry.json in place.
#
# Usage:
#   ruby build.rb              # build all packages
#   ruby build.rb hello        # build a single package

require 'fileutils'
require 'digest'
require 'json'
require 'tmpdir'

ROOT          = __dir__
EXAMPLES_DIR  = File.join(ROOT, "examples")
DIST_DIR      = File.join(ROOT, "dist")
REGISTRY_PATH = File.join(ROOT, "Formula", "registry.json")

RESET  = "\e[0m"
GREEN  = "\e[32m"
YELLOW = "\e[33m"
BLUE   = "\e[34m"
BOLD   = "\e[1m"

def step(msg) = puts("#{BLUE}===>#{RESET} #{BOLD}#{msg}#{RESET}")
def ok(msg)   = puts("  #{GREEN}✓#{RESET} #{msg}")
def note(msg) = puts("  #{YELLOW}→#{RESET} #{msg}")

# ── Load registry ───────────────────────────────────────────────────────────────

registry = JSON.parse(File.read(REGISTRY_PATH))
packages = registry["packages"]

FileUtils.mkdir_p(DIST_DIR)

# ── Determine what to build ─────────────────────────────────────────────────────

targets = ARGV.empty? ? Dir.children(EXAMPLES_DIR).sort : ARGV

targets.each do |pkg_name|
  pkg_dir = File.join(EXAMPLES_DIR, pkg_name)

  unless File.directory?(pkg_dir)
    puts "  #{YELLOW}Skipping#{RESET} #{pkg_name} (not found in examples/)"
    next
  end

  unless packages.key?(pkg_name)
    puts "  #{YELLOW}Skipping#{RESET} #{pkg_name} (not in registry.json)"
    next
  end

  version      = packages[pkg_name]["version"]
  archive_name = "#{pkg_name}-#{version}.tar.gz"
  archive_path = File.join(DIST_DIR, archive_name)

  step "Building #{pkg_name} #{version}"

  Dir.mktmpdir do |tmp|
    stage_name = "#{pkg_name}-#{version}"
    stage      = File.join(tmp, stage_name)
    bin_stage  = File.join(stage, "bin")
    FileUtils.mkdir_p(bin_stage)

    # Copy all files from the example dir into bin/
    Dir.each_child(pkg_dir) do |fname|
      src = File.join(pkg_dir, fname)
      next unless File.file?(src)

      dest = File.join(bin_stage, fname)
      FileUtils.cp(src, dest)
      FileUtils.chmod(0o755, dest) unless fname.match?(/\.(md|txt|json)$/)
      ok "Staged #{fname}"
    end

    # Fix all timestamps to epoch so the tarball SHA is reproducible across runs
    Dir.glob(File.join(stage, "**", "*")).each { |f| File.utime(0, 0, f) }

    system("tar", "-czf", archive_path, "-C", tmp, stage_name, exception: true)
  end

  sha256 = Digest::SHA256.file(archive_path).hexdigest
  packages[pkg_name]["sha256"] = sha256

  ok "Archive : dist/#{archive_name}"
  ok "SHA256  : #{sha256}"
  ok "Size    : #{File.size(archive_path)} bytes"
  puts
end

# ── Write updated registry ──────────────────────────────────────────────────────

registry["updated"] = Time.now.strftime("%Y-%m-%d")
File.write(REGISTRY_PATH, JSON.pretty_generate(registry) + "\n")

puts "#{GREEN}#{BOLD}Done.#{RESET}"
puts
puts "Next steps:"
puts "  1. Upload files from #{BLUE}dist/#{RESET} to GitHub Releases"
puts "     Tag each release as:  hello-1.0.0 / quickserve-1.0.0 / etc."
puts "  2. Commit the updated #{BLUE}Formula/registry.json#{RESET}"
puts "  3. Push to GitHub and test:  snag update && snag install hello"
puts
