# frozen_string_literal: true
RSpec.describe DIDWW::Resource::Order do
  let (:client) { DIDWW::Client }

  it 'has STATUSES constant' do
    expect(described_class::STATUSES).to include('Pending', 'Completed', 'Canceled')
  end

  it 'has status helper methods' do
    order = described_class.load(status: described_class::STATUS_PENDING)
    expect(order.pending?).to be true
    order = described_class.load(status: described_class::STATUS_COMPLETED)
    expect(order.completed?).to be true
    order = described_class.load(status: described_class::STATUS_CANCELLED)
    expect(order.cancelled?).to be true
  end

  describe 'GET /orders/{id}' do
    let (:id) { 'f1d36d01-ce9d-4bec-a307-52aa405d20ae' }

    describe 'when Order exists' do
      let (:order) do
        stub_didww_request(:get, "/orders/#{id}").to_return(
          status: 200,
          body: api_fixture('orders/id/get/without_includes/200'),
          headers: json_api_headers
        )
        client.orders.find(id).first
      end

      it 'returns a single Order' do
        expect(order).to be_kind_of(DIDWW::Resource::Order)
        expect(order.id).to eq(id)
      end

      context 'has correct attributes' do
        it '"reference", type: String' do
          expect(order.reference).to be_kind_of(String)
        end
        it '"amount", type: BigDecimal' do
          expect(order.amount).to be_kind_of(BigDecimal)
        end
        it '"status", type: String' do
          expect(order.status).to be_in(['Pending', 'Completed', 'Canceled'])
        end
        it '"description", type: String' do
          expect(order.description).to be_kind_of(String)
        end
        it '"created_at", type: Time' do
          expect(order.created_at).to be_kind_of(Time)
        end
        it '"items", type: Array of DidOrderItem' do
          expect(order.items).to all be_an_instance_of(DIDWW::ComplexObject::DidOrderItem)
        end
      end
    end

    describe 'when Order does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:get, "/orders/#{id}").to_return(
          status: 404,
          body: api_fixture('orders/id/get/without_includes/404'),
          headers: json_api_headers
        )
        expect { client.orders.find(id) }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end
  end

  describe 'GET /orders' do
    it 'returns a collection of Orders' do
      stub_didww_request(:get, '/orders').to_return(
        status: 200,
        body: api_fixture('orders/get/without_includes/200'),
        headers: json_api_headers
      )
      expect(client.orders.all).to all be_an_instance_of(DIDWW::Resource::Order)
    end
  end

  describe 'POST /orders' do

    describe 'with correct attributes' do
      context 'did order type' do
        it 'with allow_back_ordering equal "true" creates an Order with a reference' do
          stub_didww_request(:post, '/orders').
            with(body:
              {
                "data": {
                  "type": 'orders',
                  "attributes": {
                    "allow_back_ordering": true,
                    "items": [
                      {
                        "type": 'did_order_items',
                        "attributes": {
                          "qty": 15,
                          "sku_id": 'a78bb6d8-b05e-4e12-afe6-ad84ac979088'
                        }
                      }
                    ]
                  }
                }
              }.to_json).
            to_return(
              status: 201,
              body: api_fixture('orders/post/did_order_with_back_ordering/201'),
              headers: json_api_headers
            )
          order = client.orders.new(allow_back_ordering: true)
          order.items << DIDWW::ComplexObject::DidOrderItem.new(qty: 15, sku_id: 'a78bb6d8-b05e-4e12-afe6-ad84ac979088')
          order.save
          expect(order).to be_persisted
          expect(order[:reference]).to be_kind_of(String)
        end
        it 'with allow_back_ordering equal "false" creates an Order' do
          stub_didww_request(:post, '/orders').
            with(body:
              {
                "data": {
                  "type": 'orders',
                  "attributes": {
                    "allow_back_ordering": false,
                    "items": [
                      {
                        "type": 'did_order_items',
                        "attributes": {
                          "qty": 15,
                          "sku_id": 'b6d9d793-578d-42d3-bc33-73dd8155e615'
                        }
                      }
                    ]
                  }
                }
              }.to_json).
            to_return(
              status: 201,
              body: api_fixture('orders/post/did_order_without_back_ordering/201'),
              headers: json_api_headers
            )
          order = client.orders.new(allow_back_ordering: false)
          order.items << DIDWW::ComplexObject::DidOrderItem.new(qty: 15, sku_id: 'b6d9d793-578d-42d3-bc33-73dd8155e615')
          order.save
          expect(order).to be_persisted
          expect(order.reference).to be_kind_of(String)
        end
        it 'with available_did_id' do
          stub_didww_request(:post, '/orders').
              with(body:
                       {
                           "data": {
                               "type": 'orders',
                               "attributes": {
                                   "allow_back_ordering": false,
                                   "items": [
                                       {
                                           "type": 'did_order_items',
                                           "attributes": {
                                               "sku_id": 'b6d9d793-578d-42d3-bc33-73dd8155e615',
                                               "available_did_id": '7f44285d-20ef-4773-953f-ba012adafed3'
                                           }
                                       }
                                   ]
                               }
                           }
                       }.to_json).
              to_return(
                  status: 201,
                  body: api_fixture('orders/post/did_order_with_available_did/201'),
                  headers: json_api_headers
              )
          order = client.orders.new(allow_back_ordering: false)
          order.items << DIDWW::ComplexObject::DidOrderItem.new(
              sku_id: 'b6d9d793-578d-42d3-bc33-73dd8155e615',
              available_did_id: '7f44285d-20ef-4773-953f-ba012adafed3'
          )
          order.save
          expect(order).to be_persisted
          expect(order[:reference]).to be_nil
        end
        it 'with did_reservation_id' do
          stub_didww_request(:post, '/orders').
              with(body:
                       {
                           "data": {
                               "type": 'orders',
                               "attributes": {
                                   "allow_back_ordering": false,
                                   "items": [
                                       {
                                           "type": 'did_order_items',
                                           "attributes": {
                                               "sku_id": 'b6d9d793-578d-42d3-bc33-73dd8155e615',
                                               "did_reservation_id": '2a1d98d2-eafd-4332-80d5-5ecd36411eb3'
                                           }
                                       }
                                   ]
                               }
                           }
                       }.to_json).
              to_return(
                  status: 201,
                  body: api_fixture('orders/post/did_order_without_back_ordering/201'),
                  headers: json_api_headers
              )
          order = client.orders.new(allow_back_ordering: false)
          order.items << DIDWW::ComplexObject::DidOrderItem.new(
              sku_id: 'b6d9d793-578d-42d3-bc33-73dd8155e615',
              did_reservation_id: '2a1d98d2-eafd-4332-80d5-5ecd36411eb3'
          )
          order.save
          expect(order).to be_persisted
          expect(order.reference).to be_kind_of(String)
        end

        context 'with nanpa_prefix_id attribute' do
          subject { order.save }

          let(:nanpa_prefix_id) { '3a33892b-bd4d-4411-b669-5eba6cc13807' }
          let(:sku_id) { 'b6d9d793-578d-42d3-bc33-73dd8155e615' }
          let!(:mock_post_create_order_request) do
            stub_didww_request(:post, '/orders')
              .with(body: {
                       "data": {
                         "type": 'orders',
                         "attributes": {
                           "allow_back_ordering": false,
                           "items": [
                             {
                               "type": 'did_order_items',
                               "attributes": {
                                 "sku_id": 'b6d9d793-578d-42d3-bc33-73dd8155e615',
                                 "nanpa_prefix_id": nanpa_prefix_id
                               }
                             }
                           ]
                         }
                       }
                }.to_json)
              .to_return(
                status: 201,
                body: api_fixture('orders/post/did_order_without_back_ordering/201'),
                headers: json_api_headers
              )
          end
          let(:did_order_item) { DIDWW::ComplexObject::DidOrderItem.new(sku_id: sku_id, nanpa_prefix_id: nanpa_prefix_id) }
          let(:order) { client.orders.new(allow_back_ordering: false, items: [did_order_item]) }

          it 'should create DID Order' do
            subject
            expect(order).to be_persisted
            expect(order.status).to eq 'Pending'
            expect(order.items).to be_one
            expect(order.reference).to be_kind_of(String)
          end

          it 'request should be performed properly' do
            subject
            expect(mock_post_create_order_request).to have_been_requested.at_least_once
          end
        end
      end
      context 'capacity order type' do
        it 'with capacity_pool_id' do
          stub_didww_request(:post, '/orders').
              with(body:
                      {
                          "data": {
                              "type": 'orders',
                              "attributes": {
                                  "allow_back_ordering": true,
                                  "items": [
                                      {
                                          "type": 'capacity_order_items',
                                          "attributes": {
                                              "qty": 5,
                                              "capacity_pool_id": '034f98bf-704c-4497-be9a-1c9ab399a900'
                                          }
                                      }
                                  ]
                              }
                          }
                      }.to_json).
              to_return(
                  status: 201,
                  body: api_fixture('orders/post/capacity_order/201'),
                  headers: json_api_headers
              )
          order = client.orders.new(allow_back_ordering: true)
          order.items << DIDWW::ComplexObject::CapacityOrderItem.new(
              qty: 5,
              capacity_pool_id: '034f98bf-704c-4497-be9a-1c9ab399a900'
          )
          order.save
          expect(order).to be_persisted
          expect(order.items[0].nrc).to be_kind_of(BigDecimal)
          expect(order.items[0].mrc).to be_kind_of(BigDecimal)
        end
      end
    end

    describe 'with incorrect attributes' do
      it 'returns an Order with errors' do
        stub_didww_request(:post, '/orders').
          with(body:
            {
              "data": {
                "type": 'orders',
                "attributes": {
                  "allow_back_ordering": true,
                  "items": [
                    {
                      "type": 'did_order_items',
                      "attributes": {
                        "qty": 15,
                        "sku_id": 'a78bb6d8-b05e-4e12-afe6-ad84ac979088'
                      }
                    }
                  ]
                }
              }
            }.to_json).
          to_return(
            status: 422,
            body: api_fixture('orders/post/did_order_with_back_ordering/422'),
            headers: json_api_headers
          )
        order = client.orders.new(allow_back_ordering: true)
        order.items << DIDWW::ComplexObject::DidOrderItem.new(qty: 15, sku_id: 'a78bb6d8-b05e-4e12-afe6-ad84ac979088')
        order.save
        expect(order).not_to be_persisted
        expect(order.errors.count).to eq 1
        expect(order.errors[:sku_id]).to contain_exactly('is invalid')
      end
    end

    describe 'insufficient funds for capacity order' do
      it 'returns an Order with errors' do
        stub_didww_request(:post, '/orders').
            with(body:
                    {
                        "data": {
                            "type": 'orders',
                            "attributes": {
                                "allow_back_ordering": true,
                                "items": [
                                    {
                                        "type": 'capacity_order_items',
                                        "attributes": {
                                            "qty": 5,
                                            "capacity_pool_id": '034f98bf-704c-4497-be9a-1c9ab399a900'
                                        }
                                    }
                                ]
                            }
                        }
                    }.to_json).
            to_return(
                status: 400,
                body: api_fixture('orders/post/capacity_order/400'),
                headers: json_api_headers
            )
        order = client.orders.new(allow_back_ordering: true)
        order.items << DIDWW::ComplexObject::CapacityOrderItem.new(
            qty: 5,
            capacity_pool_id: '034f98bf-704c-4497-be9a-1c9ab399a900'
        )
        expect { order.save }.to raise_error(JsonApiClient::Errors::ClientError, 'Insufficient funds')
        expect(order).to_not be_persisted
      end
    end

    describe 'qty is less than minimum_qty_per_order for capacity order' do
      it 'returns an Order with errors' do
        stub_didww_request(:post, '/orders').
            with(body:
                    {
                        "data": {
                            "type": 'orders',
                            "attributes": {
                                "allow_back_ordering": true,
                                "items": [
                                    {
                                        "type": 'capacity_order_items',
                                        "attributes": {
                                            "qty": 3,
                                            "capacity_pool_id": '034f98bf-704c-4497-be9a-1c9ab399a900'
                                        }
                                    }
                                ]
                            }
                        }
                    }.to_json).
            to_return(
                status: 422,
                body: api_fixture('orders/post/capacity_order/422'),
                headers: json_api_headers
            )
        order = client.orders.new(allow_back_ordering: true)
        order.items << DIDWW::ComplexObject::CapacityOrderItem.new(
            qty: 3,
            capacity_pool_id: '034f98bf-704c-4497-be9a-1c9ab399a900'
        )
        order.save
        expect(order).to_not be_persisted
        expect(order.errors.count).to eq 1
        expect(order.errors.full_messages.to_sentence).to eq('Qty should be at least 5')
      end
    end

  end

  describe 'DELETE /orders/{id}' do
    let (:id) { '1b3ac4b7-315c-4416-afb8-24d8e7c4ec0c' }
    it 'deletes an Order' do
      stub_didww_request(:delete, "/orders/#{id}").
        to_return(
          status: 202,
          body: api_fixture('orders/id/delete/delete_order/202'),
          headers: json_api_headers
        )
      order = DIDWW::Resource::Order.load(id: id)
      expect(order.destroy)
      expect(WebMock).to have_requested(:delete, api_uri("/orders/#{id}"))
    end

    context 'when Order does not exist' do
      it 'raises a NotFound error' do
        stub_didww_request(:delete, "/orders/#{id}").
        to_return(
          status: 404,
          body: api_fixture('orders/id/delete/delete_order/404'),
          headers: json_api_headers
        )
        order = DIDWW::Resource::Order.load(id: id)
        expect { order.destroy }.to raise_error(JsonApiClient::Errors::NotFound)
        expect(WebMock).to have_requested(:delete, api_uri("/orders/#{id}"))
      end
    end

    context 'when Order cannot be destroyed' do
      it 'returns an Order with errors' do
        stub_didww_request(:delete, "/orders/#{id}").
        to_return(
          status: 422,
          body: api_fixture('orders/id/delete/delete_order/422'),
          headers: json_api_headers
        )
        order = DIDWW::Resource::Order.load(id: id)
        expect(order.destroy).to be false
        expect(order.errors.count).to eq 1
        expect(order.errors[:base]).to contain_exactly('Order not pending')
        expect(WebMock).to have_requested(:delete, api_uri("/orders/#{id}"))
      end
    end

  end

end
