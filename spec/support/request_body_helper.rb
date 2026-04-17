# frozen_string_literal: true
module RequestBodyHelper
  # Build a JSON:API PATCH request body (with id).
  def json_api_body(id:, type:, attributes: {}, relationships: {})
    data = { id: id, type: type }
    data[:relationships] = relationships unless relationships.empty?
    data[:attributes] = attributes
    { data: data }.to_json
  end

  # Build a JSON:API POST request body (no id).
  def json_api_post_body(type:, attributes: {}, relationships: {})
    data = { type: type, attributes: attributes }
    data[:relationships] = relationships unless relationships.empty?
    { data: data }.to_json
  end
end
