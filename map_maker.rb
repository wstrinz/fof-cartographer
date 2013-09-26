require 'mapnik'
require 'geo_ruby'
require 'json'
require 'geo_ruby/shp4r/shp'

class MapMaker
  include GeoRuby::SimpleFeatures
  include GeoRuby

  def color_range
    %w{#FF0500 #FF3700 #FF6900 #FF9B00 #FFCD00 #FFFF00 #C6F700 #8EEF00 #56E700 #1EE000}
  end

  def range_layer(m,property,shapefile,range = 0..100)
    m.layer "#{property}_area" do |l|
      l.style do |s|
        s.rule do |default|
          default.fill = Mapnik::Color.new('#330099')
        end

        10.times do |step|
          cutoff = ((1/(10-step).to_f) * range.size)
          s.rule "[#{property}] > #{cutoff}" do |default|
            default.fill = Mapnik::Color.new(color_range()[step])
          end
        end
      end

      l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile
    end

    m.layer "#{property}_text" do |l|
      l.style do |s|
        s.rule do |default|
          default.text "[#{property}]" do |text|
            text.label_placement = Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
            text.displacement = [0.0,10.0]
            text.fill = Mapnik::Color.new('#000')
            text.halo_fill = Mapnik::Color.new("#fff")
            # text.size = 25
            text.avoid_edges = true
            text.halo_radius = 1
          end
        end
      end

      l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile.gsub(".shp","") + "_points.shp"
    end
  end

  def crop_layer(m, shapefile)
    m.layer 'crop_area' do |l|
      l.style do |s|
        s.rule do |default|
          default.fill = Mapnik::Color.new('#330099')
        end

        s.rule "[CROP] = 'GRASS'" do |default|
          default.fill = Mapnik::Color.new('#2E5C00')
        end

        s.rule "[CROP] = 'CORN'" do |default|
          default.fill = Mapnik::Color.new('#D4D419')
        end

        s.rule "[CROP] = 'COVER'" do |default|
          default.fill = Mapnik::Color.new('#0042A3')
        end

        s.rule "[CROP] = 'FALLOW'" do |default|
          default.fill = Mapnik::Color.new('#473119')
        end
      end

      l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile
    end

    m.layer 'crop_text' do |l|
      l.style do |s|
        s.rule do |default|
          default.text "[CROP]" do |text|
            text.label_placement = Mapnik::LABEL_PLACEMENT::POINT_PLACEMENT
            text.fill = Mapnik::Color.new('#000')
            text.displacement = [0.0,-10.0]
            text.halo_fill = Mapnik::Color.new("#fff")
            text.avoid_edges = true
            text.halo_radius = 1
          end
        end
      end

      l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile.gsub(".shp","") + "_points.shp"
    end
  end

  def one_xml_map(data,farm_shapefile,field_shapefile)
    map = Mapnik::Map.new do |m|
      m.background = Mapnik::Color.new('#777')

      crop_layer(m,field_shapefile)

      m.layer 'farm_area' do |l|
        l.style do |s|
          s.rule do |default|
            default.fill = Mapnik::Color.new('#330099')
          end


          colors = color_range.shuffle
          data["fields"].map{|f| f["farm"]}.uniq.each_with_index do |farm,i|
            s.rule "[FARM] = '#{farm}'" do |default|
              default.fill = Mapnik::Color.new("#{colors[i]}")
            end
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => farm_shapefile
      end

      m.layer 'farm_text' do |l|
        l.style do |s|

          s.rule do |default|
            default.text "[FARM]" do |text|
              text.label_placement =  Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
              text.fill = Mapnik::Color.new('#000')
              text.halo_fill = Mapnik::Color.new("#fff")
              text.halo_radius = 1
            end
          end

          l.datasource = Mapnik::Datasource.create :type => 'shape', :file => farm_shapefile.gsub(".shp","") + "_points.shp"

        end
      end

      m.layer 'farm_text_field' do |l|
        l.style do |s|

          s.rule do |default|
            default.text "[FARM]" do |text|
              text.label_placement =  Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
              text.fill = Mapnik::Color.new('#000')
              text.halo_fill = Mapnik::Color.new("#fff")
              text.halo_radius = 1
            end
          end

          l.datasource = Mapnik::Datasource.create :type => 'shape', :file => field_shapefile.gsub(".shp","") + "_points.shp"

        end
      end

      range_layer(m,'SOC',field_shapefile,0..190)
      range_layer(m,'GBI',field_shapefile)

    end

    map.zoom_to_box(map.layers.first.envelope)
    map.to_xml
  end

  def render_color_scaled_map(property,shapefile,range = 0..100)

    map = Mapnik::Map.new do |m|

      m.background = Mapnik::Color.new('#777')

      m.layer 'countries' do |l|
        l.style do |s|
          s.rule do |default|
            default.fill = Mapnik::Color.new('#330099')
          end

          10.times do |step|
            cutoff = ((1/(10-step).to_f) * range.size)
            s.rule "[#{property}] > #{cutoff}" do |default|
              default.fill = Mapnik::Color.new(color_range()[step])
            end
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile
      end

      m.layer 'text' do |l|
        l.style do |s|
          s.rule do |default|
            default.text "[#{property}]" do |text|
              text.label_placement = Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
              text.displacement = [0.0,20.0]
              text.fill = Mapnik::Color.new('#000')
              text.halo_fill = Mapnik::Color.new("#fff")
              # text.size = 25
              text.avoid_edges = true
              text.halo_radius = 1
            end

            default.text "[FARM]" do |text|
              text.label_placement = Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
              # text.displacement = [0.0, 150.0]
              text.fill = Mapnik::Color.new('#000')
              # text.size = 15
              text.halo_fill = Mapnik::Color.new("#fff")
              text.avoid_edges = true
              text.halo_radius = 1
            end
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile.gsub(".shp","") + "_points.shp"
      end


    end

    map.zoom_to_box(map.layers.first.envelope)
    open('xmlmap.xml','w'){|f| f.write map.to_xml }
    map.render_to_file("#{@room}_#{property}.png")
  end

  def render_crops(shapefile)
    map = Mapnik::Map.new do |m|

      m.background = Mapnik::Color.new('#777')

      m.layer 'countries' do |l|
        l.style do |s|
          s.rule do |default|
            default.fill = Mapnik::Color.new('#330099')
          end

          s.rule "[CROP] = 'GRASS'" do |default|
            default.fill = Mapnik::Color.new('#2E5C00')
          end

          s.rule "[CROP] = 'CORN'" do |default|
            default.fill = Mapnik::Color.new('#D4D419')
          end

          s.rule "[CROP] = 'COVER'" do |default|
            default.fill = Mapnik::Color.new('#0042A3')
          end

          s.rule "[CROP] = 'FALLOW'" do |default|
            default.fill = Mapnik::Color.new('#473119')
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile
      end

      m.layer 'text' do |l|
        l.style do |s|
          s.rule do |default|
            default.text "[CROP]" do |text|
              text.label_placement = Mapnik::LABEL_PLACEMENT::INTERIOR_PLACEMENT
              text.fill = Mapnik::Color.new('#000')
              text.halo_fill = Mapnik::Color.new("#fff")
              text.avoid_edges = true
              text.halo_radius = 1
            end
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile.gsub(".shp","") + "_points.shp"
      end
    end

    map.zoom_to_box(map.layers.first.envelope)
    map.render_to_file("#{@room}_crop.png")
  end

  def render_farms(shapefile, data)
    map = Mapnik::Map.new do |ma|

      ma.background = Mapnik::Color.new('#777')


      ma.layer 'countries' do |l|
        l.style do |s|
          s.rule do |default|
            default.fill = Mapnik::Color.new('#330099')
          end


          colors = color_range.shuffle
          data["fields"].map{|f| f["farm"]}.uniq.each_with_index do |farm,i|
            s.rule "[FARM] = '#{farm}'" do |default|
              default.fill = Mapnik::Color.new("#{colors[i]}")
            end
          end
        end

        l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile
      end

      ma.layer 'text' do |l|
        l.style do |s|

          s.rule do |default|
            default.text "[FARM]" do |text|
              text.label_placement =  Mapnik::LABEL_PLACEMENT::POINT_PLACEMENT
              text.fill = Mapnik::Color.new('#000')
              text.halo_fill = Mapnik::Color.new("#fff")
              text.halo_radius = 1
            end
          end

          l.datasource = Mapnik::Datasource.create :type => 'shape', :file => shapefile.gsub(".shp","") + "_points.shp"

        end
      end
    end
    map.zoom_to_box(map.layers.first.envelope)
    map.render_to_file("#{@room}_farms.png")
  end

  def field_shapefile(data)
    meta = data
    @room = meta["clientID"]
    data = data["fields"]

    pts = []
    mids = []
    data.map{|po| [po["x"]*10,po["y"]*10]}.each{|p|
      p[0] += 1
      p[1] += 1
      pts << [
        Point.from_x_y(p[0],p[1]),
        Point.from_x_y(p[0],p[1]+9),
        Point.from_x_y(p[0]+9,p[1]+9),
        Point.from_x_y(p[0]+9,p[1]),
      ]


      basex = p[0]+(9.0/2)
      basey = p[1]+(9.0/2)

      mids << Point.from_x_y(basex, basey)
    }

    gbis = data.map{|pt| pt["GBI"]*100}
    socs = data.map{|pt| pt["SOM"]}
    farms = data.map{|pt| pt["farm"]}
    crops = data.map{|pt| pt["crop"]}
    yields = data.map{|pt| pt["yield"]}

    polys = []
    midpolys = []
    pts.each{|ps| polys << LinearRing.from_points(ps)}
    # mids.each{|ps| midpolys << LinearRing.from_points(ps)}

    dbf_fields = [
      Shp4r::Dbf::Field.new("CROP","C",10),
      Shp4r::Dbf::Field.new("FARM","C",10),
      Shp4r::Dbf::Field.new("GBI","N",10,0),
      Shp4r::Dbf::Field.new("YIELD","N",10,0),
      Shp4r::Dbf::Field.new("SOC","N",10,0)
    ]

    %w{shp shx dbf png}.each{|ext|
      File.delete "#{@room}_places.#{ext}" if File.exist? "#{@room}_places.#{ext}"
      File.delete "#{@room}_places_points.#{ext}" if File.exist?("#{@room}_places_points.#{ext}")
    }

    shpfile = Shp4r::ShpFile.create("#{@room}_places.shp",Shp4r::ShpType::POLYLINE,dbf_fields)

    polys.each_with_index{|poly,i|
      shpfile.transaction do |tr|
        tr.add(Shp4r::ShpRecord.new(poly,'CROP' => crops[i], 'YIELD' => yields[i], 'GBI' => gbis[i],'SOC' => socs[i], 'FARM' => farms[i]))
      end
    }

    shpfile.close

    shp2 = Shp4r::ShpFile.create("#{@room}_places_points.shp",Shp4r::ShpType::POINT,dbf_fields)

    mids.each_with_index{|mid,i|
      shp2.transaction do |tr|
        tr.add(Shp4r::ShpRecord.new(mid,'CROP' => crops[i], 'YIELD' => yields[i], 'GBI' => gbis[i],'SOC' => socs[i], 'FARM' => farms[i]))
      end
    }

    shp2.close
  end

  def farm_shapefile(data)
    farm_locs = {}
    farm_names = data["fields"].map{|pt| pt["farm"]}.uniq
    farm_names.each{|f|
      this_farm = data["fields"].select{|pt| pt["farm"] == f }
      minx,maxx = this_farm.map{|pt| pt["x"]}.minmax
      miny,maxy = this_farm.map{|pt| pt["y"]}.minmax

      farm_locs[f] = [minx,miny,maxx,maxy]
    }

    pts = []
    mids = []
    farm_names.each{|farm|
      p = farm_locs[farm]
      width = p[2] - p[0]
      height = p[3] - p[1]

      p = p.map{|pp| pp*10}
      p[0] += 1
      p[1] += 1
      pts << [
        Point.from_x_y(p[0],p[1]),
        Point.from_x_y(p[0]+9+width*10,p[1]),
        Point.from_x_y(p[0]+9+width*10,p[1]+9+height*10),
        Point.from_x_y(p[0],p[1]+9+height*10),
      ]

      basex = p[0]+(9.0/2)+width*10/2
      basey = p[1]+(9.0/2)+height*10/2

      mids << Point.from_x_y(basex, basey)
    }


    polys = []
    pts.each{|ps| polys << LinearRing.from_points(ps)}
    dbf_fields = [
      Shp4r::Dbf::Field.new("FARM","C",10),
    ]


    %w{shp shx dbf png}.each{|ext|
      File.delete "#{@room}_farms.#{ext}" if File.exist? "#{@room}_farms.#{ext}"
      File.delete "#{@room}_farms_points.#{ext}" if File.exist?("#{@room}_farms_points.#{ext}")
    }

    shpfile = Shp4r::ShpFile.create("#{@room}_farms.shp",Shp4r::ShpType::POLYLINE,dbf_fields)
    shpfile.transaction do |tr|
      polys.each_with_index{|poly,i|
        tr.add(Shp4r::ShpRecord.new(poly,'FARM'=>farm_names[i]))
      }

    end

    shpfile.close

    shpfile = Shp4r::ShpFile.create("#{@room}_farms_points.shp",Shp4r::ShpType::POINT,dbf_fields)

    shpfile.transaction do |tr|
      mids.each_with_index{|mid,i|
        tr.add(Shp4r::ShpRecord.new(mid, 'FARM' => farm_names[i]))
      }
    end

    shpfile.close
  end

  def render_fields(data)
    field_shapefile(data)
    farm_shapefile(data)

    render_color_scaled_map('GBI',"#{@room}_places.shp")
    render_color_scaled_map('SOC',"#{@room}_places.shp",0..190)
    render_crops("#{@room}_places.shp")
    render_farms("#{@room}_farms.shp",data)
  end


  def locs(target)
    st = 1
    sq = 4
    points = {}
    #target = 25
    x = 1
    y = 1
    xoff = yoff = Math.sqrt(sq).to_i - 1

    assign = Proc.new{
      points[st] = [x,y]
      st += 1
      return points if st > target
    }

    assign.call

    loop do
      x = 1; y += 1
      assign.call
      while xoff > 0 and yoff > 0 do
        x += xoff; y -= yoff
        assign.call
        xoff += 1
        x += xoff; y -= yoff
        yoff += 1
        assign.call
      end
      sq = (Math.sqrt(sq)+1)**2
      xoff = yoff = Math.sqrt(sq).to_i - 1
    end
  end
end

if ARGV[0]
  if File.exist?(ARGV[0])
    field_data = JSON.parse(IO.read(ARGV[0]))
  else
    field_data = JSON.parse(IO.read(File.dirname(__FILE__) + '/../test.json'))
  end
  # field_data["fields"] = field_data["fields"].select{|f| f["farm"] == "Mo Farmer"}

  m = MapMaker.new
  # m.render_fields field_data
  @room = field_data["clientID"]

  wd = "#{File.dirname(__FILE__)}/rooms/#{@room}"
  Dir.chdir wd
  puts `pwd`


  m.field_shapefile(field_data)
  m.farm_shapefile(field_data)
  map_str = m.one_xml_map(field_data,"#{@room}_farms.shp","#{@room}_places.shp")
  open("#{@room}.xml",'w'){|f| f.write map_str }

  # `eog noNameRoom_farms.png`

  # field_data = JSON.parse(IO.read(File.dirname(__FILE__) + '/../test.json'))
  # m = MapMaker.new
  # m.render_fields field_data

  # `eog noNameRoom_farms.png`
end