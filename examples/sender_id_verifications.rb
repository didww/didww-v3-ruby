# frozen_string_literal: true
# Lists Sender ID verifications with their SMS trunks, and routes one
# verification's outbound messages through an SMS trunk that sends them.
#
# A verification is created and reviewed outside the API; only its name and
# its SMS trunk can be changed, and a closed one cannot be changed at all.
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
  puts "#{v.reference} #{v.name} (#{v.sender_type}, #{v.status}): #{v.sender_ids.join(', ')} via #{routed_through}"
  puts "  changes required: #{Array(v.reject_reasons).join('; ')} #{v.reject_comment}" if v.changes_required?
end

verification = verifications.find(&:active?)
abort 'No active Sender ID verification' unless verification

trunk = DIDWW::Client.sms_trunks.all.find(&:allow_out)
abort 'No SMS trunk that sends messages' unless trunk

puts "\n=== Routing #{verification.reference} through #{trunk.name} ==="
verification.sms_trunk = trunk
if verification.save
  puts "Routed through #{trunk.id}"
else
  abort "Error routing the verification: #{verification.errors.full_messages}"
end

puts "\nActive verifications routed through this trunk:"
DIDWW::Client.sender_id_verifications
             .where(status: verification_class::STATUS_ACTIVE, 'sms_trunk.id': trunk.id)
             .all
             .each { |v| puts "  #{v.reference} #{v.name}" }
