module VatsimTools

  class StationParser

    %w{tmpdir csv}.each { |lib| require lib }
    require_relative "data_downloader"
    require_relative "station"

    attr_accessor :role
    attr_accessor :icao

    LOCAL_DATA = "#{Dir.tmpdir}/vatsim_data.txt"

    def initialize(icao, args = nil)
      VatsimTools::DataDownloader.new
      args.class == Hash ? @role = determine_role(args) : @role = "all"
      @icao = icao
    end

    def determine_role(args)
      args[:atc] == false ? role = "pilot" : role = "all"
      args[:pilots] == false ? role = "atc" : role = role
      role = "all" if args[:pilots] == false && args[:atc] == false
      role
    end

    def stations
      stations = []
      CSV.foreach(LOCAL_DATA, :col_sep =>':', encoding: "iso-8859-15") do |row|
        callsign, origin, destination, client = row[0].to_s, row[11].to_s, row[13].to_s, row[3].to_s
        stations << row if (callsign[0...@icao.length] == @icao && client == "ATC") unless @role == "pilot"
        stations << row if (origin[0...@icao.length] == @icao || destination[0...@icao.length] == @icao) unless @role == "atc"
      end
      stations
    end

    def station_objects
      station_objects= []
      stations.each {|station| station_objects << VatsimTools::Station.new(station) }
      station_objects
    end

    def sorted_station_objects
      atc = []; pilots = []
      station_objects.each {|sobj| sobj.role == "ATC" ? atc << sobj : pilots << sobj}
      {:atc => atc, :pilots => pilots}
    end

  end

end
