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
    headers 'Access-Control-Allow-Origin' => '*'
    @url = "#{request.path}?#{request.query_string}"
    @cachedResponse = CachedResponse.get(@url)
end

get '/organisations.json' do
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.organisations
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
        puts "Getting organisations fresh"
    else
        @dataset = Organisation.all
        puts "Getting organisations from cache (#{@dataset.size} items)"
    end

    @dataset.to_json
end

get '/:org/locations.json' do |organisation_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.locations organisation_id.to_i
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
        puts "Getting locations for #{organisation_id} fresh"
    else
        @dataset = Location.all organisation_id: organisation_id.to_i
        puts "Getting locations for #{organisation_id} from cache (#{@dataset.size} items)"
    end

    @dataset.to_json
end

get '/:org/:loc/attendees.json' do |organisation_id, location_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.days
        @dataset = Xedule.attendees location_id.to_i
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
        puts "Getting attendees for #{location_id} fresh"
    else
        @dataset = Attendee.all location_id: location_id.to_i
        puts "Getting attendees for #{location_id} from cache (#{@dataset.size} items)"
    end

    @dataset.map{ |n| n.attributes.reject{ |k,v| k == :location_id } }.to_json
end

get '/:org/:loc/:att/schedule.json' do |organisation_id, location_id, attendee_id|
    if @cachedResponse.nil? || @cachedResponse.age > 1.hours
        @dataset = Xedule.schedule location_id.to_i, attendee_id.to_i, params[:year], params[:week]
        CachedResponse.first_or_create({ url: @url }, { timestamp: Time.now }).update( timestamp: Time.now )
        puts "Getting events for #{attendee_id} (#{params[:year]}/#{params[:week]}) fresh"
    else
        @dataset = Attendee.get(attendee_id.to_i).events.all year: params[:year], week: params[:week]
        puts "Getting events for #{attendee_id} (#{params[:year]}/#{params[:week]}) from cache (#{@dataset.size} items)"
    end

    @dataset.map do |n|
        a = n.attributes
        a.reject!{ |k,v| k == :location_id }
        a[:attendees] = n.attendees.map(&:id)
        a
    end.to_json
end
