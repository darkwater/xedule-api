require 'data_mapper'

DataMapper.setup :default, "mysql://xedule:#{File.read('mysql.pass').chomp}@localhost/xedule"

class Organisation
    include DataMapper::Resource

    property :id,   Integer, key: true
    property :name, String

    has n, :locations
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
    has n, :events, through: Resource
end

class Event
    include DataMapper::Resource

    property :id,          Serial, key: true
    property :year,        Integer
    property :week,        Integer
    property :day,         Integer
    property :start,       String
    property :end,         String
    property :description, String
    property :classes,     String, default: '', length: 255
    property :staff,       String, default: '', length: 255
    property :facilities,  String, default: '', length: 255

    belongs_to :location
    has n, :attendees, through: Resource

    def <<(attendee)
        case attendee.type
        when :class
            self.classes = classes.split(',').push(attendee.name).join(',') # TODO: Check length
        when :staff
            self.staff = staff.split(',').push(attendee.name).join(',')
        when :facility
            self.facilities = facilities.split(',').push(attendee.name).join(',')
        end

        self.attendees << attendee
    end
end

class EventAttendee
    include DataMapper::Resource

    belongs_to :event,    key: true
    belongs_to :attendee, key: true
end

class CachedResponse
    include DataMapper::Resource

    property :url,       String, key: true
    property :timestamp, Time

    def age
        Time.now - timestamp
    end
end

DataMapper.auto_upgrade!
