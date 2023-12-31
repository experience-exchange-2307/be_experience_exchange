require 'rails_helper'

RSpec.describe 'Meetings API', type: :request do
  describe 'POST /api/v1/meetings', :vcr do
    it 'meeting can be created between two users' do
      user = create(:user)
      partner = create(:user)
      expect(Meeting.count).to eq(0)

      meeting_info = {
        user_id: user.id,
        partner_id: partner.id,
        date: Faker::Date.forward,
        start_time: Faker::Time.forward,
        end_time: Faker::Time.forward,
        purpose: Faker::Lorem.sentence
      }

      post "/api/v1/meetings", params: meeting_info
      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(Meeting.count).to eq(1)

      data = JSON.parse(response.body, symbolize_names: true)
      meeting = Meeting.last
      expect(data).to have_key(:data)

      meeting_data = data[:data]
      expect(meeting_data).to be_a(Hash)
      expect(meeting_data).to have_key(:id)
      expect(meeting_data[:id]).to eq(meeting.id.to_s)
      expect(meeting_data).to have_key(:type)
      expect(meeting_data[:type]).to eq("meeting")
      expect(meeting_data).to have_key(:attributes)

      meeting_attributes = meeting_data[:attributes]
      expect(meeting_attributes).to have_key(:partner_id)
      expect(meeting_attributes[:partner_id]).to eq(partner.id)
      expect(meeting_attributes).to have_key(:date)
      expect(meeting_attributes).to have_key(:start_time)
      expect(meeting_attributes).to have_key(:is_accepted)
      expect(meeting_attributes).to have_key(:end_time)
    end

    it 'returns an error if a partner is not found' do
      user = create(:user)

      meeting_info = {
        user_id: user.id,
        partner_id: 2,
        date: Faker::Date.forward,
        start_time: Faker::Time.forward,
        end_time: Faker::Time.forward,
        is_accepted: false,
        purpose: Faker::Lorem.sentence
      }

      post "/api/v1/meetings", params: meeting_info

      expect(response).to have_http_status(:not_found)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to_not have_key(:data)
      expect(data).to have_key(:error)
      expect(data[:error]).to eq("Partner not found.")
    end

    it 'returns an error if params are missing for the meeting' do
      user = create(:user)
      partner = create(:user)

      meeting_info = {
        user_id: user.id,
        partner_id: partner.id
      }

      post "/api/v1/meetings", params: meeting_info

      expect(response).to have_http_status(:unprocessable_entity)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to_not have_key(:data)
      expect(data).to have_key(:error)
      expect(data[:error]).to eq("Date can't be blank, Start time can't be blank, End time can't be blank, and Purpose can't be blank")
    end
  end

  describe 'PATCH /api/v1/meetings/:meeting_id', :vcr do
    it 'updates the meeting when is_approved is true' do
      user = create(:user)
      partner = create(:user)
      meeting = create(:meeting)
      UserMeeting.create(user: user, meeting: meeting, is_requestor: true)
      UserMeeting.create(user: partner, meeting: meeting, is_requestor: false)

      expect(Meeting.count).to eq(1)

      update_params = { is_approved: 'true' }

      put "/api/v1/meetings/#{meeting.id}", params: update_params

      expect(response).to be_successful
      expect(response.status).to eq(200)

      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to have_key(:success)
      expect(data[:success]).to eq('Meeting updated successfully. Meeting is accepted.')

      updated_meeting = Meeting.find(meeting.id)
      expect(updated_meeting.is_accepted).to eq(true)
    end

    it 'updates the meeting when is_approved is false' do
      user = create(:user)
      partner = create(:user)
      meeting = create(:meeting, is_accepted: true)
      UserMeeting.create(user: user, meeting: meeting, is_requestor: true)
      UserMeeting.create(user: partner, meeting: meeting, is_requestor: false)

      expect(Meeting.count).to eq(1)

      update_params = { is_approved: 'false' }

      put "/api/v1/meetings/#{meeting.id}", params: update_params

      expect(response).to be_successful
      expect(response.status).to eq(200)

      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to have_key(:success)
      expect(data[:success]).to eq('Meeting updated successfully. Meeting is not accepted.')

      updated_meeting = Meeting.find(meeting.id)
      expect(updated_meeting.is_accepted).to eq(false)
    end

    it 'returns an error if meeting is not found' do
      update_params = { is_approved: 'true' }

      put "/api/v1/meetings/999", params: update_params

      expect(response).to have_http_status(:not_found)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to_not have_key(:success)
      expect(data).to have_key(:error)
      expect(data[:error]).to eq('Meeting not found.')
    end

    it 'returns an error if is_approved parameter is not provided' do
      user = create(:user)
      partner = create(:user)
      meeting = create(:meeting)
      UserMeeting.create(user: user, meeting: meeting, is_requestor: true)
      UserMeeting.create(user: partner, meeting: meeting, is_requestor: false)

      update_params = {}

      put "/api/v1/meetings/#{meeting.id}", params: update_params

      expect(response).to have_http_status(:unprocessable_entity)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to_not have_key(:success)
      expect(data).to have_key(:error)
      expect(data[:error]).to eq('Invalid parameter value for is_approved.')
    end
  end

  describe 'DELETE /api/v1/meetings/:meeting_id', :vcr do
    it 'deletes the meeting' do
      user = create(:user)
      partner = create(:user)
      meeting = create(:meeting)

      UserMeeting.create(user: user, meeting: meeting, is_requestor: true)
      UserMeeting.create(user: partner, meeting: meeting, is_requestor: false)

      expect(Meeting.count).to eq(1)
      expect(UserMeeting.count).to eq(2)

      delete "/api/v1/meetings/#{meeting.id}"

      expect(response).to be_successful
      expect(response.status).to eq(204)

      expect(Meeting.count).to eq(0)
      expect(UserMeeting.count).to eq(0)
    end

    it 'returns an error if the meeting is not found' do
      delete "/api/v1/meetings/999"

      expect(response).to have_http_status(:not_found)

      data = JSON.parse(response.body, symbolize_names: true)
      expect(data).to_not have_key(:data)
      expect(data).to have_key(:error)
      expect(data[:error]).to eq("Meeting not found.")
    end
  end
end
