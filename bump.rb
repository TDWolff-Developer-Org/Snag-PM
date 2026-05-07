#!/usr/bin/env ruby
# frozen_string_literal: true
#
# bump.rb — auto-bump tracked third-party packages in Formula/registry.json.
#
# A package is considered "trackable" if it has an `auto_bump` block:
#
#   "ripgrep": {
#     "auto_bump": { "github_repo": "BurntSushi/ripgrep" },
#     ...
#   }
#
# For each such package, this script:
#   1. Hits api.github.com/repos/<repo>/releases/latest
#   2. Compares tag (with leading "v" stripped) against the package's `version`
#   3. If different, rewrites every URL in the entry by substituting the
#      old version string with the new one, downloads each tarball, and
#      computes a fresh SHA256
#   4. Writes the updated registry back to disk
#
# Set GITHUB_TOKEN to lift the API rate limit from 60/hr to 5000/hr.
# Inside GitHub Actions, GITHUB_TOKEN is provided automatically.

require 'net/http'
require 'json'
require 'digest'
require 'uri'

REGISTRY_PATH = File.expand_path('Formula/registry.json', __dir__)

RESET  = "\e[0m"
BOLD   = "\e[1m"
DIM    = "\e[2m"
RED    = "\e[31m"
GREEN  = "\e[32m"
YELLOW = "\e[33m"
CYAN   = "\e[36m"

def step(msg)  = puts("#{CYAN}==>#{RESET} #{BOLD}#{msg}#{RESET}")
def ok(msg)    = puts("#{GREEN}✓#{RESET} #{msg}")
def warn(msg)  = puts("#{YELLOW}⚠#{RESET}  #{msg}")
def err(msg)   = puts("#{RED}✗#{RESET} #{msg}")
def info(msg)  = puts("  #{msg}")

def fetch(url, limit = 5)
  raise 'Too many redirects' if limit.zero?
  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'snag-bump/1.0'
  req['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN']
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                  open_timeout: 10, read_timeout: 60) do |http|
    response = http.request(req)
    case response.code
    when '200' then return response.body
    when '301', '302', '307', '308' then return fetch(response['location'], limit - 1)
    else raise "HTTP #{response.code}: #{url}"
    end
  end
end

def latest_release_tag(repo)
  data = JSON.parse(fetch("https://api.github.com/repos/#{repo}/releases/latest"))
  data['tag_name'].sub(/\Av/, '')
end

def sha256_of(url)
  Digest::SHA256.hexdigest(fetch(url))
end

def update_url_entry(entry, old_v, new_v)
  new_url = entry['url'].gsub(old_v, new_v)
  print "  #{DIM}#{new_url}#{RESET} ... "
  new_sha = sha256_of(new_url)
  puts "#{GREEN}ok#{RESET} #{DIM}#{new_sha[0, 12]}…#{RESET}"
  entry['url'] = new_url
  entry['sha256'] = new_sha
  true
rescue => e
  puts "#{RED}fail#{RESET} (#{e.message})"
  false
end

# --- Main ---

raw = File.read(REGISTRY_PATH)
registry = JSON.parse(raw)
packages = registry['packages']
changed = false
failures = []

packages.each do |name, pkg|
  next unless pkg['auto_bump']

  step "Checking #{BOLD}#{name}#{RESET}"
  repo = pkg['auto_bump']['github_repo']
  current = pkg['version']

  begin
    latest = latest_release_tag(repo)
  rescue => e
    err "Could not fetch latest for #{repo}: #{e.message}"
    failures << name
    next
  end

  if latest == current
    ok "#{name} #{current} is up to date"
    next
  end

  info "#{YELLOW}#{current}#{RESET} → #{GREEN}#{latest}#{RESET}"

  success = true
  if pkg['platforms']
    pkg['platforms'].each do |platform, data|
      print "  #{platform.ljust(20)} "
      success &&= update_url_entry(data, current, latest)
    end
  elsif pkg['url']
    success &&= update_url_entry(pkg, current, latest)
  end

  if success
    pkg['version'] = latest
    ok "Bumped #{name} to #{latest}"
    changed = true
  else
    err "Failed to update one or more URLs — leaving #{name} at #{current}"
    failures << name
  end
end

if changed
  registry['updated'] = Time.now.utc.strftime('%Y-%m-%d')
  File.write(REGISTRY_PATH, JSON.pretty_generate(registry) + "\n")
  ok "Wrote #{REGISTRY_PATH}"
else
  ok "Nothing to bump"
end

unless failures.empty?
  warn "Failures: #{failures.join(', ')}"
  exit 1
end
