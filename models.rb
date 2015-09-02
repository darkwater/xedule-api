require 'data_mapper'

DataMapper.setup(:default, 'sqlite::memory:')

class Organisation
    include DataMapper::Resource

    property :id,   Integer, key: true
    property :name, String

    has n, :locations
    has n, :attendees, through: :locations
end

class Location
    include DataMapper::Resource

    property :id,   Integer, key: true
    property :name, String

    belongs_to :organisation
    has n, :attendees
    has n, :events
end

class Attendee
    include DataMapper::Resource

    property :id,   Integer, key: true
    property :type, Enum[ :class, :staff, :facility ]
    property :name, String, index: true

    belongs_to :location
    has 1, :organisation, through: :location
end

class Event
    include DataMapper::Resource

    property :id,          Serial
    property :year,        Integer
    property :week,        Integer
    property :day,         Enum[ :sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday ]
    property :start,       String
    property :end,         String
    property :description, String
    property :classes,     String, default: ''
    property :staff,       String, default: ''
    property :facilities,  String, default: ''
    property :attendees,   String, default: ''

    belongs_to :location

    def <<(attendee)
        case attendee.type
        when :class
            self.classes = classes.split(',').push(attendee.name).join(',')
        when :staff
            self.staff = staff.split(',').push(attendee.name).join(',')
        when :facility
            self.facilities = facilities.split(',').push(attendee.name).join(',')
        end

        self.attendees = attendees.split(',').push(attendee.id).join(',')
    end
end

class CachedResponse
    include DataMapper::Resource

    property :url,       String, key: true
    property :timestamp, Time

    def age
        Time.now - timestamp
    end
end

DataMapper.auto_migrate!
