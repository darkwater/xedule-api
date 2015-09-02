require 'json'
require 'fileutils'
require './xedule.rb'

class Fixnum
    { seconds: 1,
      minutes: 60,
      hours:   60 * 60,
      days:    60 * 60 * 24 }.each do |name, mul|
        define_method(name){ self * mul }
    end
end

before do
    @url = "#{request.path}?#{request.query_string}"
    @cachedResponse = CachedResponse.get(@url)
end

get '/organisations.json' do
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.organisations
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
    else
        @dataset = Organisation.all
    end

    @dataset.to_json
end

get '/:org/locations.json' do |organisation_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.locations organisation_id.to_i
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
    else
        @dataset = Location.all organisation_id: organisation_id.to_i
    end

    @dataset.to_json
end

get '/:org/:loc/attendees.json' do |organisation_id, location_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.attendees location_id.to_i
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
    else
        @dataset = Attendee.all location_id: location_id.to_i
    end

    @dataset.map{ |n| n.attributes.reject{ |k,v| k == :location_id } }.to_json
end

get '/:org/:loc/:att/schedule.json' do |organisation_id, location_id, attendee_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.hours
        @dataset = Xedule.schedule attendee_id.to_i, params[:year], params[:week]
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
    else
        @dataset = Event.all attendee_id: attendee_id.to_i, year: params[:year], week: params[:week]
    end

    @dataset.map do |n|
        a = n.attributes
        a.reject!{ |k,v| k == :attendee_id }
        a[:attendees] = n.attendees.split(',').map(&:to_i)
        a
    end.to_json
end
