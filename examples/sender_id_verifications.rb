# frozen_string_literal: true
# Lists Sender ID verifications with their SMS trunks, renames an active one
# and restores its original name, also when a step fails.
#
# A verification is created and reviewed outside the API; only its name and
# its SMS trunk can be changed, and a closed one cannot be changed at all.
# Only http_out, smpp_esme and smpp_smsc trunks are accepted as its SMS trunk.
#
# Usage: DIDWW_API_KEY=your_api_key ruby examples/sender_id_verifications.rb

require 'bundler/setup'
require 'didww'

DIDWW::Client.configure do |client|
  client.api_key  = ENV.fetch('DIDWW_API_KEY') { abort 'Please set DIDWW_API_KEY' }
  client.api_mode = :sandbox
end

verification_class = DIDWW::Resource::SenderIdVerification

puts '=== Sender ID Verifications ==='
verifications = DIDWW::Client.sender_id_verifications.includes(:sms_trunk).all
verifications.each do |v|
  routed_through = v.sms_trunk&.name || 'no SMS trunk'
  puts "#{v.reference} #{v.name} (#{v.sender_type}, #{v.status}): #{Array(v.sender_ids).join(', ')} via #{routed_through}"
  puts "  changes required: #{Array(v.reject_reasons).join('; ')} #{v.reject_comment}" if v.changes_required?
  # Prices are decimal strings; the renew date is "YYYY-MM-DD", nil once closed
  meta = v.attributes[:meta] || {}
  puts "  setup price: #{meta[:setup_price]}, monthly price: #{meta[:monthly_price]}, renews: #{v.renew_date}"
end

verification = verifications.find(&:active?)
abort 'No active Sender ID verification' unless verification
original_name = verification.name

puts "\n=== Renaming #{verification.reference} ==="
begin
  rename = verification_class.load(id: verification.id)
  rename.name = "#{original_name} (renamed)"
  abort "Error renaming the verification: #{rename.errors.full_messages}" unless rename.save
  puts "Name: #{rename.name}"
ensure
  restore = verification_class.load(id: verification.id)
  restore.name = original_name
  puts restore.save ? "Name restored: #{original_name}" : "Error restoring the name: #{restore.errors.full_messages}"
end

# Routing through an SMS trunk that sends messages works the same way; nil
# unassigns the trunk, which stops outbound messages until one is assigned again:
#
#   route = DIDWW::Resource::SenderIdVerification.load(id: verification.id)
#   route.sms_trunk = DIDWW::Resource::SmsTrunk.load(id: 'sending-sms-trunk-uuid')
#   route.save

puts "\nActive verifications by SMS trunk:"
if verification.sms_trunk
  DIDWW::Client.sender_id_verifications
               .where(status: verification_class::STATUS_ACTIVE, 'sms_trunk.id': verification.sms_trunk.id)
               .all
               .each { |v| puts "  #{v.reference} #{v.name} via #{verification.sms_trunk.name}" }
else
  puts "  #{verification.reference} has no SMS trunk"
end
