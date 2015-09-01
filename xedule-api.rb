require 'json'
require 'fileutils'
require './xedule.rb'

get '/organisations.json' do
    Xedule.organisations.to_json
end

get '/:org/locations.json' do |organisation_id|
    Xedule.locations(organisation_id.to_i).to_json
end

get '/:org/:loc/attendees.json' do |organisation_id, location_id|
    Xedule.attendees(location_id.to_i)
        .map{ |n| n.attributes.reject{ |k,v| k == :location_id } }.to_json
end

get '/:org/:loc/:att/schedule.json' do |organisation_id, location_id, attendee_id|
    Xedule.schedule(attendee_id, params[:year], params[:week])
        .map{ |n| n.attributes.reject{ |k,v| k == :attendee_id } }.to_json
end
