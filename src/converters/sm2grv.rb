#!/usr/bin/env ruby

@@usage = "Usage: sm2grv INFILE [OUTFILE] {-12345}\n\n" +
		"INFILE   - .sm file you wish to convert. You can also supply\n" +
		"           a directory path to convert all .sm files inside.\n" + 
		"OUTFILE  - Name of output .89z file, as well as the variable\n" +
		"           name on your TI89. Must be limited to 8 chars, as\n" +
		"           well as not include any special characters.\n" +
		"-12345   - The difficulties you want converted. 1 is easiest\n" +
		"           or beginner, ascending to 5 for challenge. At least\n" +
		"           one of these numbers is required.\n" +
		"-v       - Verbose output.\n" +
		"-q       - Quiet output. Script will exit silently whether\n" +
		"           successful or not. Useful for batch conversion.\n" +
		"-c       - Force confirmation of each header string. Normally,\n" +
		"           the script attempts to automatically convert the song\n" +
		"           title, artist, and variable name into a calculator\n" +
		"           compatible format. This option gives you a chance to\n" +
		"           change those values."

class Sm2grv
	attr_accessor :infile, :outfile, :difficulties, :chartList, :headers, :minbpm, :maxbpm,
                :modebpm, :songLength, :bpms
	DIFFICULTY_HASH =  {"Beginner"   => 0,
                      "Easy"      => 1,
                      "Medium"    => 2,
                      "Hard"      => 3,
                      "Challenge" => 4}
	RESOLUTION_HASH = {quarter:      "10001111",
		                 eighth:       "10000111",
                     twelfth:      "10000100",
        					   sixteenth:    "10000011",
                     twentyfourth: "10000101",
                     thirtysecond: "10000001",
                     sixtyfourth:  "10000010"}

  CHART_END_TAG = "10100101" #or 0xA5
	class ChartStruct
		attr_accessor :diffString, :diffNum, :notes, :footRating, :radarValues
		
		def initialize(diffString)
			@diffString = diffString
			@diffNum = DIFFICULTY_HASH[diffString]
			@notes = []
		end

    def <=>(anotherChart)
      @diffNum <=> anotherChart.diffNum
    end
	end
	
	def initialize(infile, outfile, difficulties)
		initialize
		@difficulties = difficulties
		@infile = infile
		@outfile = outfile
	end
	
	def initialize
		@difficulties = [false, false, false, false, false]
		@headers = Hash.new
		@chartList = []
    @songLength = 0
    @bpms = []
    @bpmsBeatOffset = []
    @minbpm, @maxbpm, @modebpm = 0, 0, 0
	end
	
	#scrubs a line in the input file to reduce parsing errors.
	def scrub(line)
		#remove any comments
		line = line.split('//')[0]
		#whitespace can be bad too
		line.strip!
	end
	
  #gracefully shortens string by word.
  def shortenString(str, len)
    str = str.split
    while str.join(' ').length > len and str.length > 1
      str = str[0..-2]
    end
    str.join(' ')[0..len]
  end

  def formatInput
    if @headers.key?('#TITLETRANSLIT')
      @headers['#TITLE'] = @headers['#TITLETRANSLIT']
    end

    if @headers.key?('#ARTISTTRANSLIT')
      @headers['#ARTIST'] = @headers['#ARTISTTRANSLIT']
    end
    
    if @headers.key?('#SUBTITLETRANSLIT')
      @headers['#SUBTITLE'] = @headers['#SUBTITLETRANSLIT']
    end

    if @headers.key('#SUBTITLE')
      @headers['#TITLE'] = @headers['#TITLE'] + @headers['#SUBTITLE']
    end
    
    unless @headers.key?('#TITLE')
      @headers['#TITLE'] = 'Unknown Title'
    end
    @headers['#TITLE'] = shortenString(@headers['#TITLE'], 19)
    #The calculator uses latin-1 encoding, while .sm is usually UTF-8
    @headers['#TITLE'].encode!('ISO-8859-1', :invalid => :replace)

    unless @headers.key?('#ARTIST')
      @headers['#ARTIST'] = ' '
    end
    @headers['#ARTIST'] = shortenString(@headers['#ARTIST'], 19)
    @headers['#ARTIST'].encode!('ISO-8859-1', :invalid => :replace)

    if @outfile.nil?
      @outfile = shortenString(@headers['#TITLE'], 8)
    end
    if @outfile =~ /^\d/
      @outfile = 'a' + @outfile
    end
    @outfile.encode!('ISO-8859-1', :invalid => :replace)
	  @outfile.sub!(' ', '')
    
    if @headers.key?('#BPMS')
      lengthSig = Array.new

      bpmString = @headers['#BPMS']
      bpmString = bpmString.split(',')
      bpmString.each do |bpm|
        bpm = bpm.split('=')
        bpmBeat = bpm[0].to_f
        bpmBeatPart = (bpmBeat - bpmBeat.to_i).to_f
        bpmBeatPart = (bpmBeatPart * 64).to_i
        bpmBeat = bpmBeat.to_i
        @bpms << [bpmBeat, bpmBeatPart, bpm[1].to_i]
        if @bpms.length > 1
          lengthSig << [@bpms[-1][0] - @bpms[-2][0], @bpms[-2][1]]
        end
      end
      if @bpms.length == 1
        lengthSig << [@songLength, @bpms[0][-1]]
      else
        lengthSig << [@songLength - lengthSig[-1][0], @bpms[-1][-1]]
      end

      @bpms.each {|i| if i[2] < 0 then raise "Invalid value: negative BPM" end}

      @minbpm = @bpms.min[2]
      @maxbpm = @bpms.max[2]
      
      i = 0
      while i < lengthSig.length
        j = i + 1
        while j < lengthSig.length
          if lengthSig[i][1] == lengthSig[j][1] and i != j
            lengthSig[i][0] += lengthSig[j][0]
            lengthSig.delete_at(j)
          else
            j += 1
          end
        end
        i += 1
      end
      @modebpm = lengthSig[lengthSig.index(lengthSig.max)][1]
    else
      raise "No Beats Per Minute found"
    end

    #Change difficulty flags to what we have, not what we want.
    @difficulties = [false, false, false, false, false]
    @chartList.each do |chart|
      @difficulties[chart.diffNum] = true
      chart.radarValues = chart.radarValues.split(',')

      radarValAsNumber = []
      chart.radarValues.each do |val|
        radarValAsNumber << (val.to_f * 16 + 0.5).to_i
      end
      chart.radarValues = radarValAsNumber
      chart.footRating = chart.footRating.to_i
      if chart.footRating > 15
        chart.footRating = 15
      elsif chart.footRating < 1
        chart.footRating = 1
      end

    end

    @chartList.sort!
  end

  def codedStringtoRawString(binaryString, formatString, base = 2)
    result = Array.new
    result << binaryString.to_i(base)
    result.pack(formatString)
  end

  def intToRawString(number, formatString)
    result = Array.new
    result << number
    result.pack(formatString)
  end
  
  def writeFile
    chartOffsetPlaceholderLocations = Array.new
    binaryOutFile = File.new(@outfile, mode='wb')
    binaryOutFile << @headers['#TITLE'] << "\000"
    binaryOutFile << @headers['#ARTIST'] << "\000"
    #word-align the file, calculator will crash otherwise
    if binaryOutFile.pos % 2 == 1
      binaryOutFile.write "\000"
    end
    
    binaryOutFile << [@minbpm, @maxbpm, @modebpm].pack('n*')
    diffString = ""
    @difficulties.each do |bit|
      if bit
        diffString += '1'
      else
        diffString += '0'
      end
    end
    diffString += '00000000000'
    binaryOutFile << codedStringtoRawString(diffString, 'n*')

    @chartList.each do |chart|
      byteBufferString = ''
      byteBufferString += chart.footRating.to_s(2)
      binaryOutFile << codedStringtoRawString(byteBufferString, 'C')
      chart.radarValues.each do |val|
        byteBufferString = val.to_s(2)
        binaryOutFile << codedStringtoRawString(byteBufferString, 'C')
      end
      chartOffsetPlaceholderLocations << binaryOutFile.pos
      binaryOutFile << "\xFF\xFF\xFF"
    end
    @bpms.each do |bpm|
      binaryOutFile << bpm.pack('nCn')
    end
    binaryOutFile << intToRawString(0, 'n')
    currentPosition = []
    @chartList.each_index do |chartIndex|
      currentPosition << binaryOutFile.pos
      binaryOutFile.seek(chartOffsetPlaceholderLocations[chartIndex])
      if currentPosition[chartIndex] > 4294967295     #max val of 4 byte unsigned int
        raise 'Chart too big'
      else
        binaryOutFile << intToRawString(currentPosition[chartIndex], 'N')
      end
      binaryOutFile.seek(currentPosition[chartIndex])
      @chartList[chartIndex].notes.each do |step|
        binaryOutFile << codedStringtoRawString(step, 'C*')
      end
    end
    binaryOutFile.close
  end 

  def wrapFile
    unless File.exist? 'ttbin2oth' or File.exist? 'ttbin2oth.exe'
      raise 'ttbin2oth not found'
    end
    puts "ttbin2oth -quiet -89 GRV #{@outfile} #{@outfile} groove"
    system("ttbin2oth -quiet -89 GRV #{@outfile} #{@outfile} groove")
    File.delete @outfile
  end

	def parseInput
		f = open(@infile)
		f.each(';') do |header|
			header.strip!
			if header =~ /#NOTES:/i
				stepinfo = header.split(":")
				if stepinfo[1] =~ /dance-single/i
					difficulty = scrub(stepinfo[3])
					if @difficulties[DIFFICULTY_HASH[difficulty]]
						currChart = ChartStruct.new(difficulty)
						currChart.footRating = scrub(stepinfo[4])
						currChart.radarValues = scrub(stepinfo[5])
						
						notes = stepinfo[6].split(',')
						lastMeasure = RESOLUTION_HASH[:quarter]
						notes.each do |measure|
							measure = measure.split("\n")
							measure.delete_if {|line| (line =~ /^([0-4a-zA-Z]){4}/) == nil}
							case measure.length
								when 4
									thisMeasure = RESOLUTION_HASH[:quarter]
								when 8
									thisMeasure = RESOLUTION_HASH[:eighth]
                when 12
                  thisMeasure = RESOLUTION_HASH[:twelfth]
								when 16
									thisMeasure = RESOLUTION_HASH[:sixteenth]
                when 24
                  thisMeasure = RESOLUTION_HASH[:twelfth]
								when 32
									thisMeasure = RESOLUTION_HASH[:thirtysecond]
								when 64
									thisMeasure = RESOLUTION_HASH[:sixtyfourth]
								else
									puts measure.length
									puts measure[1..10]
									raise "Failed to parse Measure resolution: "
							end
              @songLength += 4
							currChart.notes << thisMeasure  unless lastMeasure == thisMeasure
							lastMeasure = thisMeasure
							
							measure.each do |line|
								nextStep = "00000000"
								#ignore mines, rolls, lifts and other things
								line.gsub!(/[4a-zA-Z]/, '0')
								for tapIndex in 0..line.length
									if line[tapIndex] == '1'
										nextStep[tapIndex] = '1'
									elsif line[tapIndex] =~ /[23]/
										nextStep[tapIndex] = '1'
										nextStep[tapIndex + 4] = '1'
									end
								end
								currChart.notes << nextStep
							end
						end
            currChart.notes << CHART_END_TAG
						@chartList << currChart
					end
				end
			elsif header =~ /#.+:.+;/
				scrub(header)
				header = header.split(':')
				header[1].chomp!(';')
				@headers[header[0]] = header[1]
			end
		end
		f.close
	end
