require 'net/http'
require 'uri'
require './models.rb'

module Xedule
    def self.get(path)
        puts "Getting #{path}"
        Net::HTTP.get(URI.join('https://summacollege.xedule.nl', path))
    end

    def self.organisations
        get('/').scan(/.Organisatie.OrganisatorischeEenheid.([0-9]+)\?Code=([^"]+)/).map do |id, name|
            data = {
                id: id.to_i,
                name: URI.unescape(name)
            }

            organisation = Organisation.first_or_create({ id: data[:id] }, data)
            organisation.update(data)

            organisation
        end
    end

    def self.locations(organisation_id)
        get("/Organisatie/OrganisatorischeEenheid/#{organisation_id}")
        .scan(/.OrganisatorischeEenheid.Attendees.([0-9]+)\?Code=([^&]+)/).map do |id, name|
            data = {
                id: id.to_i,
                name: URI.unescape(name),
                organisation_id: organisation_id
            }

            location = Location.first_or_create({ id: data[:id] }, data)
            location.update(data)

            location
        end
    end

    def self.attendees(location_id)
        get("/OrganisatorischeEenheid/Attendees/#{location_id}")
        .scan(/option value="([0-9]+)\?Code=([^&]+)&amp;attId=([1-3])&amp;OreId=#{location_id}"/).map do |id, name, type|
            data = {
                id: id.to_i,
                name: URI.unescape(name),
                type: [ nil, :class, :staff, :facility ][type.to_i],
                location_id: location_id
            }

            if attendee = Attendee.get(data[:id])
                attendee.update data
            else
                attendee = Attendee.create data
            end

            p attendee.errors unless attendee.saved?

            attendee
        end
    end

    def self.schedule(attendee_id, year, week)
        attendee = Attendee.get(attendee_id)
        attendee.events( year: year, week: week ).destroy

        event = nil
        events = []

        get("/Calendar/iCalendarICS/#{attendee_id}?year=#{year}&week=#{week}").each_line do |line|
            line.chomp!

            if line == 'BEGIN:VEVENT'
                event = Event.new
                event.location_id = attendee.location_id
            elsif line == 'END:VEVENT'
                event.save
                events << event
                event = nil
            elsif not event.nil?
                case line
                when /ATTENDEE;CN=([^:]+):MAILTO:noreply@xedule.nl
                     |LOCATION:(.+)$/x
                    att = Attendee.first(name: $1 || $2, location_id: attendee.location_id)
                    event << att
                when /DESCRIPTION:(.+)/
                    event.description = $1
                when /DTSTART.*:([0-9]+)T([0-9]+)$/ # yyyymmddThhmmss
                    date = Date.parse($1)
                    event.year = date.year
                    event.week = date.cweek
                    event.day = date.wday

                    hour = $2[0, 2]
                    mins = $2[2, 2]
                    event.start = "#{hour}:#{mins}"
                when /DTEND.*:[0-9]+T([0-9]+)$/ # yyyymmddThhmmss
                    hour = $1[0, 2]
                    mins = $1[2, 2]
                    event.end = "#{hour}:#{mins}"
                end
            end
        end

        events
    end
end
