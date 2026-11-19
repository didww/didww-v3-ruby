# frozen_string_literal: true
# Shared capacity groups: creates a group in a capacity pool, lists groups,
# updates the group and deletes it, also when a step fails.
#
# shared_channels_count is the number of the pool's channels shared among the
# group's DIDs; metered_channels_count caps the metered channels they may use.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/shared_capacity_groups.rb

require 'bundler/setup'
require 'didww'
require 'securerandom'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

suffix = SecureRandom.hex(4)

# Get a capacity pool
pool = DIDWW::Client.capacity_pools.page(1).per(1).all.first
abort 'No capacity pools found' unless pool
puts "Using capacity pool: #{pool.name} (#{pool.total_channels_count} channels, #{pool.assigned_channels_count} assigned)"

# Create a shared capacity group (2026-04-16 external_reference_id for customer tagging)
puts "\n=== Creating Shared Capacity Group ==="
group = DIDWW::Client.shared_capacity_groups.new(
  name: "Ruby Channel Group #{suffix}",
  shared_channels_count: 1,
  metered_channels_count: 10,
  external_reference_id: "ruby-scg-#{suffix}"
)
group.capacity_pool = pool
abort "Error creating shared capacity group: #{group.errors.full_messages}" unless group.save
puts "Created: #{group.id}"
puts "  Name: #{group.name}"
puts "  Shared: #{group.shared_channels_count}, metered: #{group.metered_channels_count}"
puts "  External reference: #{group.external_reference_id}"

begin
  # List shared capacity groups with their capacity pool
  puts "\n=== Shared Capacity Groups ==="
  groups = DIDWW::Client.shared_capacity_groups
           .includes(:capacity_pool)
           .all
  puts "Found #{groups.size} shared capacity groups"
  groups.each do |g|
    puts "  #{g.name} shared=#{g.shared_channels_count} metered=#{g.metered_channels_count} pool=#{g.capacity_pool&.name}"
  end

  # Update: only the changed attributes are sent
  puts "\n=== Updating Shared Capacity Group ==="
  group.name = "Ruby Channel Group #{suffix} (v2)"
  group.metered_channels_count = 5
  abort "Error updating shared capacity group: #{group.errors.full_messages}" unless group.save
  puts "Updated: #{group.name}, metered: #{group.metered_channels_count}"
ensure
  puts "\n=== Deleting Shared Capacity Group ==="
  puts group.destroy ? 'Deleted shared capacity group' : "Error deleting shared capacity group: #{group.errors.full_messages}"
end