end

#default config values go here
@@verbose = false
@@quiet = false
@@unknArg = nil
@@sg = Sm2grv.new

def message(m)
	puts m  unless @@quiet
end

def verboseMessage(m)
	if @@verbose == true
		puts m
	end
end

def error(m)
	message(m)
	message("\n\n")
	message(@@usage)
end

def validateArgs
	if @@sg.infile.nil?
		error("fatal: INFILE is required.")
		return false
	end
	if @@sg.difficulties == [false, false, false, false, false]
		error("fatal: No difficulties specified.")
		return false
	end
	unless @@unknArg.nil?
		error("Unknown or invalid argument(s), including " + @@unknArg +
				"\nAttempting to continue.")
	end
	true
end

#"main" method here in case file is invoked directly
if ARGV.empty? or ARGV[0] == "-h" or ARGV[0] == "-help"
	puts(@@usage)
	exit
end

for a in ARGV.each
	if a[0] == '-'
		for char in a.each_char
			if char == 'v'
				@@verbose = true
			elsif char == 'q'
				@@quiet = trued
			elsif char =~ /[1-5]/
				char = char.to_i
				@@sg.difficulties[char - 1] = true
			end
		end
	elsif @@sg.infile.nil?
		@@sg.infile = a
	elsif @@sg.outfile.nil?
		@@sg.outfile = a
	else
		@@unknArg = a
	end
end

exit  unless validateArgs
verboseMessage('Processing file ' + @@sg.infile)
@@sg.parseInput
if @@sg.chartList.length == 0
	error("fatal: No requested difficulties found in file.")
	exit
else
  verboseMessage("Found " + @@sg.chartList.length.to_s + " of your requested difficulties:")
  @@sg.chartList.each do |chart|
    verboseMessage("  -" + chart.diffString + ": " + chart.notes.length.to_s + " bytes long.")
  end
end

@@sg.formatInput
@@sg.writeFile
@@sg.wrapFile

